-- ============================================================
-- SCRIPT TẠO 56 BẢNG CUBOID — OLAP_QuanLyBanHang
-- Tên bảng: tiếng Việt viết tắt (ds=doanh_so, tk=ton_kho)
-- Tên cột dimension: giữ nguyên từ DW_Core
-- Tên cột measure: tong_so_luong, tong_doanh_thu, tong_ton_kho
-- Chạy sau khi đã: CREATE DATABASE OLAP_QuanLyBanHang
-- ============================================================

USE OLAP_QuanLyBanHang;
GO

-- ============================================================
-- PHẦN 1: SALES CUBE (24 bảng — olap_ds_*)
-- Measures: tong_so_luong = SUM(so_luong), tong_doanh_thu = SUM(tong_tien)
-- Chiều: Time(4) × MatHang(2) × KhachHang(3) = 24
-- ============================================================

-- ------------------------------------------------------------
-- 0-D (1 bảng)
-- ------------------------------------------------------------

-- [1] olap_ds_all
SELECT
    SUM(f.so_luong)   AS tong_so_luong,
    SUM(f.tong_tien)  AS tong_doanh_thu
INTO OLAP_QuanLyBanHang.dbo.olap_ds_all
FROM DW_Core.dbo.Fact_BanHang f;

-- ------------------------------------------------------------
-- 1-D (6 bảng)
-- ------------------------------------------------------------

-- [2] olap_ds_nam
SELECT
    t.nam,
    SUM(f.so_luong)   AS tong_so_luong,
    SUM(f.tong_tien)  AS tong_doanh_thu
INTO OLAP_QuanLyBanHang.dbo.olap_ds_nam
FROM DW_Core.dbo.Fact_BanHang f
JOIN DW_Core.dbo.Dim_ThoiGian t ON f.time_key = t.time_key
GROUP BY t.nam;

-- [3] olap_ds_quy
SELECT
    t.nam,
    t.quy,
    SUM(f.so_luong)   AS tong_so_luong,
    SUM(f.tong_tien)  AS tong_doanh_thu
INTO OLAP_QuanLyBanHang.dbo.olap_ds_quy
FROM DW_Core.dbo.Fact_BanHang f
JOIN DW_Core.dbo.Dim_ThoiGian t ON f.time_key = t.time_key
GROUP BY t.nam, t.quy;

-- [4] olap_ds_thang
SELECT
    t.nam,
    t.quy,
    t.thang,
    SUM(f.so_luong)   AS tong_so_luong,
    SUM(f.tong_tien)  AS tong_doanh_thu
INTO OLAP_QuanLyBanHang.dbo.olap_ds_thang
FROM DW_Core.dbo.Fact_BanHang f
JOIN DW_Core.dbo.Dim_ThoiGian t ON f.time_key = t.time_key
GROUP BY t.nam, t.quy, t.thang;

-- [5] olap_ds_mh
SELECT
    mh.mh_key,
    mh.mo_ta,
    mh.kich_co,
    mh.gia,
    SUM(f.so_luong)   AS tong_so_luong,
    SUM(f.tong_tien)  AS tong_doanh_thu
INTO OLAP_QuanLyBanHang.dbo.olap_ds_mh
FROM DW_Core.dbo.Fact_BanHang f
JOIN DW_Core.dbo.Dim_MatHang mh ON f.mh_key = mh.mh_key
GROUP BY mh.mh_key, mh.mo_ta, mh.kich_co, mh.gia;

-- [6] olap_ds_loai_kh
SELECT
    kh.loai_kh,
    SUM(f.so_luong)   AS tong_so_luong,
    SUM(f.tong_tien)  AS tong_doanh_thu
INTO OLAP_QuanLyBanHang.dbo.olap_ds_loai_kh
FROM DW_Core.dbo.Fact_BanHang f
JOIN DW_Core.dbo.Dim_KhachHang kh ON f.kh_key = kh.kh_key
GROUP BY kh.loai_kh;

-- [7] olap_ds_kh
SELECT
    kh.kh_key,
    kh.ten,
    kh.loai_kh,
    SUM(f.so_luong)   AS tong_so_luong,
    SUM(f.tong_tien)  AS tong_doanh_thu
INTO OLAP_QuanLyBanHang.dbo.olap_ds_kh
FROM DW_Core.dbo.Fact_BanHang f
JOIN DW_Core.dbo.Dim_KhachHang kh ON f.kh_key = kh.kh_key
GROUP BY kh.kh_key, kh.ten, kh.loai_kh;

-- ------------------------------------------------------------
-- 2-D (12 bảng)
-- ------------------------------------------------------------

-- [8] olap_ds_nam_mh
SELECT
    t.nam,
    mh.mh_key,
    mh.mo_ta,
    SUM(f.so_luong)   AS tong_so_luong,
    SUM(f.tong_tien)  AS tong_doanh_thu
INTO OLAP_QuanLyBanHang.dbo.olap_ds_nam_mh
FROM DW_Core.dbo.Fact_BanHang f
JOIN DW_Core.dbo.Dim_ThoiGian t  ON f.time_key = t.time_key
JOIN DW_Core.dbo.Dim_MatHang  mh ON f.mh_key   = mh.mh_key
GROUP BY t.nam, mh.mh_key, mh.mo_ta;

-- [9] olap_ds_quy_mh
SELECT
    t.nam,
    t.quy,
    mh.mh_key,
    mh.mo_ta,
    SUM(f.so_luong)   AS tong_so_luong,
    SUM(f.tong_tien)  AS tong_doanh_thu
INTO OLAP_QuanLyBanHang.dbo.olap_ds_quy_mh
FROM DW_Core.dbo.Fact_BanHang f
JOIN DW_Core.dbo.Dim_ThoiGian t  ON f.time_key = t.time_key
JOIN DW_Core.dbo.Dim_MatHang  mh ON f.mh_key   = mh.mh_key
GROUP BY t.nam, t.quy, mh.mh_key, mh.mo_ta;

