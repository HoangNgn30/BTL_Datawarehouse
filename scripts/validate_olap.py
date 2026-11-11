"""Compare all materialized cuboids with source queries; fail on any mismatch."""
import os
import sys
import re
from pathlib import Path
import pyodbc
from dotenv import load_dotenv
load_dotenv(Path(__file__).resolve().parents[1] / 'dw-dm' / '.env')
AUTH = 'Trusted_Connection=yes;' if os.getenv('DB_TRUSTED', 'yes').lower() in ('yes','true','1') else f"UID={os.environ['DB_USER']};PWD={os.getenv('DB_PASSWORD','')};"
CONNECTION = f"DRIVER={{{os.getenv('DB_DRIVER','ODBC Driver 17 for SQL Server')}}};SERVER={os.getenv('DB_SERVER',r'.\MSSQLSERVER01')};DATABASE=OLAP_QuanLyBanHang;{AUTH}TrustServerCertificate=yes;"
SALES = """SELECT YEAR(o.NgayDatHang) nam, DATEPART(QUARTER,o.NgayDatHang) quy, MONTH(o.NgayDatHang) thang,
 CAST(d.MaMH AS NVARCHAR(20)) mh_key, CAST(o.MaKH AS NVARCHAR(20)) kh_key,
 CASE WHEN dl.MaKH IS NOT NULL AND bd.MaKH IS NOT NULL THEN N'CaHai'
 WHEN dl.MaKH IS NOT NULL THEN N'DuLich' WHEN bd.MaKH IS NOT NULL THEN N'BuuDien' ELSE N'Khac' END loai_kh,
 d.SoLuongDat tong_so_luong, d.SoLuongDat*d.GiaDat tong_doanh_thu
 FROM IDB_BanHang.dbo.DonDatHang o JOIN IDB_BanHang.dbo.MatHangDuocDat d ON d.MaDon=o.MaDon
 LEFT JOIN IDB_VPDD.dbo.KhachHangDuLich dl ON dl.MaKH=o.MaKH
 LEFT JOIN IDB_VPDD.dbo.KhachHangBuuDien bd ON bd.MaKH=o.MaKH"""
STOCK = """SELECT s.ThangKey/100 nam, ((s.ThangKey%100-1)/3)+1 quy, s.ThangKey%100 thang,
 CAST(s.MaMH AS NVARCHAR(20)) mh_key, CAST(s.MaCuaHang AS NVARCHAR(20)) ch_key,
 v.Bang bang, v.TenThanhPho ten_tp, s.SoLuong tong_ton_kho
 FROM IDB_BanHang.dbo.TonKhoThang s JOIN IDB_BanHang.dbo.CuaHang c ON c.MaCuaHang=s.MaCuaHang
 JOIN IDB_BanHang.dbo.VanPhongDaiDien v ON v.MaThanhPho=c.MaThanhPho"""
CUSTOMER_SOURCE = os.getenv('DB_CUSTOMER_SOURCE','IDB_VPDD')
if not re.fullmatch(r'[A-Za-z0-9_]+',CUSTOMER_SOURCE): raise ValueError('Invalid customer source')
SALES = SALES.replace('IDB_VPDD.dbo.',f'[{CUSTOMER_SOURCE}].dbo.')
KEYS = {'nam','quy','thang','mh_key','kh_key','loai_kh','ch_key','bang','ten_tp'}

