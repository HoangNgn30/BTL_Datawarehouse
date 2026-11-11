/* =====================================================================
   01 - TAO 2 CSDL NGUON THEO DE BAI + SINH DU LIEU MAU (deterministic)
   - IDB_VPDD    : co so du lieu Van phong dai dien (khach hang)
   - IDB_BanHang : co so du lieu Ban hang
   Chay: sqlcmd -S localhost -U sa -P ... -C -f 65001 -i sql\01_idb_source.sql
   ===================================================================== */
USE master;
GO
IF (DB_ID('IDB_VPDD') IS NOT NULL OR DB_ID('IDB_BanHang') IS NOT NULL) AND '$(ResetDemo)' <> '1'
    THROW 51000, 'CSDL nguon da ton tai. Chi dung ResetDemo=1 voi du lieu demo co the tao lai.', 1;
GO
IF DB_ID('IDB_VPDD') IS NOT NULL BEGIN ALTER DATABASE IDB_VPDD SET SINGLE_USER WITH ROLLBACK IMMEDIATE; DROP DATABASE IDB_VPDD; END
IF DB_ID('IDB_BanHang') IS NOT NULL BEGIN ALTER DATABASE IDB_BanHang SET SINGLE_USER WITH ROLLBACK IMMEDIATE; DROP DATABASE IDB_BanHang; END
CREATE DATABASE IDB_VPDD;
CREATE DATABASE IDB_BanHang;
GO

/* ===================== IDB_BanHang ===================== */
USE IDB_BanHang;
GO
CREATE TABLE VanPhongDaiDien (
    MaThanhPho INT PRIMARY KEY, TenThanhPho NVARCHAR(100) NOT NULL,
    DiaChiVP NVARCHAR(200), Bang NVARCHAR(100), ThoiGian DATETIME DEFAULT GETDATE());
CREATE TABLE CuaHang (
    MaCuaHang INT PRIMARY KEY, MaThanhPho INT NOT NULL REFERENCES VanPhongDaiDien(MaThanhPho),
    SoDienThoai VARCHAR(20), ThoiGian DATETIME DEFAULT GETDATE());
CREATE TABLE MatHang (
    MaMH INT PRIMARY KEY, MoTa NVARCHAR(200), KichCo NVARCHAR(20),
    TrongLuong DECIMAL(10,2), Gia DECIMAL(18,2), ThoiGian DATETIME DEFAULT GETDATE());
CREATE TABLE MatHangLuuTru (
    MaCuaHang INT NOT NULL REFERENCES CuaHang(MaCuaHang),
    MaMH INT NOT NULL REFERENCES MatHang(MaMH),
    SoLuongTrongKho INT NOT NULL, ThoiGian DATETIME DEFAULT GETDATE(),
    PRIMARY KEY (MaCuaHang, MaMH));
CREATE TABLE DonDatHang (
    MaDon INT PRIMARY KEY, NgayDatHang DATE NOT NULL, MaKH INT NOT NULL);  -- MaKH tham chieu IDB_VPDD.KhachHang
CREATE TABLE MatHangDuocDat (
    MaDon INT NOT NULL REFERENCES DonDatHang(MaDon),
    MaMH INT NOT NULL REFERENCES MatHang(MaMH),
    SoLuongDat INT NOT NULL, GiaDat DECIMAL(18,2) NOT NULL, ThoiGian DATETIME DEFAULT GETDATE(),
    PRIMARY KEY (MaDon, MaMH));
GO

DECLARE @n INT;
-- 12 thanh pho / bang
INSERT VanPhongDaiDien (MaThanhPho, TenThanhPho, DiaChiVP, Bang)
SELECT v.id, v.tp, N'So ' + CAST(v.id*10 AS NVARCHAR(10)) + N' Duong Trung Tam, ' + v.tp, v.bang
FROM (VALUES (1,N'New York',N'New York'),(2,N'Buffalo',N'New York'),(3,N'Los Angeles',N'California'),
             (4,N'San Diego',N'California'),(5,N'Houston',N'Texas'),(6,N'Dallas',N'Texas'),
             (7,N'Miami',N'Florida'),(8,N'Orlando',N'Florida'),(9,N'Chicago',N'Illinois'),
             (10,N'Seattle',N'Washington'),(11,N'Boston',N'Massachusetts'),(12,N'Denver',N'Colorado')) v(id,tp,bang);

-- 30 cua hang (moi thanh pho >= 2 cua hang)
INSERT CuaHang (MaCuaHang, MaThanhPho, SoDienThoai)
SELECT i, (i-1)%12+1, '0' + CAST(900000000 + i*7919 AS VARCHAR(12))
FROM (SELECT TOP (30) ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) i FROM sys.all_objects) x;