-- [10] olap_ds_thang_mh
SELECT
    t.nam,
    t.quy,
    t.thang,
    mh.mh_key,
    mh.mo_ta,
    SUM(f.so_luong)   AS tong_so_luong,
    SUM(f.tong_tien)  AS tong_doanh_thu
INTO OLAP_QuanLyBanHang.dbo.olap_ds_thang_mh
FROM DW_Core.dbo.Fact_BanHang f
JOIN DW_Core.dbo.Dim_ThoiGian t  ON f.time_key = t.time_key
JOIN DW_Core.dbo.Dim_MatHang  mh ON f.mh_key   = mh.mh_key
GROUP BY t.nam, t.quy, t.thang, mh.mh_key, mh.mo_ta;

-- [11] olap_ds_nam_loai_kh
SELECT
    t.nam,
    kh.loai_kh,
    SUM(f.so_luong)   AS tong_so_luong,
    SUM(f.tong_tien)  AS tong_doanh_thu
INTO OLAP_QuanLyBanHang.dbo.olap_ds_nam_loai_kh
FROM DW_Core.dbo.Fact_BanHang f
JOIN DW_Core.dbo.Dim_ThoiGian  t  ON f.time_key = t.time_key
JOIN DW_Core.dbo.Dim_KhachHang kh ON f.kh_key   = kh.kh_key
GROUP BY t.nam, kh.loai_kh;

-- [12] olap_ds_quy_loai_kh
SELECT
    t.nam,
    t.quy,
    kh.loai_kh,
    SUM(f.so_luong)   AS tong_so_luong,
    SUM(f.tong_tien)  AS tong_doanh_thu
INTO OLAP_QuanLyBanHang.dbo.olap_ds_quy_loai_kh
FROM DW_Core.dbo.Fact_BanHang f
JOIN DW_Core.dbo.Dim_ThoiGian  t  ON f.time_key = t.time_key
JOIN DW_Core.dbo.Dim_KhachHang kh ON f.kh_key   = kh.kh_key
GROUP BY t.nam, t.quy, kh.loai_kh;

-- [13] olap_ds_thang_loai_kh
SELECT
    t.nam,
    t.quy,
    t.thang,
    kh.loai_kh,
    SUM(f.so_luong)   AS tong_so_luong,
    SUM(f.tong_tien)  AS tong_doanh_thu
INTO OLAP_QuanLyBanHang.dbo.olap_ds_thang_loai_kh
FROM DW_Core.dbo.Fact_BanHang f
JOIN DW_Core.dbo.Dim_ThoiGian  t  ON f.time_key = t.time_key
JOIN DW_Core.dbo.Dim_KhachHang kh ON f.kh_key   = kh.kh_key
GROUP BY t.nam, t.quy, t.thang, kh.loai_kh;

-- [14] olap_ds_nam_kh
SELECT
    t.nam,
    kh.kh_key,
    kh.ten,
    kh.loai_kh,
    SUM(f.so_luong)   AS tong_so_luong,
    SUM(f.tong_tien)  AS tong_doanh_thu
INTO OLAP_QuanLyBanHang.dbo.olap_ds_nam_kh
FROM DW_Core.dbo.Fact_BanHang f
JOIN DW_Core.dbo.Dim_ThoiGian  t  ON f.time_key = t.time_key
JOIN DW_Core.dbo.Dim_KhachHang kh ON f.kh_key   = kh.kh_key
GROUP BY t.nam, kh.kh_key, kh.ten, kh.loai_kh;

-- [15] olap_ds_quy_kh
SELECT
    t.nam,
    t.quy,
    kh.kh_key,
    kh.ten,
    kh.loai_kh,
    SUM(f.so_luong)   AS tong_so_luong,
    SUM(f.tong_tien)  AS tong_doanh_thu
INTO OLAP_QuanLyBanHang.dbo.olap_ds_quy_kh
FROM DW_Core.dbo.Fact_BanHang f
JOIN DW_Core.dbo.Dim_ThoiGian  t  ON f.time_key = t.time_key
JOIN DW_Core.dbo.Dim_KhachHang kh ON f.kh_key   = kh.kh_key
GROUP BY t.nam, t.quy, kh.kh_key, kh.ten, kh.loai_kh;

-- [16] olap_ds_thang_kh
SELECT
    t.nam,
    t.quy,
    t.thang,
    kh.kh_key,
    kh.ten,
    kh.loai_kh,
    SUM(f.so_luong)   AS tong_so_luong,
    SUM(f.tong_tien)  AS tong_doanh_thu
INTO OLAP_QuanLyBanHang.dbo.olap_ds_thang_kh
FROM DW_Core.dbo.Fact_BanHang f
JOIN DW_Core.dbo.Dim_ThoiGian  t  ON f.time_key = t.time_key
JOIN DW_Core.dbo.Dim_KhachHang kh ON f.kh_key   = kh.kh_key
GROUP BY t.nam, t.quy, t.thang, kh.kh_key, kh.ten, kh.loai_kh;

-- [17] olap_ds_mh_loai_kh
SELECT
    mh.mh_key,
    mh.mo_ta,
    kh.loai_kh,
    SUM(f.so_luong)   AS tong_so_luong,
    SUM(f.tong_tien)  AS tong_doanh_thu
INTO OLAP_QuanLyBanHang.dbo.olap_ds_mh_loai_kh
FROM DW_Core.dbo.Fact_BanHang f
JOIN DW_Core.dbo.Dim_MatHang   mh ON f.mh_key = mh.mh_key
JOIN DW_Core.dbo.Dim_KhachHang kh ON f.kh_key = kh.kh_key
GROUP BY mh.mh_key, mh.mo_ta, kh.loai_kh;

