-- CustomerSource = IDB_VPDD (SQL demo) or STG_OracleVPDD (Oracle landing).
-- Refresh the integrated relational database; source databases are never modified.
USE master;
GO
IF DB_ID('IDB_TichHop') IS NULL CREATE DATABASE IDB_TichHop;
GO
USE IDB_TichHop;
GO
SET NOCOUNT ON;
SET XACT_ABORT ON;
SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;
IF OBJECT_ID('dbo.Integration_Run') IS NULL CREATE TABLE dbo.Integration_Run (
 RunID INT IDENTITY PRIMARY KEY,CustomerSource NVARCHAR(100) NOT NULL,
 StartedAt DATETIME2 NOT NULL,FinishedAt DATETIME2 NULL,Status VARCHAR(10) NOT NULL,
 OrderLines INT NULL,SnapshotRows INT NULL,ErrorMessage NVARCHAR(2000) NULL);
DECLARE @started DATETIME2=SYSUTCDATETIME(),@run INT;
INSERT dbo.Integration_Run(CustomerSource,StartedAt,Status) VALUES ('$(CustomerSource)',@started,'RUNNING');
SET @run=SCOPE_IDENTITY();
BEGIN TRY
BEGIN TRANSACTION;
IF OBJECT_ID('dbo.VanPhongDaiDien') IS NULL CREATE TABLE dbo.VanPhongDaiDien (MaThanhPho INT PRIMARY KEY,TenThanhPho NVARCHAR(100) NOT NULL,DiaChiVP NVARCHAR(200),Bang NVARCHAR(100),ThoiGian DATETIME2(6));
IF OBJECT_ID('dbo.CuaHang') IS NULL CREATE TABLE dbo.CuaHang (MaCuaHang INT PRIMARY KEY,MaThanhPho INT NOT NULL REFERENCES dbo.VanPhongDaiDien(MaThanhPho),SoDienThoai VARCHAR(20),ThoiGian DATETIME2(6));
IF OBJECT_ID('dbo.MatHang') IS NULL CREATE TABLE dbo.MatHang (MaMH INT PRIMARY KEY,MoTa NVARCHAR(200),KichCo NVARCHAR(20),TrongLuong DECIMAL(10,2),Gia DECIMAL(18,2),ThoiGian DATETIME2(6));
IF OBJECT_ID('dbo.KhachHang') IS NULL CREATE TABLE dbo.KhachHang (MaKH INT PRIMARY KEY,TenKH NVARCHAR(100) NOT NULL,MaThanhPho INT NOT NULL REFERENCES dbo.VanPhongDaiDien(MaThanhPho),NgayDatHangDauTien DATE);
IF OBJECT_ID('dbo.KhachHangDuLich') IS NULL CREATE TABLE dbo.KhachHangDuLich (MaKH INT PRIMARY KEY REFERENCES dbo.KhachHang(MaKH),HuongDanVienDuLich NVARCHAR(100),ThoiGian DATETIME2(6));
IF OBJECT_ID('dbo.KhachHangBuuDien') IS NULL CREATE TABLE dbo.KhachHangBuuDien (MaKH INT PRIMARY KEY REFERENCES dbo.KhachHang(MaKH),DiaChiBuuDien NVARCHAR(200),ThoiGian DATETIME2(6));
IF OBJECT_ID('dbo.MatHangLuuTru') IS NULL CREATE TABLE dbo.MatHangLuuTru (MaCuaHang INT NOT NULL REFERENCES dbo.CuaHang(MaCuaHang),MaMH INT NOT NULL REFERENCES dbo.MatHang(MaMH),SoLuongTrongKho INT NOT NULL CHECK(SoLuongTrongKho>=0),ThoiGian DATETIME2(6),PRIMARY KEY(MaCuaHang,MaMH));
IF OBJECT_ID('dbo.DonDatHang') IS NULL CREATE TABLE dbo.DonDatHang (MaDon INT PRIMARY KEY,NgayDatHang DATE NOT NULL,MaKH INT NOT NULL REFERENCES dbo.KhachHang(MaKH));
IF OBJECT_ID('dbo.MatHangDuocDat') IS NULL CREATE TABLE dbo.MatHangDuocDat (MaDon INT NOT NULL REFERENCES dbo.DonDatHang(MaDon),MaMH INT NOT NULL REFERENCES dbo.MatHang(MaMH),SoLuongDat INT NOT NULL CHECK(SoLuongDat>0),GiaDat DECIMAL(18,2) NOT NULL CHECK(GiaDat>=0),ThoiGian DATETIME2(6),PRIMARY KEY(MaDon,MaMH));
IF OBJECT_ID('dbo.PhanBoDonHang') IS NULL CREATE TABLE dbo.PhanBoDonHang (MaDon INT NOT NULL,MaMH INT NOT NULL,MaCuaHang INT NOT NULL,SoLuongCap INT NOT NULL CHECK(SoLuongCap>0),PRIMARY KEY(MaDon,MaMH,MaCuaHang),FOREIGN KEY(MaDon,MaMH) REFERENCES dbo.MatHangDuocDat(MaDon,MaMH),FOREIGN KEY(MaCuaHang,MaMH) REFERENCES dbo.MatHangLuuTru(MaCuaHang,MaMH));
IF OBJECT_ID('dbo.BienDongKho') IS NULL CREATE TABLE dbo.BienDongKho (MaBienDong INT PRIMARY KEY,MaCuaHang INT NOT NULL,MaMH INT NOT NULL,Ngay DATE NOT NULL,Loai VARCHAR(10) NOT NULL CHECK(Loai IN ('DAUKY','XUAT')),SoLuong INT NOT NULL,MaDon INT NULL REFERENCES dbo.DonDatHang(MaDon),FOREIGN KEY(MaCuaHang,MaMH) REFERENCES dbo.MatHangLuuTru(MaCuaHang,MaMH));
IF OBJECT_ID('dbo.TonKhoThang') IS NULL CREATE TABLE dbo.TonKhoThang (ThangKey BIGINT NOT NULL,MaCuaHang INT NOT NULL,MaMH INT NOT NULL,SoLuong INT NOT NULL CHECK(SoLuong>=0),PRIMARY KEY(ThangKey,MaCuaHang,MaMH),FOREIGN KEY(MaCuaHang,MaMH) REFERENCES dbo.MatHangLuuTru(MaCuaHang,MaMH));
DELETE FROM dbo.TonKhoThang;
DELETE FROM dbo.BienDongKho;
DELETE FROM dbo.PhanBoDonHang;
DELETE FROM dbo.MatHangDuocDat;
DELETE FROM dbo.DonDatHang;
DELETE FROM dbo.MatHangLuuTru;
DELETE FROM dbo.KhachHangBuuDien;
DELETE FROM dbo.KhachHangDuLich;
DELETE FROM dbo.KhachHang;
DELETE FROM dbo.MatHang;
DELETE FROM dbo.CuaHang;
DELETE FROM dbo.VanPhongDaiDien;
INSERT dbo.VanPhongDaiDien (MaThanhPho,TenThanhPho,DiaChiVP,Bang,ThoiGian) SELECT MaThanhPho,TenThanhPho,DiaChiVP,Bang,ThoiGian FROM IDB_BanHang.dbo.VanPhongDaiDien OPTION (MAXDOP 1,MAX_GRANT_PERCENT=0);
INSERT dbo.CuaHang (MaCuaHang,MaThanhPho,SoDienThoai,ThoiGian) SELECT MaCuaHang,MaThanhPho,SoDienThoai,ThoiGian FROM IDB_BanHang.dbo.CuaHang OPTION (MAXDOP 1,MAX_GRANT_PERCENT=0);
INSERT dbo.MatHang (MaMH,MoTa,KichCo,TrongLuong,Gia,ThoiGian) SELECT MaMH,MoTa,KichCo,TrongLuong,Gia,ThoiGian FROM IDB_BanHang.dbo.MatHang OPTION (MAXDOP 1,MAX_GRANT_PERCENT=0);
INSERT dbo.KhachHang (MaKH,TenKH,MaThanhPho,NgayDatHangDauTien) SELECT MaKH,TenKH,MaThanhPho,NgayDatHangDauTien FROM [$(CustomerSource)].dbo.KhachHang OPTION (MAXDOP 1,MAX_GRANT_PERCENT=0);
INSERT dbo.KhachHangDuLich (MaKH,HuongDanVienDuLich,ThoiGian) SELECT MaKH,HuongDanVienDuLich,ThoiGian FROM [$(CustomerSource)].dbo.KhachHangDuLich OPTION (MAXDOP 1,MAX_GRANT_PERCENT=0);
INSERT dbo.KhachHangBuuDien (MaKH,DiaChiBuuDien,ThoiGian) SELECT MaKH,DiaChiBuuDien,ThoiGian FROM [$(CustomerSource)].dbo.KhachHangBuuDien OPTION (MAXDOP 1,MAX_GRANT_PERCENT=0);
INSERT dbo.MatHangLuuTru (MaCuaHang,MaMH,SoLuongTrongKho,ThoiGian) SELECT MaCuaHang,MaMH,SoLuongTrongKho,ThoiGian FROM IDB_BanHang.dbo.MatHangLuuTru OPTION (MAXDOP 1,MAX_GRANT_PERCENT=0);
INSERT dbo.DonDatHang (MaDon,NgayDatHang,MaKH) SELECT MaDon,NgayDatHang,MaKH FROM IDB_BanHang.dbo.DonDatHang OPTION (MAXDOP 1,MAX_GRANT_PERCENT=0);
INSERT dbo.MatHangDuocDat (MaDon,MaMH,SoLuongDat,GiaDat,ThoiGian) SELECT MaDon,MaMH,SoLuongDat,GiaDat,ThoiGian FROM IDB_BanHang.dbo.MatHangDuocDat OPTION (MAXDOP 1,MAX_GRANT_PERCENT=0);
INSERT dbo.PhanBoDonHang (MaDon,MaMH,MaCuaHang,SoLuongCap) SELECT MaDon,MaMH,MaCuaHang,SoLuongCap FROM IDB_BanHang.dbo.PhanBoDonHang OPTION (MAXDOP 1,MAX_GRANT_PERCENT=0);
INSERT dbo.BienDongKho (MaBienDong,MaCuaHang,MaMH,Ngay,Loai,SoLuong,MaDon) SELECT MaBienDong,MaCuaHang,MaMH,Ngay,Loai,SoLuong,MaDon FROM IDB_BanHang.dbo.BienDongKho OPTION (MAXDOP 1,MAX_GRANT_PERCENT=0);
INSERT dbo.TonKhoThang (ThangKey,MaCuaHang,MaMH,SoLuong) SELECT ThangKey,MaCuaHang,MaMH,SoLuong FROM IDB_BanHang.dbo.TonKhoThang OPTION (MAXDOP 1,MAX_GRANT_PERCENT=0);
IF EXISTS (SELECT 1 FROM dbo.MatHangDuocDat d LEFT JOIN
 (SELECT MaDon,MaMH,SUM(SoLuongCap) n FROM dbo.PhanBoDonHang GROUP BY MaDon,MaMH) p
 ON p.MaDon=d.MaDon AND p.MaMH=d.MaMH WHERE ISNULL(p.n,0)<>d.SoLuongDat)
 THROW 51010,'Integrated allocation does not match ordered quantity',1;
COMMIT TRANSACTION;
UPDATE dbo.Integration_Run SET FinishedAt=SYSUTCDATETIME(),Status='SUCCESS',
 OrderLines=(SELECT COUNT(*) FROM dbo.MatHangDuocDat),SnapshotRows=(SELECT COUNT(*) FROM dbo.TonKhoThang) WHERE RunID=@run;
PRINT 'Integrated database loaded: IDB_TichHop (12 tables, checked PK/FK)';
END TRY
BEGIN CATCH
 IF @@TRANCOUNT>0 ROLLBACK TRANSACTION;
 UPDATE dbo.Integration_Run SET FinishedAt=SYSUTCDATETIME(),Status='FAILED',ErrorMessage=ERROR_MESSAGE() WHERE RunID=@run;
 THROW;
END CATCH;
