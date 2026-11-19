"""Compare every materialized cuboid with queries on the relational sources; fail on any mismatch."""
import os
import sys
import re
from pathlib import Path
import pyodbc
from dotenv import load_dotenv
ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / 'dw-dm'))
from cube_schema import KEY_COLUMNS, cuboid_count  # noqa: E402
load_dotenv(ROOT / 'dw-dm' / '.env')
AUTH = 'Trusted_Connection=yes;' if os.getenv('DB_TRUSTED', 'yes').lower() in ('yes','true','1') else f"UID={os.environ['DB_USER']};PWD={os.getenv('DB_PASSWORD','')};"
CONNECTION = f"DRIVER={{{os.getenv('DB_DRIVER','ODBC Driver 17 for SQL Server')}}};SERVER={os.getenv('DB_SERVER',r'.\MSSQLSERVER01')};DATABASE=OLAP_QuanLyBanHang;{AUTH}TrustServerCertificate=yes;"
MIN_FACT_ROWS = 100_000
# One row per allocation (order line x fulfilling store), straight from the sources.
SALES = """SELECT YEAR(o.NgayDatHang) nam, DATEPART(QUARTER,o.NgayDatHang) quy, MONTH(o.NgayDatHang) thang, o.NgayDatHang ngay,
 CAST(p.MaMH AS NVARCHAR(20)) mh_key, CAST(o.MaKH AS NVARCHAR(20)) kh_key,
 CASE WHEN dl.MaKH IS NOT NULL AND bd.MaKH IS NOT NULL THEN N'CaHai'
 WHEN dl.MaKH IS NOT NULL THEN N'DuLich' WHEN bd.MaKH IS NOT NULL THEN N'BuuDien' ELSE N'Khac' END loai_kh,
 v.Bang bang, v.TenThanhPho ten_tp, CAST(p.MaCuaHang AS NVARCHAR(20)) ch_key,
 p.SoLuongCap tong_so_luong, p.SoLuongCap*d.GiaDat tong_doanh_thu
 FROM IDB_BanHang.dbo.PhanBoDonHang p
 JOIN IDB_BanHang.dbo.MatHangDuocDat d ON d.MaDon=p.MaDon AND d.MaMH=p.MaMH
 JOIN IDB_BanHang.dbo.DonDatHang o ON o.MaDon=p.MaDon
 JOIN IDB_BanHang.dbo.CuaHang c ON c.MaCuaHang=p.MaCuaHang
 JOIN IDB_BanHang.dbo.VanPhongDaiDien v ON v.MaThanhPho=c.MaThanhPho
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

def run():
    bad = 0
    count = 0
    with pyodbc.connect(CONNECTION) as cn:
        def rows(sql):
            return {tuple(row) for row in cn.cursor().execute(sql).fetchall()}
        def scalar(sql):
            return cn.cursor().execute(sql).fetchone()[0]
        def compare(name, actual, expected):
            nonlocal bad, count
            count += 1
            a,b = rows(actual),rows(expected)
            ok = a == b
            bad += not ok
            print(f"[{'OK' if ok else 'FAIL'}] {name} ({len(a)} rows)")
            if not ok:
                print('  actual-only:',list(a-b)[:2], 'expected-only:',list(b-a)[:2])
        def check(name, ok, detail=''):
            nonlocal bad, count
            count += 1
            bad += not ok
            print(f"[{'OK' if ok else 'FAIL'}] {name} {detail}")
        tables = [r[0] for r in cn.cursor().execute("SELECT name FROM sys.tables WHERE name LIKE 'olap[_]%' ORDER BY name")]
        expected_count = cuboid_count('ds') + cuboid_count('tk')
        if len(tables) != expected_count:
            raise AssertionError(f'Expected {expected_count} cuboids, got {len(tables)}')
        for table in tables:
            columns = [r[0] for r in cn.cursor().execute("SELECT name FROM sys.columns WHERE object_id=OBJECT_ID(?) ORDER BY column_id",table)]
            dims = [c for c in columns if c in KEY_COLUMNS]
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
        compare('allocations grouped by day/customer/product/store -> Fact_BanHang (4 FK key)',
            'SELECT ngay_key,kh_key,mh_key,ch_key,so_luong,doanh_thu FROM DW_Core.dbo.Fact_BanHang',
            """SELECT YEAR(o.NgayDatHang)*10000+MONTH(o.NgayDatHang)*100+DAY(o.NgayDatHang),CAST(o.MaKH AS NVARCHAR(20)),
            CAST(p.MaMH AS NVARCHAR(20)),CAST(p.MaCuaHang AS NVARCHAR(20)),SUM(p.SoLuongCap),SUM(p.SoLuongCap*d.GiaDat)
            FROM IDB_BanHang.dbo.PhanBoDonHang p JOIN IDB_BanHang.dbo.MatHangDuocDat d ON d.MaDon=p.MaDon AND d.MaMH=p.MaMH
            JOIN IDB_BanHang.dbo.DonDatHang o ON o.MaDon=p.MaDon
            GROUP BY o.NgayDatHang,o.MaKH,p.MaMH,p.MaCuaHang""")
        compare('fact totals = ordered quantity and order-line revenue',
            'SELECT SUM(so_luong),SUM(doanh_thu) FROM DW_Core.dbo.Fact_BanHang',
            'SELECT SUM(SoLuongDat),SUM(SoLuongDat*GiaDat) FROM IDB_BanHang.dbo.MatHangDuocDat')
        compare('allocations fulfill exactly each order line',
            'SELECT MaDon,MaMH,SUM(SoLuongCap) FROM IDB_BanHang.dbo.PhanBoDonHang GROUP BY MaDon,MaMH',
            'SELECT MaDon,MaMH,SoLuongDat FROM IDB_BanHang.dbo.MatHangDuocDat')
        compare('monthly snapshots -> Fact_Kho',
            'SELECT time_key,ch_key,mh_key,so_luong FROM DW_Core.dbo.Fact_Kho',
            'SELECT ThangKey,CAST(MaCuaHang AS NVARCHAR(20)),CAST(MaMH AS NVARCHAR(20)),SoLuong FROM IDB_BanHang.dbo.TonKhoThang')
        compare('current stock -> last monthly balance',
            'SELECT MaCuaHang,MaMH,SoLuongTrongKho FROM IDB_BanHang.dbo.MatHangLuuTru',
            'SELECT MaCuaHang,MaMH,SoLuong FROM IDB_BanHang.dbo.TonKhoThang WHERE ThangKey=(SELECT MAX(ThangKey) FROM IDB_BanHang.dbo.TonKhoThang)')
        compare('no negative running inventory',
            """SELECT COUNT(*) FROM (SELECT SUM(SoLuong) OVER(PARTITION BY MaCuaHang,MaMH ORDER BY Ngay,MaBienDong ROWS UNBOUNDED PRECEDING) balance FROM IDB_BanHang.dbo.BienDongKho) x WHERE balance<0""",
            'SELECT 0')
        for fact in ('Fact_BanHang', 'Fact_Kho'):
            n = scalar(f'SELECT COUNT(*) FROM DW_Core.dbo.{fact}')
            check(f'{fact} has at least {MIN_FACT_ROWS:,} rows', n >= MIN_FACT_ROWS, f'({n:,} rows)')
    print(f'{count-bad}/{count} checks passed')
    return int(bool(bad))
if __name__ == '__main__':
    sys.exit(run())