-- [18] olap_ds_mh_kh
SELECT
    mh.mh_key,
    mh.mo_ta,
    kh.kh_key,
    kh.ten,
    kh.loai_kh,
    SUM(f.so_luong)   AS tong_so_luong,
    SUM(f.tong_tien)  AS tong_doanh_thu
INTO OLAP_QuanLyBanHang.dbo.olap_ds_mh_kh
FROM DW_Core.dbo.Fact_BanHang f
JOIN DW_Core.dbo.Dim_MatHang   mh ON f.mh_key = mh.mh_key
JOIN DW_Core.dbo.Dim_KhachHang kh ON f.kh_key = kh.kh_key
GROUP BY mh.mh_key, mh.mo_ta, kh.kh_key, kh.ten, kh.loai_kh;

-- [19] olap_ds_loai_kh_kh
SELECT
    kh.loai_kh,
    kh.kh_key,
    kh.ten,
    SUM(f.so_luong)   AS tong_so_luong,
    SUM(f.tong_tien)  AS tong_doanh_thu
INTO OLAP_QuanLyBanHang.dbo.olap_ds_loai_kh_kh
FROM DW_Core.dbo.Fact_BanHang f
JOIN DW_Core.dbo.Dim_KhachHang kh ON f.kh_key = kh.kh_key
GROUP BY kh.loai_kh, kh.kh_key, kh.ten;

-- ------------------------------------------------------------
-- 3-D (5 bảng)
-- ------------------------------------------------------------

-- [20] olap_ds_nam_mh_loai_kh
SELECT
    t.nam,
    mh.mh_key,
    mh.mo_ta,
    kh.loai_kh,
    SUM(f.so_luong)   AS tong_so_luong,
    SUM(f.tong_tien)  AS tong_doanh_thu
INTO OLAP_QuanLyBanHang.dbo.olap_ds_nam_mh_loai_kh
FROM DW_Core.dbo.Fact_BanHang f
JOIN DW_Core.dbo.Dim_ThoiGian  t  ON f.time_key = t.time_key
JOIN DW_Core.dbo.Dim_MatHang   mh ON f.mh_key   = mh.mh_key
JOIN DW_Core.dbo.Dim_KhachHang kh ON f.kh_key   = kh.kh_key
GROUP BY t.nam, mh.mh_key, mh.mo_ta, kh.loai_kh;

-- [21] olap_ds_quy_mh_loai_kh
SELECT
    t.nam,
    t.quy,
    mh.mh_key,
    mh.mo_ta,
    kh.loai_kh,
    SUM(f.so_luong)   AS tong_so_luong,
    SUM(f.tong_tien)  AS tong_doanh_thu
INTO OLAP_QuanLyBanHang.dbo.olap_ds_quy_mh_loai_kh
FROM DW_Core.dbo.Fact_BanHang f
JOIN DW_Core.dbo.Dim_ThoiGian  t  ON f.time_key = t.time_key
JOIN DW_Core.dbo.Dim_MatHang   mh ON f.mh_key   = mh.mh_key
JOIN DW_Core.dbo.Dim_KhachHang kh ON f.kh_key   = kh.kh_key
GROUP BY t.nam, t.quy, mh.mh_key, mh.mo_ta, kh.loai_kh;

-- [22] olap_ds_thang_mh_loai_kh
SELECT
    t.nam,
    t.quy,
    t.thang,
    mh.mh_key,
    mh.mo_ta,
    kh.loai_kh,
    SUM(f.so_luong)   AS tong_so_luong,
    SUM(f.tong_tien)  AS tong_doanh_thu
INTO OLAP_QuanLyBanHang.dbo.olap_ds_thang_mh_loai_kh
FROM DW_Core.dbo.Fact_BanHang f
JOIN DW_Core.dbo.Dim_ThoiGian  t  ON f.time_key = t.time_key
JOIN DW_Core.dbo.Dim_MatHang   mh ON f.mh_key   = mh.mh_key
JOIN DW_Core.dbo.Dim_KhachHang kh ON f.kh_key   = kh.kh_key
GROUP BY t.nam, t.quy, t.thang, mh.mh_key, mh.mo_ta, kh.loai_kh;

-- [23] olap_ds_nam_mh_kh
SELECT
    t.nam,
    mh.mh_key,
    mh.mo_ta,
    kh.kh_key,
    kh.ten,
    kh.loai_kh,
    SUM(f.so_luong)   AS tong_so_luong,
    SUM(f.tong_tien)  AS tong_doanh_thu
INTO OLAP_QuanLyBanHang.dbo.olap_ds_nam_mh_kh
FROM DW_Core.dbo.Fact_BanHang f
JOIN DW_Core.dbo.Dim_ThoiGian  t  ON f.time_key = t.time_key
JOIN DW_Core.dbo.Dim_MatHang   mh ON f.mh_key   = mh.mh_key
JOIN DW_Core.dbo.Dim_KhachHang kh ON f.kh_key   = kh.kh_key
GROUP BY t.nam, mh.mh_key, mh.mo_ta, kh.kh_key, kh.ten, kh.loai_kh;

-- [24] olap_ds_thang_mh_kh
SELECT
    t.nam,
    t.quy,
    t.thang,
    mh.mh_key,
    mh.mo_ta,
    kh.kh_key,
    kh.ten,
    kh.loai_kh,
    SUM(f.so_luong)   AS tong_so_luong,
    SUM(f.tong_tien)  AS tong_doanh_thu
INTO OLAP_QuanLyBanHang.dbo.olap_ds_thang_mh_kh
FROM DW_Core.dbo.Fact_BanHang f
JOIN DW_Core.dbo.Dim_ThoiGian  t  ON f.time_key = t.time_key
JOIN DW_Core.dbo.Dim_MatHang   mh ON f.mh_key   = mh.mh_key
JOIN DW_Core.dbo.Dim_KhachHang kh ON f.kh_key   = kh.kh_key
GROUP BY t.nam, t.quy, t.thang, mh.mh_key, mh.mo_ta, kh.kh_key, kh.ten, kh.loai_kh;


