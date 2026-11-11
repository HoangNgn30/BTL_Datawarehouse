"""Compare selected report results, row for row, against relational sources."""
import json
import sys
import os
import re
from pathlib import Path
sys.path.insert(0,str(Path(__file__).resolve().parents[1]/'dw-dm'))
from main import app, query_all
from fastapi.testclient import TestClient
from fastapi.encoders import jsonable_encoder

REPORTS=[
(1,{},'''SELECT CAST(c.MaCuaHang AS NVARCHAR(20)) ch_key,v.TenThanhPho ten_tp,v.Bang bang,c.SoDienThoai so_dt,CAST(m.MaMH AS NVARCHAR(20)) mh_key,m.MoTa mo_ta,m.KichCo kich_co,m.TrongLuong trong_luong,m.Gia gia FROM CuaHang c JOIN VanPhongDaiDien v ON v.MaThanhPho=c.MaThanhPho JOIN MatHangLuuTru l ON l.MaCuaHang=c.MaCuaHang JOIN MatHang m ON m.MaMH=l.MaMH'''),
(2,{'kh':'1'},'''SELECT CAST(o.MaDon AS NVARCHAR(20)) ma_don,CAST(k.MaKH AS NVARCHAR(20)) kh_key,k.TenKH ten,o.NgayDatHang ngay FROM DonDatHang o JOIN IDB_VPDD.dbo.KhachHang k ON k.MaKH=o.MaKH WHERE k.MaKH=1'''),
(3,{'kh':'1'},'''SELECT DISTINCT CAST(c.MaCuaHang AS NVARCHAR(20)) ch_key,v.TenThanhPho ten_tp,c.SoDienThoai so_dt FROM DonDatHang o JOIN MatHangDuocDat d ON d.MaDon=o.MaDon JOIN MatHangLuuTru l ON l.MaMH=d.MaMH JOIN CuaHang c ON c.MaCuaHang=l.MaCuaHang JOIN VanPhongDaiDien v ON v.MaThanhPho=c.MaThanhPho WHERE o.MaKH=1'''),
(4,{'mh':'1','muc':100},'''SELECT CAST(c.MaCuaHang AS NVARCHAR(20)) ch_key,v.DiaChiVP dia_chi_vp,v.TenThanhPho ten_tp,v.Bang bang,l.SoLuongTrongKho so_luong FROM MatHangLuuTru l JOIN CuaHang c ON c.MaCuaHang=l.MaCuaHang JOIN VanPhongDaiDien v ON v.MaThanhPho=c.MaThanhPho WHERE l.MaMH=1 AND l.SoLuongTrongKho>100'''),
(5,{'ma_don':'1'},'''SELECT CAST(d.MaDon AS NVARCHAR(20)) ma_don,CAST(d.MaMH AS NVARCHAR(20)) mh_key,m.MoTa mo_ta,CAST(p.MaCuaHang AS NVARCHAR(20)) ch_dap_ung,p.SoLuongCap so_luong_cap,v.TenThanhPho tp_dap_ung,CAST(l.MaCuaHang AS NVARCHAR(20)) ch_co_ban,v2.TenThanhPho tp_ch_co_ban FROM MatHangDuocDat d JOIN MatHang m ON m.MaMH=d.MaMH JOIN PhanBoDonHang p ON p.MaDon=d.MaDon AND p.MaMH=d.MaMH JOIN CuaHang c ON c.MaCuaHang=p.MaCuaHang JOIN VanPhongDaiDien v ON v.MaThanhPho=c.MaThanhPho JOIN MatHangLuuTru l ON l.MaMH=d.MaMH JOIN CuaHang c2 ON c2.MaCuaHang=l.MaCuaHang JOIN VanPhongDaiDien v2 ON v2.MaThanhPho=c2.MaThanhPho WHERE d.MaDon=1'''),
(6,{'kh':'1'},'''SELECT CAST(k.MaKH AS NVARCHAR(20)) kh_key,k.TenKH ten,v.TenThanhPho ten_tp,v.Bang bang FROM IDB_VPDD.dbo.KhachHang k JOIN VanPhongDaiDien v ON v.MaThanhPho=k.MaThanhPho WHERE k.MaKH=1'''),
(7,{'mh':'1','tp':'1'},'''SELECT CAST(c.MaCuaHang AS NVARCHAR(20)) ch_key,v.TenThanhPho ten_tp,CAST(l.MaMH AS NVARCHAR(20)) mh_key,l.SoLuongTrongKho ton_kho FROM MatHangLuuTru l JOIN CuaHang c ON c.MaCuaHang=l.MaCuaHang JOIN VanPhongDaiDien v ON v.MaThanhPho=c.MaThanhPho WHERE l.MaMH=1 AND c.MaThanhPho=1'''),
(8,{'ma_don':'1'},'''SELECT CAST(d.MaDon AS NVARCHAR(20)) ma_don,CAST(d.MaMH AS NVARCHAR(20)) mh_key,m.MoTa mo_ta,d.SoLuongDat so_luong,d.GiaDat gia_dat,k.TenKH khach_hang,CAST(p.MaCuaHang AS NVARCHAR(20)) ch_key,p.SoLuongCap so_luong_cap,v.TenThanhPho ten_tp FROM MatHangDuocDat d JOIN DonDatHang o ON o.MaDon=d.MaDon JOIN MatHang m ON m.MaMH=d.MaMH JOIN IDB_VPDD.dbo.KhachHang k ON k.MaKH=o.MaKH JOIN PhanBoDonHang p ON p.MaDon=d.MaDon AND p.MaMH=d.MaMH JOIN CuaHang c ON c.MaCuaHang=p.MaCuaHang JOIN VanPhongDaiDien v ON v.MaThanhPho=c.MaThanhPho WHERE d.MaDon=1'''),
(9,{'loai':'ca_hai'},'''SELECT CAST(k.MaKH AS NVARCHAR(20)) kh_key,k.TenKH ten,N'CaHai' loai_kh,d.HuongDanVienDuLich huong_dan_vien,b.DiaChiBuuDien dia_chi_buu_dien FROM IDB_VPDD.dbo.KhachHang k JOIN IDB_VPDD.dbo.KhachHangDuLich d ON d.MaKH=k.MaKH JOIN IDB_VPDD.dbo.KhachHangBuuDien b ON b.MaKH=k.MaKH''')]

def run():
    def canonical(data):
        return sorted(json.dumps(row,sort_keys=True,ensure_ascii=True) for row in jsonable_encoder(data))
    with TestClient(app) as client:
        for number,params,sql in REPORTS:
            response=client.get(f'/api/bao-cao/{number}',params=params)
            assert response.status_code==200,response.text
            source=os.getenv('DB_CUSTOMER_SOURCE','IDB_VPDD')
            if not re.fullmatch(r'[A-Za-z0-9_]+',source): raise ValueError('Invalid customer source')
            expected=query_all('IDB_BanHang',sql.replace('IDB_VPDD.dbo.',f'[{source}].dbo.'))
            assert canonical(response.json())==canonical(expected),f'Report {number} differs'
            print(f'[OK] Report {number}: {len(expected)} rows match source')
    print('9/9 report comparisons passed')
if __name__=='__main__':run()
