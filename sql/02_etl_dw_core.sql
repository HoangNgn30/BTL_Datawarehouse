/* =====================================================================
   02 - GALAXY SCHEMA (Fact Constellation) DW_Core + ETL tu IDB_TichHop
   Fact_BanHang : khoa = ngay_key + kh_key + mh_key + ch_key (4 chieu)
                  do do so_luong, doanh_thu (cong duoc theo moi chieu)
   Fact_Kho     : khoa = time_key + ch_key + mh_key (snapshot cuoi thang)
                  do do so_luong (semi-additive: khong cong theo thoi gian)
   Chieu dung chung: Thoi gian (Dim_Ngay -> Dim_ThoiGian), Mat hang,
                     Vi tri (Dim_CuaHang -> Dim_VPDD: cua hang -> thanh pho -> bang)
   Dim_KhachHang -> Dim_VPDD (thanh pho noi khach song)
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
    time_key BIGINT PRIMARY KEY,         -- YYYYMM (cap thang)
    thang INT NOT NULL, quy INT NOT NULL, nam INT NOT NULL);
CREATE TABLE dbo.Dim_Ngay (
    ngay_key INT PRIMARY KEY,            -- YYYYMMDD (cap chi tiet nhat cua thoi gian)
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
    ngay_key INT NOT NULL REFERENCES dbo.Dim_Ngay(ngay_key),
    kh_key NVARCHAR(20) NOT NULL REFERENCES dbo.Dim_KhachHang(kh_key),
    mh_key NVARCHAR(20) NOT NULL REFERENCES dbo.Dim_MatHang(mh_key),
    ch_key NVARCHAR(20) NOT NULL REFERENCES dbo.Dim_CuaHang(ch_key),
    so_luong INT NOT NULL CHECK (so_luong > 0),
    doanh_thu DECIMAL(18,2) NOT NULL CHECK (doanh_thu >= 0),
    CONSTRAINT PK_Fact_BanHang PRIMARY KEY (ngay_key, kh_key, mh_key, ch_key));
CREATE TABLE dbo.Fact_Kho (
    time_key BIGINT NOT NULL REFERENCES dbo.Dim_ThoiGian(time_key),
    ch_key NVARCHAR(20) NOT NULL REFERENCES dbo.Dim_CuaHang(ch_key),
    mh_key NVARCHAR(20) NOT NULL REFERENCES dbo.Dim_MatHang(mh_key),
    so_luong INT NOT NULL CHECK (so_luong >= 0),
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

-- Lich lien tuc: moi thang (Dim_ThoiGian) va moi ngay (Dim_Ngay) phu ca thang dat hang va thang snapshot.
DECLARE @k0 BIGINT, @k1 BIGINT;
SELECT @k0 = MIN(k), @k1 = MAX(k) FROM (
    SELECT ThangKey AS k FROM IDB_TichHop.dbo.TonKhoThang
    UNION ALL
    SELECT YEAR(NgayDatHang)*100 + MONTH(NgayDatHang) FROM IDB_TichHop.dbo.DonDatHang
) months OPTION (MAXDOP 1, MAX_GRANT_PERCENT = 0);
IF @k0 IS NULL THROW 51020, 'Khong co don hang hay snapshot ton kho de sinh chieu thoi gian', 1;
DECLARE @d0 DATE = DATEFROMPARTS(@k0/100, @k0%100, 1);
DECLARE @d1 DATE = EOMONTH(DATEFROMPARTS(@k1/100, @k1%100, 1));
;WITH n AS (SELECT TOP (DATEDIFF(DAY, @d0, @d1) + 1) ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) - 1 AS i
            FROM sys.all_objects a CROSS JOIN sys.all_objects b),
      d AS (SELECT DATEADD(DAY, i, @d0) AS ngay FROM n)
SELECT ngay INTO #Lich FROM d OPTION (MAXDOP 1, MAX_GRANT_PERCENT = 0);

INSERT dbo.Dim_ThoiGian
SELECT DISTINCT YEAR(ngay)*100+MONTH(ngay), MONTH(ngay), DATEPART(QUARTER,ngay), YEAR(ngay) FROM #Lich OPTION (MAXDOP 1, MAX_GRANT_PERCENT = 0);

INSERT dbo.Dim_Ngay
SELECT YEAR(ngay)*10000+MONTH(ngay)*100+DAY(ngay), ngay, YEAR(ngay)*100+MONTH(ngay) FROM #Lich OPTION (MAXDOP 1, MAX_GRANT_PERCENT = 0);
DROP TABLE #Lich;

-- Fact_BanHang: moi lan cap hang (dong don x cua hang cap) gom ve khoa 4 chieu.
-- Cua hang la cua hang thuc cap hang; doanh thu = so luong cap x gia dat cua dong don.
INSERT dbo.Fact_BanHang (ngay_key, kh_key, mh_key, ch_key, so_luong, doanh_thu)
SELECT YEAR(o.NgayDatHang)*10000+MONTH(o.NgayDatHang)*100+DAY(o.NgayDatHang),
       CAST(o.MaKH AS NVARCHAR(20)), CAST(p.MaMH AS NVARCHAR(20)), CAST(p.MaCuaHang AS NVARCHAR(20)),
       SUM(p.SoLuongCap), SUM(p.SoLuongCap * d.GiaDat)
FROM IDB_TichHop.dbo.PhanBoDonHang p
JOIN IDB_TichHop.dbo.MatHangDuocDat d ON d.MaDon = p.MaDon AND d.MaMH = p.MaMH
JOIN IDB_TichHop.dbo.DonDatHang o ON o.MaDon = p.MaDon
GROUP BY o.NgayDatHang, o.MaKH, p.MaMH, p.MaCuaHang OPTION (MAXDOP 1, MAX_GRANT_PERCENT = 0);

INSERT dbo.Fact_Kho
SELECT ThangKey, CAST(MaCuaHang AS NVARCHAR(20)), CAST(MaMH AS NVARCHAR(20)), SoLuong
FROM IDB_TichHop.dbo.TonKhoThang OPTION (MAXDOP 1, MAX_GRANT_PERCENT = 0);
GO

COMMIT TRANSACTION;
GO