-- ============================================================
-- PHẦN 2: INVENTORY CUBE (32 bảng — olap_tk_*)
-- Measure: tong_ton_kho = SUM(so_luong) của snapshot mới nhất
-- Chiều: Time(4) × MatHang(2) × CuaHang(4) = 32
-- ============================================================

-- ------------------------------------------------------------
-- 0-D (1 bảng)
-- ------------------------------------------------------------

-- [25] olap_tk_all
SELECT
    SUM(f.so_luong) AS tong_ton_kho
INTO OLAP_QuanLyBanHang.dbo.olap_tk_all
FROM DW_Core.dbo.Fact_Kho f
WHERE f.time_key = (
    SELECT MAX(f2.time_key)
    FROM DW_Core.dbo.Fact_Kho f2
    WHERE f2.ch_key = f.ch_key
      AND f2.mh_key = f.mh_key
);

-- ------------------------------------------------------------
-- 1-D (7 bảng)
-- ------------------------------------------------------------

-- [26] olap_tk_nam
SELECT
    t.nam,
    SUM(f.so_luong) AS tong_ton_kho
INTO OLAP_QuanLyBanHang.dbo.olap_tk_nam
FROM DW_Core.dbo.Fact_Kho f
JOIN DW_Core.dbo.Dim_ThoiGian t ON f.time_key = t.time_key
WHERE f.time_key = (
    SELECT MAX(f2.time_key)
    FROM DW_Core.dbo.Fact_Kho f2
    WHERE f2.ch_key = f.ch_key
      AND f2.mh_key = f.mh_key
      AND f2.time_key / 100 = t.nam
)
GROUP BY t.nam;

-- [27] olap_tk_quy
SELECT
    t.nam,
    t.quy,
    SUM(f.so_luong) AS tong_ton_kho
INTO OLAP_QuanLyBanHang.dbo.olap_tk_quy
FROM DW_Core.dbo.Fact_Kho f
JOIN DW_Core.dbo.Dim_ThoiGian t ON f.time_key = t.time_key
WHERE f.time_key = (
    SELECT MAX(f2.time_key)
    FROM DW_Core.dbo.Fact_Kho f2
    JOIN DW_Core.dbo.Dim_ThoiGian t2 ON f2.time_key = t2.time_key
    WHERE f2.ch_key = f.ch_key
      AND f2.mh_key = f.mh_key
      AND t2.nam = t.nam
      AND t2.quy = t.quy
)
GROUP BY t.nam, t.quy;

-- [28] olap_tk_thang
-- (month level: mỗi tháng chỉ có 1 snapshot → SUM trực tiếp)
SELECT
    t.nam,
    t.quy,
    t.thang,
    SUM(f.so_luong) AS tong_ton_kho
INTO OLAP_QuanLyBanHang.dbo.olap_tk_thang
FROM DW_Core.dbo.Fact_Kho f
JOIN DW_Core.dbo.Dim_ThoiGian t ON f.time_key = t.time_key
GROUP BY t.nam, t.quy, t.thang;

-- [29] olap_tk_mh
SELECT
    mh.mh_key,
    mh.mo_ta,
    SUM(f.so_luong) AS tong_ton_kho
INTO OLAP_QuanLyBanHang.dbo.olap_tk_mh
FROM DW_Core.dbo.Fact_Kho f
JOIN DW_Core.dbo.Dim_MatHang mh ON f.mh_key = mh.mh_key
WHERE f.time_key = (
    SELECT MAX(f2.time_key)
    FROM DW_Core.dbo.Fact_Kho f2
    WHERE f2.ch_key = f.ch_key
      AND f2.mh_key = f.mh_key
)
GROUP BY mh.mh_key, mh.mo_ta;

-- [30] olap_tk_tinh
SELECT
    vp.bang,
    SUM(f.so_luong) AS tong_ton_kho
INTO OLAP_QuanLyBanHang.dbo.olap_tk_tinh
FROM DW_Core.dbo.Fact_Kho f
JOIN DW_Core.dbo.Dim_CuaHang ch ON f.ch_key  = ch.ch_key
JOIN DW_Core.dbo.Dim_VPDD    vp ON ch.vp_key = vp.vp_key
WHERE f.time_key = (
    SELECT MAX(f2.time_key)
    FROM DW_Core.dbo.Fact_Kho f2
    WHERE f2.ch_key = f.ch_key
      AND f2.mh_key = f.mh_key
)
GROUP BY vp.bang;

-- [31] olap_tk_tp
SELECT
    vp.bang,
    vp.ten_tp,
    SUM(f.so_luong) AS tong_ton_kho
INTO OLAP_QuanLyBanHang.dbo.olap_tk_tp
FROM DW_Core.dbo.Fact_Kho f
JOIN DW_Core.dbo.Dim_CuaHang ch ON f.ch_key  = ch.ch_key
JOIN DW_Core.dbo.Dim_VPDD    vp ON ch.vp_key = vp.vp_key
WHERE f.time_key = (
    SELECT MAX(f2.time_key)
    FROM DW_Core.dbo.Fact_Kho f2
    WHERE f2.ch_key = f.ch_key
      AND f2.mh_key = f.mh_key
)
GROUP BY vp.bang, vp.ten_tp;

-- [32] olap_tk_ch
SELECT
    f.ch_key,
    SUM(f.so_luong) AS tong_ton_kho
INTO OLAP_QuanLyBanHang.dbo.olap_tk_ch
FROM DW_Core.dbo.Fact_Kho f
WHERE f.time_key = (
    SELECT MAX(f2.time_key)
    FROM DW_Core.dbo.Fact_Kho f2
    WHERE f2.ch_key = f.ch_key
      AND f2.mh_key = f.mh_key
)
GROUP BY f.ch_key;

