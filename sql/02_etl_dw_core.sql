/* =====================================================================
   02 - GALAXY SCHEMA (Fact Constellation) DW_Core + ETL tu IDB_TichHop
   Fact_BanHang (grain: dong don hang = ma_don + mh_key)
   Fact_Kho     (grain: thang + cua hang + mat hang)
   Dim dung chung: Dim_ThoiGian, Dim_MatHang, Dim_VPDD (thanh pho/bang)
   Dim_KhachHang -> Dim_VPDD ; Dim_CuaHang -> Dim_VPDD
   ===================================================================== */
USE master;
GO
IF DB_ID('DW_Core') IS NULL CREATE DATABASE DW_Core;
GO
USE DW_Core;
GO
SET XACT_ABORT ON;
BEGIN TRANSACTION;
IF OBJECT_ID('dbo.Fact_PhanBo') IS NOT NULL DROP TABLE dbo.Fact_PhanBo;
IF OBJECT_ID('dbo.Fact_BanHang') IS NOT NULL DROP TABLE dbo.Fact_BanHang;
IF OBJECT_ID('dbo.Fact_Kho')     IS NOT NULL DROP TABLE dbo.Fact_Kho;
IF OBJECT_ID('dbo.Dim_KhachHang')IS NOT NULL DROP TABLE dbo.Dim_KhachHang;
IF OBJECT_ID('dbo.Dim_CuaHang')  IS NOT NULL DROP TABLE dbo.Dim_CuaHang;
IF OBJECT_ID('dbo.Dim_MatHang')  IS NOT NULL DROP TABLE dbo.Dim_MatHang;
IF OBJECT_ID('dbo.Dim_VPDD')     IS NOT NULL DROP TABLE dbo.Dim_VPDD;
IF OBJECT_ID('dbo.Dim_Ngay')     IS NOT NULL DROP TABLE dbo.Dim_Ngay;
IF OBJECT_ID('dbo.Dim_ThoiGian') IS NOT NULL DROP TABLE dbo.Dim_ThoiGian;
GO

CREATE TABLE dbo.Dim_ThoiGian (
    time_key BIGINT PRIMARY KEY,         -- YYYYMM
    thang INT NOT NULL, quy INT NOT NULL, nam INT NOT NULL);
CREATE TABLE dbo.Dim_Ngay (
    ngay_key INT PRIMARY KEY,            -- YYYYMMDD
    ngay DATE NOT NULL,
    time_key BIGINT NOT NULL REFERENCES dbo.Dim_ThoiGian(time_key));
CREATE TABLE dbo.Dim_VPDD (
    vp_key NVARCHAR(20) PRIMARY KEY, ten_tp NVARCHAR(100), dia_chi_vp NVARCHAR(200), bang NVARCHAR(100));
CREATE TABLE dbo.Dim_CuaHang (
    ch_key NVARCHAR(20) PRIMARY KEY, so_dt NVARCHAR(30),
    vp_key NVARCHAR(20) NOT NULL REFERENCES dbo.Dim_VPDD(vp_key));
CREATE TABLE dbo.Dim_MatHang (
    mh_key NVARCHAR(20) PRIMARY KEY, mo_ta NVARCHAR(200), kich_co NVARCHAR(50),
    trong_luong DECIMAL(18,3), gia DECIMAL(18,2));
CREATE TABLE dbo.Dim_KhachHang (          -- table flattening KhachHang + DuLich + BuuDien
    kh_key NVARCHAR(20) PRIMARY KEY, ten NVARCHAR(200),
    vp_key NVARCHAR(20) NULL REFERENCES dbo.Dim_VPDD(vp_key),
    ngay_dat_dau_tien DATE NULL,
    la_du_lich BIT NOT NULL DEFAULT 0, la_buu_dien BIT NOT NULL DEFAULT 0,
    huong_dan_vien NVARCHAR(200) NULL, dia_chi_buu_dien NVARCHAR(300) NULL,
    loai_kh NVARCHAR(30) NOT NULL);       -- DuLich | BuuDien | CaHai | Khac
GO
CREATE TABLE dbo.Fact_BanHang (
    ma_don NVARCHAR(20) NOT NULL,
    mh_key NVARCHAR(20) NOT NULL REFERENCES dbo.Dim_MatHang(mh_key),
    kh_key NVARCHAR(20) NOT NULL REFERENCES dbo.Dim_KhachHang(kh_key),
    ngay_key INT NOT NULL REFERENCES dbo.Dim_Ngay(ngay_key),
    time_key BIGINT NOT NULL REFERENCES dbo.Dim_ThoiGian(time_key),
    so_luong INT NOT NULL, gia_dat DECIMAL(18,2) NOT NULL, tong_tien DECIMAL(18,2) NOT NULL,
    CONSTRAINT PK_Fact_BanHang PRIMARY KEY (ma_don, mh_key));
CREATE TABLE dbo.Fact_PhanBo (
    ma_don NVARCHAR(20) NOT NULL, mh_key NVARCHAR(20) NOT NULL,
    ch_key NVARCHAR(20) NOT NULL REFERENCES dbo.Dim_CuaHang(ch_key),
    so_luong_cap INT NOT NULL CHECK (so_luong_cap > 0),
    PRIMARY KEY (ma_don, mh_key, ch_key),
    FOREIGN KEY (ma_don, mh_key) REFERENCES dbo.Fact_BanHang(ma_don, mh_key));