def run():
    bad = 0
    count = 0
    with pyodbc.connect(CONNECTION) as cn:
        def rows(sql):
            return {tuple(row) for row in cn.cursor().execute(sql).fetchall()}
        def compare(name, actual, expected):
            nonlocal bad, count
            count += 1
            a,b = rows(actual),rows(expected)
            ok = a == b
            bad += not ok
            print(f"[{'OK' if ok else 'FAIL'}] {name} ({len(a)} rows)")
            if not ok:
                print('  actual-only:',list(a-b)[:2], 'expected-only:',list(b-a)[:2])
        tables = [r[0] for r in cn.cursor().execute("SELECT name FROM sys.tables WHERE name LIKE 'olap[_]%' ORDER BY name")]
        if len(tables) != 56:
            raise AssertionError(f'Expected 56 cuboids, got {len(tables)}')
        for table in tables:
            columns = [r[0] for r in cn.cursor().execute("SELECT name FROM sys.columns WHERE object_id=OBJECT_ID(?) ORDER BY column_id",table)]
            dims = [c for c in columns if c in KEYS]
            measures = ['tong_so_luong','tong_doanh_thu'] if table.startswith('olap_ds_') else ['tong_ton_kho']
            group = ' GROUP BY '+','.join(dims) if dims else ''
            select = ','.join(dims+[f'SUM({m}) {m}' for m in measures])
            base = SALES if table.startswith('olap_ds_') else STOCK
            prefix = f'WITH base AS ({base}) '
            source = 'base'
            if table.startswith('olap_tk_'):
                period = [d for d in dims if d in ('nam','quy','thang')]
                partition = ','.join(['ch_key','mh_key']+period)
                prefix += f', ranked AS (SELECT *,ROW_NUMBER() OVER(PARTITION BY {partition} ORDER BY nam DESC,thang DESC) rn FROM base) '
                source = 'ranked WHERE rn=1'
            expected = prefix + f'SELECT {select} FROM {source}{group}'
            compare(table, f"SELECT {','.join(dims+measures)} FROM [{table}]",expected)
        compare('source ledger -> every monthly snapshot',
            'SELECT ThangKey,MaCuaHang,MaMH,SoLuong FROM IDB_BanHang.dbo.TonKhoThang',
            """SELECT s.ThangKey,s.MaCuaHang,s.MaMH,SUM(b.SoLuong)
            FROM IDB_BanHang.dbo.TonKhoThang s JOIN IDB_BanHang.dbo.BienDongKho b
            ON b.MaCuaHang=s.MaCuaHang AND b.MaMH=s.MaMH
            AND YEAR(b.Ngay)*100+MONTH(b.Ngay)<=s.ThangKey
            GROUP BY s.ThangKey,s.MaCuaHang,s.MaMH""")
        compare('all order lines -> Fact_BanHang',
            'SELECT ma_don,mh_key,so_luong,gia_dat,tong_tien FROM DW_Core.dbo.Fact_BanHang',
            'SELECT CAST(MaDon AS NVARCHAR(20)),CAST(MaMH AS NVARCHAR(20)),SoLuongDat,GiaDat,SoLuongDat*GiaDat FROM IDB_BanHang.dbo.MatHangDuocDat')
        compare('all allocations -> Fact_PhanBo',
            'SELECT ma_don,mh_key,ch_key,so_luong_cap FROM DW_Core.dbo.Fact_PhanBo',
            'SELECT CAST(MaDon AS NVARCHAR(20)),CAST(MaMH AS NVARCHAR(20)),CAST(MaCuaHang AS NVARCHAR(20)),SoLuongCap FROM IDB_BanHang.dbo.PhanBoDonHang')
        compare('allocations fulfill exactly each order line',
            'SELECT MaDon,MaMH,SUM(SoLuongCap) FROM IDB_BanHang.dbo.PhanBoDonHang GROUP BY MaDon,MaMH',
            'SELECT MaDon,MaMH,SoLuongDat FROM IDB_BanHang.dbo.MatHangDuocDat')
        compare('current stock -> last monthly balance',
            'SELECT MaCuaHang,MaMH,SoLuongTrongKho FROM IDB_BanHang.dbo.MatHangLuuTru',
            'SELECT MaCuaHang,MaMH,SoLuong FROM IDB_BanHang.dbo.TonKhoThang WHERE ThangKey=(SELECT MAX(ThangKey) FROM IDB_BanHang.dbo.TonKhoThang)')
        compare('no negative running inventory',
            """SELECT COUNT(*) FROM (SELECT SUM(SoLuong) OVER(PARTITION BY MaCuaHang,MaMH ORDER BY Ngay,MaBienDong ROWS UNBOUNDED PRECEDING) balance FROM IDB_BanHang.dbo.BienDongKho) x WHERE balance<0""",
            'SELECT 0')
    print(f'{count-bad}/{count} checks passed')
    return int(bool(bad))
if __name__ == '__main__':
    sys.exit(run())