-- ------------------------------------------------------------
-- 2-D (15 bảng)
-- ------------------------------------------------------------

-- [33] olap_tk_nam_mh
SELECT
    t.nam,
    mh.mh_key,
    mh.mo_ta,
    SUM(f.so_luong) AS tong_ton_kho
INTO OLAP_QuanLyBanHang.dbo.olap_tk_nam_mh
FROM DW_Core.dbo.Fact_Kho f
JOIN DW_Core.dbo.Dim_ThoiGian t  ON f.time_key = t.time_key
JOIN DW_Core.dbo.Dim_MatHang  mh ON f.mh_key   = mh.mh_key
WHERE f.time_key = (
    SELECT MAX(f2.time_key)
    FROM DW_Core.dbo.Fact_Kho f2
    WHERE f2.ch_key = f.ch_key
      AND f2.mh_key = f.mh_key
      AND f2.time_key / 100 = t.nam
)
GROUP BY t.nam, mh.mh_key, mh.mo_ta;

-- [34] olap_tk_quy_mh
SELECT
    t.nam,
    t.quy,
    mh.mh_key,
    mh.mo_ta,
    SUM(f.so_luong) AS tong_ton_kho
INTO OLAP_QuanLyBanHang.dbo.olap_tk_quy_mh
FROM DW_Core.dbo.Fact_Kho f
JOIN DW_Core.dbo.Dim_ThoiGian t  ON f.time_key = t.time_key
JOIN DW_Core.dbo.Dim_MatHang  mh ON f.mh_key   = mh.mh_key
WHERE f.time_key = (
    SELECT MAX(f2.time_key)
    FROM DW_Core.dbo.Fact_Kho f2
    JOIN DW_Core.dbo.Dim_ThoiGian t2 ON f2.time_key = t2.time_key
    WHERE f2.ch_key = f.ch_key
      AND f2.mh_key = f.mh_key
      AND t2.nam = t.nam
      AND t2.quy = t.quy
)
GROUP BY t.nam, t.quy, mh.mh_key, mh.mo_ta;

-- [35] olap_tk_thang_mh
SELECT
    t.nam,
    t.quy,
    t.thang,
    mh.mh_key,
    mh.mo_ta,
    SUM(f.so_luong) AS tong_ton_kho
INTO OLAP_QuanLyBanHang.dbo.olap_tk_thang_mh
FROM DW_Core.dbo.Fact_Kho f
JOIN DW_Core.dbo.Dim_ThoiGian t  ON f.time_key = t.time_key
JOIN DW_Core.dbo.Dim_MatHang  mh ON f.mh_key   = mh.mh_key
GROUP BY t.nam, t.quy, t.thang, mh.mh_key, mh.mo_ta;

-- [36] olap_tk_nam_tinh
SELECT
    t.nam,
    vp.bang,
    SUM(f.so_luong) AS tong_ton_kho
INTO OLAP_QuanLyBanHang.dbo.olap_tk_nam_tinh
FROM DW_Core.dbo.Fact_Kho f
JOIN DW_Core.dbo.Dim_ThoiGian t  ON f.time_key = t.time_key
JOIN DW_Core.dbo.Dim_CuaHang  ch ON f.ch_key   = ch.ch_key
JOIN DW_Core.dbo.Dim_VPDD     vp ON ch.vp_key  = vp.vp_key
WHERE f.time_key = (
    SELECT MAX(f2.time_key)
    FROM DW_Core.dbo.Fact_Kho f2
    WHERE f2.ch_key = f.ch_key
      AND f2.mh_key = f.mh_key
      AND f2.time_key / 100 = t.nam
)
GROUP BY t.nam, vp.bang;

-- [37] olap_tk_quy_tinh
SELECT
    t.nam,
    t.quy,
    vp.bang,
    SUM(f.so_luong) AS tong_ton_kho
INTO OLAP_QuanLyBanHang.dbo.olap_tk_quy_tinh
FROM DW_Core.dbo.Fact_Kho f
JOIN DW_Core.dbo.Dim_ThoiGian t  ON f.time_key = t.time_key
JOIN DW_Core.dbo.Dim_CuaHang  ch ON f.ch_key   = ch.ch_key
JOIN DW_Core.dbo.Dim_VPDD     vp ON ch.vp_key  = vp.vp_key
WHERE f.time_key = (
    SELECT MAX(f2.time_key)
    FROM DW_Core.dbo.Fact_Kho f2
    JOIN DW_Core.dbo.Dim_ThoiGian t2 ON f2.time_key = t2.time_key
    WHERE f2.ch_key = f.ch_key
      AND f2.mh_key = f.mh_key
      AND t2.nam = t.nam
      AND t2.quy = t.quy
)
GROUP BY t.nam, t.quy, vp.bang;

-- [38] olap_tk_thang_tinh
SELECT
    t.nam,
    t.quy,
    t.thang,
    vp.bang,
    SUM(f.so_luong) AS tong_ton_kho
INTO OLAP_QuanLyBanHang.dbo.olap_tk_thang_tinh
FROM DW_Core.dbo.Fact_Kho f
JOIN DW_Core.dbo.Dim_ThoiGian t  ON f.time_key = t.time_key
JOIN DW_Core.dbo.Dim_CuaHang  ch ON f.ch_key   = ch.ch_key
JOIN DW_Core.dbo.Dim_VPDD     vp ON ch.vp_key  = vp.vp_key
GROUP BY t.nam, t.quy, t.thang, vp.bang;

-- [39] olap_tk_nam_tp
SELECT
    t.nam,
    vp.bang,
    vp.ten_tp,
    SUM(f.so_luong) AS tong_ton_kho
