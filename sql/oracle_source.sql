-- Nguon tren Oracle (de bai yeu cau SQL Server VA Oracle).
-- Cung luoc do voi sql/01_idb_source.sql. Chay bang SQL*Plus voi user co quyen CREATE TABLE.
-- Du lieu co the xuat tu SQL Server sang CSV roi nap bang SQL*Loader, hoac dung ETL doc
-- truc tiep Oracle (python-oracledb) roi nap vao DW_Core.
CREATE TABLE VanPhongDaiDien (
  MaThanhPho NUMBER PRIMARY KEY, TenThanhPho VARCHAR2(100) NOT NULL,
  DiaChiVP VARCHAR2(200), Bang VARCHAR2(100), ThoiGian DATE DEFAULT SYSDATE);
CREATE TABLE CuaHang (
  MaCuaHang NUMBER PRIMARY KEY, MaThanhPho NUMBER NOT NULL REFERENCES VanPhongDaiDien(MaThanhPho),
  SoDienThoai VARCHAR2(20), ThoiGian DATE DEFAULT SYSDATE);
CREATE TABLE MatHang (
  MaMH NUMBER PRIMARY KEY, MoTa VARCHAR2(200), KichCo VARCHAR2(20),
  TrongLuong NUMBER(10,2), Gia NUMBER(18,2), ThoiGian DATE DEFAULT SYSDATE);
CREATE TABLE MatHangLuuTru (
  MaCuaHang NUMBER REFERENCES CuaHang(MaCuaHang), MaMH NUMBER REFERENCES MatHang(MaMH),
  SoLuongTrongKho NUMBER NOT NULL, ThoiGian DATE DEFAULT SYSDATE,
  PRIMARY KEY (MaCuaHang, MaMH));
CREATE TABLE KhachHang (
  MaKH NUMBER PRIMARY KEY, TenKH VARCHAR2(100) NOT NULL, MaThanhPho NUMBER NOT NULL,
  NgayDatHangDauTien DATE);
CREATE TABLE KhachHangDuLich (
  MaKH NUMBER PRIMARY KEY REFERENCES KhachHang(MaKH), HuongDanVienDuLich VARCHAR2(100), ThoiGian DATE DEFAULT SYSDATE);
CREATE TABLE KhachHangBuuDien (
  MaKH NUMBER PRIMARY KEY REFERENCES KhachHang(MaKH), DiaChiBuuDien VARCHAR2(200), ThoiGian DATE DEFAULT SYSDATE);
CREATE TABLE DonDatHang (
  MaDon NUMBER PRIMARY KEY, NgayDatHang DATE NOT NULL, MaKH NUMBER NOT NULL REFERENCES KhachHang(MaKH));
CREATE TABLE MatHangDuocDat (
  MaDon NUMBER REFERENCES DonDatHang(MaDon), MaMH NUMBER REFERENCES MatHang(MaMH),
  SoLuongDat NUMBER NOT NULL, GiaDat NUMBER(18,2) NOT NULL, ThoiGian DATE DEFAULT SYSDATE,
  PRIMARY KEY (MaDon, MaMH));