CREATE TABLE dbo.Fact_Kho (
    time_key BIGINT NOT NULL REFERENCES dbo.Dim_ThoiGian(time_key),
    ch_key NVARCHAR(20) NOT NULL REFERENCES dbo.Dim_CuaHang(ch_key),
    mh_key NVARCHAR(20) NOT NULL REFERENCES dbo.Dim_MatHang(mh_key),
    so_luong INT NOT NULL,
    CONSTRAINT PK_Fact_Kho PRIMARY KEY (time_key, ch_key, mh_key));
GO

/* ===================== ETL ===================== */
INSERT dbo.Dim_VPDD
SELECT CAST(MaThanhPho AS NVARCHAR(20)), TenThanhPho, DiaChiVP, Bang FROM IDB_TichHop.dbo.VanPhongDaiDien OPTION (MAXDOP 1, MAX_GRANT_PERCENT = 0);

INSERT dbo.Dim_CuaHang
SELECT CAST(MaCuaHang AS NVARCHAR(20)), SoDienThoai, CAST(MaThanhPho AS NVARCHAR(20)) FROM IDB_TichHop.dbo.CuaHang OPTION (MAXDOP 1, MAX_GRANT_PERCENT = 0);

INSERT dbo.Dim_MatHang
SELECT CAST(MaMH AS NVARCHAR(20)), MoTa, KichCo, TrongLuong, Gia FROM IDB_TichHop.dbo.MatHang OPTION (MAXDOP 1, MAX_GRANT_PERCENT = 0);

INSERT dbo.Dim_KhachHang
SELECT CAST(k.MaKH AS NVARCHAR(20)), k.TenKH, CAST(k.MaThanhPho AS NVARCHAR(20)), k.NgayDatHangDauTien,
       CASE WHEN dl.MaKH IS NULL THEN 0 ELSE 1 END, CASE WHEN bd.MaKH IS NULL THEN 0 ELSE 1 END,
       dl.HuongDanVienDuLich, bd.DiaChiBuuDien,
       CASE WHEN dl.MaKH IS NOT NULL AND bd.MaKH IS NOT NULL THEN N'CaHai'
            WHEN dl.MaKH IS NOT NULL THEN N'DuLich'
            WHEN bd.MaKH IS NOT NULL THEN N'BuuDien' ELSE N'Khac' END
FROM IDB_TichHop.dbo.KhachHang k
LEFT JOIN IDB_TichHop.dbo.KhachHangDuLich  dl ON dl.MaKH = k.MaKH
LEFT JOIN IDB_TichHop.dbo.KhachHangBuuDien bd ON bd.MaKH = k.MaKH OPTION (MAXDOP 1, MAX_GRANT_PERCENT = 0);

-- Dim_ThoiGian: moi thang tu thang dau tien co don hang den thang cuoi
DECLARE @d0 DATE = (SELECT DATEFROMPARTS(MIN(ThangKey)/100, MIN(ThangKey)%100, 1) FROM IDB_TichHop.dbo.TonKhoThang);
DECLARE @d1 DATE = (SELECT DATEFROMPARTS(MAX(ThangKey)/100, MAX(ThangKey)%100, 1) FROM IDB_TichHop.dbo.TonKhoThang);
;WITH m AS (SELECT @d0 AS d UNION ALL SELECT DATEADD(MONTH,1,d) FROM m WHERE d < @d1)
INSERT dbo.Dim_ThoiGian
SELECT YEAR(d)*100+MONTH(d), MONTH(d), DATEPART(QUARTER,d), YEAR(d) FROM m OPTION (MAXRECURSION 1000, MAXDOP 1, MAX_GRANT_PERCENT = 0);

INSERT dbo.Dim_Ngay
SELECT DISTINCT YEAR(NgayDatHang)*10000+MONTH(NgayDatHang)*100+DAY(NgayDatHang), NgayDatHang,
       YEAR(NgayDatHang)*100+MONTH(NgayDatHang)
FROM IDB_TichHop.dbo.DonDatHang OPTION (MAXDOP 1, MAX_GRANT_PERCENT = 0);

-- Preserve source order lines and source allocation independently.
INSERT dbo.Fact_BanHang
SELECT CAST(o.MaDon AS NVARCHAR(20)), CAST(d.MaMH AS NVARCHAR(20)), CAST(o.MaKH AS NVARCHAR(20)),
       YEAR(o.NgayDatHang)*10000+MONTH(o.NgayDatHang)*100+DAY(o.NgayDatHang),
       YEAR(o.NgayDatHang)*100+MONTH(o.NgayDatHang),
       d.SoLuongDat, d.GiaDat, d.SoLuongDat*d.GiaDat
FROM IDB_TichHop.dbo.DonDatHang o
JOIN IDB_TichHop.dbo.MatHangDuocDat d ON d.MaDon = o.MaDon OPTION (MAXDOP 1, MAX_GRANT_PERCENT = 0);

INSERT dbo.Fact_PhanBo
SELECT CAST(MaDon AS NVARCHAR(20)), CAST(MaMH AS NVARCHAR(20)),
       CAST(MaCuaHang AS NVARCHAR(20)), SoLuongCap FROM IDB_TichHop.dbo.PhanBoDonHang OPTION (MAXDOP 1, MAX_GRANT_PERCENT = 0);

INSERT dbo.Fact_Kho
SELECT ThangKey, CAST(MaCuaHang AS NVARCHAR(20)), CAST(MaMH AS NVARCHAR(20)), SoLuong
FROM IDB_TichHop.dbo.TonKhoThang OPTION (MAXDOP 1, MAX_GRANT_PERCENT = 0);
GO

COMMIT TRANSACTION;