INTO OLAP_QuanLyBanHang.dbo.olap_tk_nam_tp
FROM DW_Core.dbo.Fact_Kho f
JOIN DW_Core.dbo.Dim_ThoiGian t  ON f.time_key = t.time_key
JOIN DW_Core.dbo.Dim_CuaHang  ch ON f.ch_key   = ch.ch_key
JOIN DW_Core.dbo.Dim_VPDD     vp ON ch.vp_key  = vp.vp_key
WHERE f.time_key = (
    SELECT MAX(f2.time_key)
    FROM DW_Core.dbo.Fact_Kho f2
    WHERE f2.ch_key = f.ch_key
      AND f2.mh_key = f.mh_key
      AND f2.time_key / 100 = t.nam
)
GROUP BY t.nam, vp.bang, vp.ten_tp;

-- [40] olap_tk_quy_tp
SELECT
    t.nam,
    t.quy,
    vp.bang,
    vp.ten_tp,
    SUM(f.so_luong) AS tong_ton_kho
INTO OLAP_QuanLyBanHang.dbo.olap_tk_quy_tp
FROM DW_Core.dbo.Fact_Kho f
JOIN DW_Core.dbo.Dim_ThoiGian t  ON f.time_key = t.time_key
JOIN DW_Core.dbo.Dim_CuaHang  ch ON f.ch_key   = ch.ch_key
JOIN DW_Core.dbo.Dim_VPDD     vp ON ch.vp_key  = vp.vp_key
WHERE f.time_key = (
    SELECT MAX(f2.time_key)
    FROM DW_Core.dbo.Fact_Kho f2
    JOIN DW_Core.dbo.Dim_ThoiGian t2 ON f2.time_key = t2.time_key
    WHERE f2.ch_key = f.ch_key
      AND f2.mh_key = f.mh_key
      AND t2.nam = t.nam
      AND t2.quy = t.quy
)
GROUP BY t.nam, t.quy, vp.bang, vp.ten_tp;

-- [41] olap_tk_thang_tp
SELECT
    t.nam,
    t.quy,
    t.thang,
    vp.bang,
    vp.ten_tp,
    SUM(f.so_luong) AS tong_ton_kho
INTO OLAP_QuanLyBanHang.dbo.olap_tk_thang_tp
FROM DW_Core.dbo.Fact_Kho f
JOIN DW_Core.dbo.Dim_ThoiGian t  ON f.time_key = t.time_key
JOIN DW_Core.dbo.Dim_CuaHang  ch ON f.ch_key   = ch.ch_key
JOIN DW_Core.dbo.Dim_VPDD     vp ON ch.vp_key  = vp.vp_key
GROUP BY t.nam, t.quy, t.thang, vp.bang, vp.ten_tp;

-- [42] olap_tk_nam_ch
SELECT
    t.nam,
    f.ch_key,
    SUM(f.so_luong) AS tong_ton_kho
INTO OLAP_QuanLyBanHang.dbo.olap_tk_nam_ch
FROM DW_Core.dbo.Fact_Kho f
JOIN DW_Core.dbo.Dim_ThoiGian t ON f.time_key = t.time_key
WHERE f.time_key = (
    SELECT MAX(f2.time_key)
    FROM DW_Core.dbo.Fact_Kho f2
    WHERE f2.ch_key = f.ch_key
      AND f2.mh_key = f.mh_key
      AND f2.time_key / 100 = t.nam
)
GROUP BY t.nam, f.ch_key;

-- [43] olap_tk_quy_ch
SELECT
    t.nam,
    t.quy,
    f.ch_key,
    SUM(f.so_luong) AS tong_ton_kho
INTO OLAP_QuanLyBanHang.dbo.olap_tk_quy_ch
FROM DW_Core.dbo.Fact_Kho f
JOIN DW_Core.dbo.Dim_ThoiGian t ON f.time_key = t.time_key
WHERE f.time_key = (
    SELECT MAX(f2.time_key)
    FROM DW_Core.dbo.Fact_Kho f2
    JOIN DW_Core.dbo.Dim_ThoiGian t2 ON f2.time_key = t2.time_key
    WHERE f2.ch_key = f.ch_key
      AND f2.mh_key = f.mh_key
      AND t2.nam = t.nam
      AND t2.quy = t.quy
)
GROUP BY t.nam, t.quy, f.ch_key;

-- [44] olap_tk_thang_ch
SELECT
    t.nam,
    t.quy,
    t.thang,
    f.ch_key,
    SUM(f.so_luong) AS tong_ton_kho
INTO OLAP_QuanLyBanHang.dbo.olap_tk_thang_ch
FROM DW_Core.dbo.Fact_Kho f
JOIN DW_Core.dbo.Dim_ThoiGian t ON f.time_key = t.time_key
GROUP BY t.nam, t.quy, t.thang, f.ch_key;

-- [45] olap_tk_mh_tinh
SELECT
    mh.mh_key,
    mh.mo_ta,
    vp.bang,
    SUM(f.so_luong) AS tong_ton_kho
INTO OLAP_QuanLyBanHang.dbo.olap_tk_mh_tinh
FROM DW_Core.dbo.Fact_Kho f
JOIN DW_Core.dbo.Dim_MatHang  mh ON f.mh_key  = mh.mh_key
JOIN DW_Core.dbo.Dim_CuaHang  ch ON f.ch_key  = ch.ch_key
JOIN DW_Core.dbo.Dim_VPDD     vp ON ch.vp_key = vp.vp_key
WHERE f.time_key = (
    SELECT MAX(f2.time_key)
    FROM DW_Core.dbo.Fact_Kho f2
    WHERE f2.ch_key = f.ch_key
      AND f2.mh_key = f.mh_key
)
GROUP BY mh.mh_key, mh.mo_ta, vp.bang;

-- [46] olap_tk_mh_tp
SELECT
    mh.mh_key,
    mh.mo_ta,
    vp.bang,
    vp.ten_tp,
    SUM(f.so_luong) AS tong_ton_kho