-- 60 mat hang
INSERT MatHang (MaMH, MoTa, KichCo, TrongLuong, Gia)
SELECT i, N'Mat hang ' + CAST(i AS NVARCHAR(10)), CHOOSE(i%3+1, N'S', N'M', N'L'),
       CAST(0.2 + (ABS(CHECKSUM(i*31))%500)/100.0 AS DECIMAL(10,2)),
       CAST(10 + ABS(CHECKSUM(i*57))%490 AS DECIMAL(18,2))
FROM (SELECT TOP (60) ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) i FROM sys.all_objects) x;

-- ton kho DAU KY 2021-01-01 (~55% cap cua hang x mat hang); 01b tru xuat kho
INSERT MatHangLuuTru (MaCuaHang, MaMH, SoLuongTrongKho, ThoiGian)
SELECT c.MaCuaHang, m.MaMH, 50 + ABS(CHECKSUM(c.MaCuaHang*131 + m.MaMH*7))%450, '2023-12-31'
FROM CuaHang c CROSS JOIN MatHang m
WHERE ABS(CHECKSUM(c.MaCuaHang*977 + m.MaMH))%100 < 55;

-- 1500 don hang cua 300 khach hang, 2021-2023
INSERT DonDatHang (MaDon, NgayDatHang, MaKH)
SELECT i, DATEADD(DAY, ABS(CHECKSUM(i*104729))%1095, '2021-01-01'), ABS(CHECKSUM(i*6007))%300 + 1
FROM (SELECT TOP (1500) ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) i FROM sys.all_objects a CROSS JOIN sys.all_objects b) x;

-- 1..3 dong / don (mat hang khac nhau)
INSERT MatHangDuocDat (MaDon, MaMH, SoLuongDat, GiaDat, ThoiGian)
SELECT d.MaDon, ((b.base + k.k*17) % 60) + 1, 1 + ABS(CHECKSUM(d.MaDon*13 + k.k))%10,
       CAST(m.Gia * (0.9 + (ABS(CHECKSUM(d.MaDon*3 + k.k))%21)/100.0) AS DECIMAL(18,2)), d.NgayDatHang
FROM DonDatHang d
CROSS JOIN (VALUES (0),(1),(2)) k(k)
CROSS APPLY (SELECT ABS(CHECKSUM(d.MaDon*2711))%60 AS base) b
JOIN MatHang m ON m.MaMH = ((b.base + k.k*17) % 60) + 1
WHERE k.k = 0 OR ABS(CHECKSUM(d.MaDon*53 + k.k))%100 < 50;
GO

/* ===================== IDB_VPDD ===================== */
USE IDB_VPDD;
GO
CREATE TABLE KhachHang (
    MaKH INT PRIMARY KEY, TenKH NVARCHAR(100) NOT NULL, MaThanhPho INT NOT NULL,
    NgayDatHangDauTien DATE NULL);
CREATE TABLE KhachHangDuLich (
    MaKH INT PRIMARY KEY REFERENCES KhachHang(MaKH), HuongDanVienDuLich NVARCHAR(100), ThoiGian DATETIME DEFAULT GETDATE());
CREATE TABLE KhachHangBuuDien (
    MaKH INT PRIMARY KEY REFERENCES KhachHang(MaKH), DiaChiBuuDien NVARCHAR(200), ThoiGian DATETIME DEFAULT GETDATE());
GO

INSERT KhachHang (MaKH, TenKH, MaThanhPho)
SELECT i, N'Khach hang ' + CAST(i AS NVARCHAR(10)), ABS(CHECKSUM(i*911))%12 + 1
FROM (SELECT TOP (300) ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) i FROM sys.all_objects) x;

UPDATE k SET NgayDatHangDauTien =
    (SELECT MIN(d.NgayDatHang) FROM IDB_BanHang.dbo.DonDatHang d WHERE d.MaKH = k.MaKH)
FROM KhachHang k;

-- MaKH%6: 0,1,2 = du lich ; 3,4 = buu dien ; 5 = ca hai
INSERT KhachHangDuLich (MaKH, HuongDanVienDuLich)
SELECT MaKH, N'HDV ' + CAST(MaKH%15 + 1 AS NVARCHAR(10)) FROM KhachHang WHERE MaKH%6 IN (0,1,2,5);
INSERT KhachHangBuuDien (MaKH, DiaChiBuuDien)
SELECT MaKH, N'PO Box ' + CAST(1000 + MaKH AS NVARCHAR(10)) FROM KhachHang WHERE MaKH%6 IN (3,4,5);
GO

