-- Authoritative customer/VPDD source in Oracle FREEPDB1, schema KDL_VPDD.
-- The two subtypes overlap. City codes reference the SQL Server sales source.
CREATE TABLE KhachHang (
  MaKH NUMBER(10) PRIMARY KEY,
  TenKH NVARCHAR2(100) NOT NULL,
  MaThanhPho NUMBER(10) NOT NULL,
  NgayDatHangDauTien DATE
);
CREATE TABLE KhachHangDuLich (
  MaKH NUMBER(10) PRIMARY KEY REFERENCES KhachHang(MaKH),
  HuongDanVienDuLich NVARCHAR2(100),
  ThoiGian TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
CREATE TABLE KhachHangBuuDien (
  MaKH NUMBER(10) PRIMARY KEY REFERENCES KhachHang(MaKH),
  DiaChiBuuDien NVARCHAR2(200),
  ThoiGian TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