INTO OLAP_QuanLyBanHang.dbo.olap_tk_mh_tp
FROM DW_Core.dbo.Fact_Kho f
JOIN DW_Core.dbo.Dim_MatHang  mh ON f.mh_key  = mh.mh_key
JOIN DW_Core.dbo.Dim_CuaHang  ch ON f.ch_key  = ch.ch_key
JOIN DW_Core.dbo.Dim_VPDD     vp ON ch.vp_key = vp.vp_key
WHERE f.time_key = (
    SELECT MAX(f2.time_key)
    FROM DW_Core.dbo.Fact_Kho f2
    WHERE f2.ch_key = f.ch_key
      AND f2.mh_key = f.mh_key
)
GROUP BY mh.mh_key, mh.mo_ta, vp.bang, vp.ten_tp;

-- [47] olap_tk_mh_ch
SELECT
    mh.mh_key,
    mh.mo_ta,
    f.ch_key,
    SUM(f.so_luong) AS tong_ton_kho
INTO OLAP_QuanLyBanHang.dbo.olap_tk_mh_ch
FROM DW_Core.dbo.Fact_Kho f
JOIN DW_Core.dbo.Dim_MatHang mh ON f.mh_key = mh.mh_key
WHERE f.time_key = (
    SELECT MAX(f2.time_key)
    FROM DW_Core.dbo.Fact_Kho f2
    WHERE f2.ch_key = f.ch_key
      AND f2.mh_key = f.mh_key
)
GROUP BY mh.mh_key, mh.mo_ta, f.ch_key;

-- ------------------------------------------------------------
-- 3-D (9 bảng)
-- ------------------------------------------------------------

-- [48] olap_tk_nam_mh_tinh
SELECT
    t.nam,
    mh.mh_key,
    mh.mo_ta,
    vp.bang,
    SUM(f.so_luong) AS tong_ton_kho
INTO OLAP_QuanLyBanHang.dbo.olap_tk_nam_mh_tinh
FROM DW_Core.dbo.Fact_Kho f
JOIN DW_Core.dbo.Dim_ThoiGian t  ON f.time_key = t.time_key
JOIN DW_Core.dbo.Dim_MatHang  mh ON f.mh_key   = mh.mh_key
JOIN DW_Core.dbo.Dim_CuaHang  ch ON f.ch_key   = ch.ch_key
JOIN DW_Core.dbo.Dim_VPDD     vp ON ch.vp_key  = vp.vp_key
WHERE f.time_key = (
    SELECT MAX(f2.time_key)
    FROM DW_Core.dbo.Fact_Kho f2
    WHERE f2.ch_key = f.ch_key
      AND f2.mh_key = f.mh_key
      AND f2.time_key / 100 = t.nam
)
GROUP BY t.nam, mh.mh_key, mh.mo_ta, vp.bang;

-- [49] olap_tk_quy_mh_tinh
SELECT
    t.nam,
    t.quy,
    mh.mh_key,
    mh.mo_ta,
    vp.bang,
    SUM(f.so_luong) AS tong_ton_kho
INTO OLAP_QuanLyBanHang.dbo.olap_tk_quy_mh_tinh
FROM DW_Core.dbo.Fact_Kho f
JOIN DW_Core.dbo.Dim_ThoiGian t  ON f.time_key = t.time_key
JOIN DW_Core.dbo.Dim_MatHang  mh ON f.mh_key   = mh.mh_key
JOIN DW_Core.dbo.Dim_CuaHang  ch ON f.ch_key   = ch.ch_key
JOIN DW_Core.dbo.Dim_VPDD     vp ON ch.vp_key  = vp.vp_key
WHERE f.time_key = (
    SELECT MAX(f2.time_key)
    FROM DW_Core.dbo.Fact_Kho f2
    JOIN DW_Core.dbo.Dim_ThoiGian t2 ON f2.time_key = t2.time_key
    WHERE f2.ch_key = f.ch_key
      AND f2.mh_key = f.mh_key
      AND t2.nam = t.nam
      AND t2.quy = t.quy
)
GROUP BY t.nam, t.quy, mh.mh_key, mh.mo_ta, vp.bang;

-- [50] olap_tk_thang_mh_tinh
SELECT
    t.nam,
    t.quy,
    t.thang,
    mh.mh_key,
    mh.mo_ta,
    vp.bang,
    SUM(f.so_luong) AS tong_ton_kho
INTO OLAP_QuanLyBanHang.dbo.olap_tk_thang_mh_tinh
FROM DW_Core.dbo.Fact_Kho f
JOIN DW_Core.dbo.Dim_ThoiGian t  ON f.time_key = t.time_key
JOIN DW_Core.dbo.Dim_MatHang  mh ON f.mh_key   = mh.mh_key
JOIN DW_Core.dbo.Dim_CuaHang  ch ON f.ch_key   = ch.ch_key
JOIN DW_Core.dbo.Dim_VPDD     vp ON ch.vp_key  = vp.vp_key
GROUP BY t.nam, t.quy, t.thang, mh.mh_key, mh.mo_ta, vp.bang;

-- [51] olap_tk_nam_mh_tp
SELECT
    t.nam,
    mh.mh_key,
    mh.mo_ta,
    vp.bang,
    vp.ten_tp,
    SUM(f.so_luong) AS tong_ton_kho
INTO OLAP_QuanLyBanHang.dbo.olap_tk_nam_mh_tp
FROM DW_Core.dbo.Fact_Kho f
JOIN DW_Core.dbo.Dim_ThoiGian t  ON f.time_key = t.time_key
JOIN DW_Core.dbo.Dim_MatHang  mh ON f.mh_key   = mh.mh_key
JOIN DW_Core.dbo.Dim_CuaHang  ch ON f.ch_key   = ch.ch_key
JOIN DW_Core.dbo.Dim_VPDD     vp ON ch.vp_key  = vp.vp_key
WHERE f.time_key = (
    SELECT MAX(f2.time_key)
    FROM DW_Core.dbo.Fact_Kho f2
    WHERE f2.ch_key = f.ch_key
      AND f2.mh_key = f.mh_key
      AND f2.time_key / 100 = t.nam
)
GROUP BY t.nam, mh.mh_key, mh.mo_ta, vp.bang, vp.ten_tp;

-- [52] olap_tk_quy_mh_tp
SELECT
    t.nam,
    t.quy,
    mh.mh_key,
    mh.mo_ta,
    vp.bang,
    vp.ten_tp,
    SUM(f.so_luong) AS tong_ton_kho
INTO OLAP_QuanLyBanHang.dbo.olap_tk_quy_mh_tp
FROM DW_Core.dbo.Fact_Kho f
JOIN DW_Core.dbo.Dim_ThoiGian t  ON f.time_key = t.time_key
JOIN DW_Core.dbo.Dim_MatHang  mh ON f.mh_key   = mh.mh_key
JOIN DW_Core.dbo.Dim_CuaHang  ch ON f.ch_key   = ch.ch_key
JOIN DW_Core.dbo.Dim_VPDD     vp ON ch.vp_key  = vp.vp_key
WHERE f.time_key = (
    SELECT MAX(f2.time_key)
    FROM DW_Core.dbo.Fact_Kho f2
    JOIN DW_Core.dbo.Dim_ThoiGian t2 ON f2.time_key = t2.time_key
    WHERE f2.ch_key = f.ch_key
      AND f2.mh_key = f.mh_key
      AND t2.nam = t.nam
      AND t2.quy = t.quy
)
GROUP BY t.nam, t.quy, mh.mh_key, mh.mo_ta, vp.bang, vp.ten_tp;

-- [53] olap_tk_thang_mh_tp
SELECT
    t.nam,
    t.quy,
    t.thang,
    mh.mh_key,
    mh.mo_ta,
    vp.bang,
    vp.ten_tp,
    SUM(f.so_luong) AS tong_ton_kho
INTO OLAP_QuanLyBanHang.dbo.olap_tk_thang_mh_tp
FROM DW_Core.dbo.Fact_Kho f
JOIN DW_Core.dbo.Dim_ThoiGian t  ON f.time_key = t.time_key
JOIN DW_Core.dbo.Dim_MatHang  mh ON f.mh_key   = mh.mh_key
JOIN DW_Core.dbo.Dim_CuaHang  ch ON f.ch_key   = ch.ch_key
JOIN DW_Core.dbo.Dim_VPDD     vp ON ch.vp_key  = vp.vp_key
GROUP BY t.nam, t.quy, t.thang, mh.mh_key, mh.mo_ta, vp.bang, vp.ten_tp;

-- [54] olap_tk_nam_mh_ch
SELECT
    t.nam,
    mh.mh_key,
    mh.mo_ta,
    f.ch_key,
    SUM(f.so_luong) AS tong_ton_kho
INTO OLAP_QuanLyBanHang.dbo.olap_tk_nam_mh_ch
FROM DW_Core.dbo.Fact_Kho f
JOIN DW_Core.dbo.Dim_ThoiGian t  ON f.time_key = t.time_key
JOIN DW_Core.dbo.Dim_MatHang  mh ON f.mh_key   = mh.mh_key
WHERE f.time_key = (
    SELECT MAX(f2.time_key)
    FROM DW_Core.dbo.Fact_Kho f2
    WHERE f2.ch_key = f.ch_key
      AND f2.mh_key = f.mh_key
      AND f2.time_key / 100 = t.nam
)
GROUP BY t.nam, mh.mh_key, mh.mo_ta, f.ch_key;

-- [55] olap_tk_quy_mh_ch
SELECT
    t.nam,
    t.quy,
    mh.mh_key,
    mh.mo_ta,
    f.ch_key,
    SUM(f.so_luong) AS tong_ton_kho
INTO OLAP_QuanLyBanHang.dbo.olap_tk_quy_mh_ch
FROM DW_Core.dbo.Fact_Kho f
JOIN DW_Core.dbo.Dim_ThoiGian t  ON f.time_key = t.time_key
JOIN DW_Core.dbo.Dim_MatHang  mh ON f.mh_key   = mh.mh_key
WHERE f.time_key = (
    SELECT MAX(f2.time_key)
    FROM DW_Core.dbo.Fact_Kho f2
    JOIN DW_Core.dbo.Dim_ThoiGian t2 ON f2.time_key = t2.time_key
    WHERE f2.ch_key = f.ch_key
      AND f2.mh_key = f.mh_key
      AND t2.nam = t.nam
      AND t2.quy = t.quy
)
GROUP BY t.nam, t.quy, mh.mh_key, mh.mo_ta, f.ch_key;

-- [56] olap_tk_thang_mh_ch
SELECT
    t.nam,
    t.quy,
    t.thang,
    mh.mh_key,
    mh.mo_ta,
    f.ch_key,
    SUM(f.so_luong) AS tong_ton_kho
INTO OLAP_QuanLyBanHang.dbo.olap_tk_thang_mh_ch
FROM DW_Core.dbo.Fact_Kho f
JOIN DW_Core.dbo.Dim_ThoiGian t  ON f.time_key = t.time_key
JOIN DW_Core.dbo.Dim_MatHang  mh ON f.mh_key   = mh.mh_key
GROUP BY t.nam, t.quy, t.thang, mh.mh_key, mh.mo_ta, f.ch_key;

-- ============================================================
-- VERIFY: Đếm và liệt kê tất cả bảng đã tạo
-- ============================================================
SELECT COUNT(*) AS tong_so_bang
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_TYPE = 'BASE TABLE';

SELECT TABLE_NAME
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_TYPE = 'BASE TABLE'
ORDER BY TABLE_NAME;
