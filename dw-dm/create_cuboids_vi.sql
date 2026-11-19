-- ============================================================
-- FILE SINH TU DONG boi scripts/gen_cuboids.py. KHONG SUA TAY.
-- Sales cube    : 120 cuboid (olap_ds_*), Thoi gian(5) x Mat hang(2) x Khach hang(3) x Vi tri(4)
-- Inventory cube: 32 cuboid (olap_tk_*), Thoi gian(4) x Mat hang(2) x Vi tri(4)
-- Measures: tong_so_luong, tong_doanh_thu (cong duoc); tong_ton_kho (snapshot cuoi ky)
-- ============================================================
USE OLAP_QuanLyBanHang;
GO
SET NOCOUNT ON;
GO

-- [1] olap_ds_all (0D)
SELECT SUM(f.so_luong) AS tong_so_luong,
       SUM(f.doanh_thu) AS tong_doanh_thu
INTO dbo.[olap_ds_all]
FROM DW_Core.dbo.Fact_BanHang f
OPTION (MAXDOP 1, MAX_GRANT_PERCENT = 0);
GO

-- [2] olap_ds_tinh (1D)
SELECT v.bang AS bang,
       SUM(f.so_luong) AS tong_so_luong,
       SUM(f.doanh_thu) AS tong_doanh_thu
INTO dbo.[olap_ds_tinh]
FROM DW_Core.dbo.Fact_BanHang f
JOIN DW_Core.dbo.Dim_CuaHang ch ON ch.ch_key = f.ch_key
JOIN DW_Core.dbo.Dim_VPDD v ON v.vp_key = ch.vp_key
GROUP BY v.bang
OPTION (MAXDOP 1, MAX_GRANT_PERCENT = 0);
GO

-- [3] olap_ds_tp (1D)
SELECT v.bang AS bang,
       v.ten_tp AS ten_tp,
       SUM(f.so_luong) AS tong_so_luong,
       SUM(f.doanh_thu) AS tong_doanh_thu
INTO dbo.[olap_ds_tp]
FROM DW_Core.dbo.Fact_BanHang f
JOIN DW_Core.dbo.Dim_CuaHang ch ON ch.ch_key = f.ch_key
JOIN DW_Core.dbo.Dim_VPDD v ON v.vp_key = ch.vp_key
GROUP BY v.bang, v.ten_tp
OPTION (MAXDOP 1, MAX_GRANT_PERCENT = 0);
GO

-- [4] olap_ds_ch (1D)
SELECT v.bang AS bang,
       v.ten_tp AS ten_tp,
       f.ch_key AS ch_key,
       SUM(f.so_luong) AS tong_so_luong,
       SUM(f.doanh_thu) AS tong_doanh_thu
INTO dbo.[olap_ds_ch]
FROM DW_Core.dbo.Fact_BanHang f
JOIN DW_Core.dbo.Dim_CuaHang ch ON ch.ch_key = f.ch_key
JOIN DW_Core.dbo.Dim_VPDD v ON v.vp_key = ch.vp_key
GROUP BY v.bang, v.ten_tp, f.ch_key
OPTION (MAXDOP 1, MAX_GRANT_PERCENT = 0);
GO

-- [5] olap_ds_loai_kh (1D)
SELECT kh.loai_kh AS loai_kh,
       SUM(f.so_luong) AS tong_so_luong,
       SUM(f.doanh_thu) AS tong_doanh_thu
INTO dbo.[olap_ds_loai_kh]
FROM DW_Core.dbo.Fact_BanHang f
JOIN DW_Core.dbo.Dim_KhachHang kh ON kh.kh_key = f.kh_key
GROUP BY kh.loai_kh
OPTION (MAXDOP 1, MAX_GRANT_PERCENT = 0);
GO

-- [6] olap_ds_loai_kh_tinh (2D)
SELECT kh.loai_kh AS loai_kh,
       v.bang AS bang,
       SUM(f.so_luong) AS tong_so_luong,
       SUM(f.doanh_thu) AS tong_doanh_thu
INTO dbo.[olap_ds_loai_kh_tinh]
FROM DW_Core.dbo.Fact_BanHang f
JOIN DW_Core.dbo.Dim_KhachHang kh ON kh.kh_key = f.kh_key
JOIN DW_Core.dbo.Dim_CuaHang ch ON ch.ch_key = f.ch_key
JOIN DW_Core.dbo.Dim_VPDD v ON v.vp_key = ch.vp_key
GROUP BY kh.loai_kh, v.bang
OPTION (MAXDOP 1, MAX_GRANT_PERCENT = 0);
GO

-- [7] olap_ds_loai_kh_tp (2D)
SELECT kh.loai_kh AS loai_kh,
       v.bang AS bang,
       v.ten_tp AS ten_tp,
       SUM(f.so_luong) AS tong_so_luong,
       SUM(f.doanh_thu) AS tong_doanh_thu
INTO dbo.[olap_ds_loai_kh_tp]
FROM DW_Core.dbo.Fact_BanHang f
JOIN DW_Core.dbo.Dim_KhachHang kh ON kh.kh_key = f.kh_key
JOIN DW_Core.dbo.Dim_CuaHang ch ON ch.ch_key = f.ch_key
JOIN DW_Core.dbo.Dim_VPDD v ON v.vp_key = ch.vp_key
GROUP BY kh.loai_kh, v.bang, v.ten_tp
OPTION (MAXDOP 1, MAX_GRANT_PERCENT = 0);
GO

-- [8] olap_ds_loai_kh_ch (2D)
SELECT kh.loai_kh AS loai_kh,
       v.bang AS bang,
       v.ten_tp AS ten_tp,
       f.ch_key AS ch_key,
       SUM(f.so_luong) AS tong_so_luong,
       SUM(f.doanh_thu) AS tong_doanh_thu
INTO dbo.[olap_ds_loai_kh_ch]
FROM DW_Core.dbo.Fact_BanHang f
JOIN DW_Core.dbo.Dim_KhachHang kh ON kh.kh_key = f.kh_key
JOIN DW_Core.dbo.Dim_CuaHang ch ON ch.ch_key = f.ch_key
JOIN DW_Core.dbo.Dim_VPDD v ON v.vp_key = ch.vp_key
GROUP BY kh.loai_kh, v.bang, v.ten_tp, f.ch_key
OPTION (MAXDOP 1, MAX_GRANT_PERCENT = 0);
GO

-- [9] olap_ds_kh (1D)
SELECT f.kh_key AS kh_key,
       kh.ten AS ten,
       kh.loai_kh AS loai_kh,
       SUM(f.so_luong) AS tong_so_luong,
       SUM(f.doanh_thu) AS tong_doanh_thu
INTO dbo.[olap_ds_kh]
FROM DW_Core.dbo.Fact_BanHang f
JOIN DW_Core.dbo.Dim_KhachHang kh ON kh.kh_key = f.kh_key
GROUP BY f.kh_key, kh.ten, kh.loai_kh
OPTION (MAXDOP 1, MAX_GRANT_PERCENT = 0);
GO

-- [10] olap_ds_kh_tinh (2D)
SELECT f.kh_key AS kh_key,
       kh.ten AS ten,
       kh.loai_kh AS loai_kh,
       v.bang AS bang,
       SUM(f.so_luong) AS tong_so_luong,
       SUM(f.doanh_thu) AS tong_doanh_thu
INTO dbo.[olap_ds_kh_tinh]
FROM DW_Core.dbo.Fact_BanHang f
JOIN DW_Core.dbo.Dim_KhachHang kh ON kh.kh_key = f.kh_key
JOIN DW_Core.dbo.Dim_CuaHang ch ON ch.ch_key = f.ch_key
JOIN DW_Core.dbo.Dim_VPDD v ON v.vp_key = ch.vp_key
GROUP BY f.kh_key, kh.ten, kh.loai_kh, v.bang
OPTION (MAXDOP 1, MAX_GRANT_PERCENT = 0);
GO

-- [11] olap_ds_kh_tp (2D)
SELECT f.kh_key AS kh_key,
       kh.ten AS ten,
       kh.loai_kh AS loai_kh,
       v.bang AS bang,
       v.ten_tp AS ten_tp,
       SUM(f.so_luong) AS tong_so_luong,
       SUM(f.doanh_thu) AS tong_doanh_thu
INTO dbo.[olap_ds_kh_tp]
FROM DW_Core.dbo.Fact_BanHang f
JOIN DW_Core.dbo.Dim_KhachHang kh ON kh.kh_key = f.kh_key
JOIN DW_Core.dbo.Dim_CuaHang ch ON ch.ch_key = f.ch_key
JOIN DW_Core.dbo.Dim_VPDD v ON v.vp_key = ch.vp_key
GROUP BY f.kh_key, kh.ten, kh.loai_kh, v.bang, v.ten_tp
OPTION (MAXDOP 1, MAX_GRANT_PERCENT = 0);
GO

-- [12] olap_ds_kh_ch (2D)
SELECT f.kh_key AS kh_key,
       kh.ten AS ten,
       kh.loai_kh AS loai_kh,
       v.bang AS bang,
       v.ten_tp AS ten_tp,
       f.ch_key AS ch_key,
       SUM(f.so_luong) AS tong_so_luong,
       SUM(f.doanh_thu) AS tong_doanh_thu
INTO dbo.[olap_ds_kh_ch]
FROM DW_Core.dbo.Fact_BanHang f
JOIN DW_Core.dbo.Dim_KhachHang kh ON kh.kh_key = f.kh_key
JOIN DW_Core.dbo.Dim_CuaHang ch ON ch.ch_key = f.ch_key
JOIN DW_Core.dbo.Dim_VPDD v ON v.vp_key = ch.vp_key
GROUP BY f.kh_key, kh.ten, kh.loai_kh, v.bang, v.ten_tp, f.ch_key
OPTION (MAXDOP 1, MAX_GRANT_PERCENT = 0);
GO

-- [13] olap_ds_mh (1D)
SELECT f.mh_key AS mh_key,
       mh.mo_ta AS mo_ta,
       SUM(f.so_luong) AS tong_so_luong,
       SUM(f.doanh_thu) AS tong_doanh_thu
INTO dbo.[olap_ds_mh]
FROM DW_Core.dbo.Fact_BanHang f
JOIN DW_Core.dbo.Dim_MatHang mh ON mh.mh_key = f.mh_key
GROUP BY f.mh_key, mh.mo_ta
OPTION (MAXDOP 1, MAX_GRANT_PERCENT = 0);
GO

-- [14] olap_ds_mh_tinh (2D)
SELECT f.mh_key AS mh_key,
       mh.mo_ta AS mo_ta,
       v.bang AS bang,
       SUM(f.so_luong) AS tong_so_luong,
       SUM(f.doanh_thu) AS tong_doanh_thu
INTO dbo.[olap_ds_mh_tinh]
FROM DW_Core.dbo.Fact_BanHang f
JOIN DW_Core.dbo.Dim_MatHang mh ON mh.mh_key = f.mh_key
JOIN DW_Core.dbo.Dim_CuaHang ch ON ch.ch_key = f.ch_key
JOIN DW_Core.dbo.Dim_VPDD v ON v.vp_key = ch.vp_key
GROUP BY f.mh_key, mh.mo_ta, v.bang
OPTION (MAXDOP 1, MAX_GRANT_PERCENT = 0);
GO

-- [15] olap_ds_mh_tp (2D)
SELECT f.mh_key AS mh_key,
       mh.mo_ta AS mo_ta,
       v.bang AS bang,
       v.ten_tp AS ten_tp,
       SUM(f.so_luong) AS tong_so_luong,
       SUM(f.doanh_thu) AS tong_doanh_thu
INTO dbo.[olap_ds_mh_tp]
FROM DW_Core.dbo.Fact_BanHang f
JOIN DW_Core.dbo.Dim_MatHang mh ON mh.mh_key = f.mh_key
JOIN DW_Core.dbo.Dim_CuaHang ch ON ch.ch_key = f.ch_key
JOIN DW_Core.dbo.Dim_VPDD v ON v.vp_key = ch.vp_key
GROUP BY f.mh_key, mh.mo_ta, v.bang, v.ten_tp
OPTION (MAXDOP 1, MAX_GRANT_PERCENT = 0);
GO

-- [16] olap_ds_mh_ch (2D)
SELECT f.mh_key AS mh_key,
       mh.mo_ta AS mo_ta,
       v.bang AS bang,
       v.ten_tp AS ten_tp,
       f.ch_key AS ch_key,
       SUM(f.so_luong) AS tong_so_luong,
       SUM(f.doanh_thu) AS tong_doanh_thu
INTO dbo.[olap_ds_mh_ch]
FROM DW_Core.dbo.Fact_BanHang f
JOIN DW_Core.dbo.Dim_MatHang mh ON mh.mh_key = f.mh_key
JOIN DW_Core.dbo.Dim_CuaHang ch ON ch.ch_key = f.ch_key
JOIN DW_Core.dbo.Dim_VPDD v ON v.vp_key = ch.vp_key
GROUP BY f.mh_key, mh.mo_ta, v.bang, v.ten_tp, f.ch_key
OPTION (MAXDOP 1, MAX_GRANT_PERCENT = 0);
GO

-- [17] olap_ds_mh_loai_kh (2D)
SELECT f.mh_key AS mh_key,
       mh.mo_ta AS mo_ta,
       kh.loai_kh AS loai_kh,
       SUM(f.so_luong) AS tong_so_luong,
       SUM(f.doanh_thu) AS tong_doanh_thu
INTO dbo.[olap_ds_mh_loai_kh]
FROM DW_Core.dbo.Fact_BanHang f
JOIN DW_Core.dbo.Dim_KhachHang kh ON kh.kh_key = f.kh_key
JOIN DW_Core.dbo.Dim_MatHang mh ON mh.mh_key = f.mh_key
GROUP BY f.mh_key, mh.mo_ta, kh.loai_kh
OPTION (MAXDOP 1, MAX_GRANT_PERCENT = 0);
GO

-- [18] olap_ds_mh_loai_kh_tinh (3D)
SELECT f.mh_key AS mh_key,
       mh.mo_ta AS mo_ta,
       kh.loai_kh AS loai_kh,
       v.bang AS bang,
       SUM(f.so_luong) AS tong_so_luong,
       SUM(f.doanh_thu) AS tong_doanh_thu
INTO dbo.[olap_ds_mh_loai_kh_tinh]
FROM DW_Core.dbo.Fact_BanHang f
JOIN DW_Core.dbo.Dim_KhachHang kh ON kh.kh_key = f.kh_key
JOIN DW_Core.dbo.Dim_MatHang mh ON mh.mh_key = f.mh_key
JOIN DW_Core.dbo.Dim_CuaHang ch ON ch.ch_key = f.ch_key
JOIN DW_Core.dbo.Dim_VPDD v ON v.vp_key = ch.vp_key
GROUP BY f.mh_key, mh.mo_ta, kh.loai_kh, v.bang
OPTION (MAXDOP 1, MAX_GRANT_PERCENT = 0);
GO

-- [19] olap_ds_mh_loai_kh_tp (3D)
SELECT f.mh_key AS mh_key,
       mh.mo_ta AS mo_ta,
       kh.loai_kh AS loai_kh,
       v.bang AS bang,
       v.ten_tp AS ten_tp,
       SUM(f.so_luong) AS tong_so_luong,
       SUM(f.doanh_thu) AS tong_doanh_thu
INTO dbo.[olap_ds_mh_loai_kh_tp]
FROM DW_Core.dbo.Fact_BanHang f
JOIN DW_Core.dbo.Dim_KhachHang kh ON kh.kh_key = f.kh_key
JOIN DW_Core.dbo.Dim_MatHang mh ON mh.mh_key = f.mh_key
JOIN DW_Core.dbo.Dim_CuaHang ch ON ch.ch_key = f.ch_key
JOIN DW_Core.dbo.Dim_VPDD v ON v.vp_key = ch.vp_key
GROUP BY f.mh_key, mh.mo_ta, kh.loai_kh, v.bang, v.ten_tp
OPTION (MAXDOP 1, MAX_GRANT_PERCENT = 0);
GO

-- [20] olap_ds_mh_loai_kh_ch (3D)
SELECT f.mh_key AS mh_key,
       mh.mo_ta AS mo_ta,
       kh.loai_kh AS loai_kh,
       v.bang AS bang,
       v.ten_tp AS ten_tp,
       f.ch_key AS ch_key,
       SUM(f.so_luong) AS tong_so_luong,
       SUM(f.doanh_thu) AS tong_doanh_thu
INTO dbo.[olap_ds_mh_loai_kh_ch]
FROM DW_Core.dbo.Fact_BanHang f
JOIN DW_Core.dbo.Dim_KhachHang kh ON kh.kh_key = f.kh_key
JOIN DW_Core.dbo.Dim_MatHang mh ON mh.mh_key = f.mh_key
JOIN DW_Core.dbo.Dim_CuaHang ch ON ch.ch_key = f.ch_key
JOIN DW_Core.dbo.Dim_VPDD v ON v.vp_key = ch.vp_key
GROUP BY f.mh_key, mh.mo_ta, kh.loai_kh, v.bang, v.ten_tp, f.ch_key
OPTION (MAXDOP 1, MAX_GRANT_PERCENT = 0);
GO

-- [21] olap_ds_mh_kh (2D)
SELECT f.mh_key AS mh_key,
       mh.mo_ta AS mo_ta,
       f.kh_key AS kh_key,
       kh.ten AS ten,
       kh.loai_kh AS loai_kh,
       SUM(f.so_luong) AS tong_so_luong,
       SUM(f.doanh_thu) AS tong_doanh_thu
INTO dbo.[olap_ds_mh_kh]
FROM DW_Core.dbo.Fact_BanHang f
JOIN DW_Core.dbo.Dim_KhachHang kh ON kh.kh_key = f.kh_key
JOIN DW_Core.dbo.Dim_MatHang mh ON mh.mh_key = f.mh_key
GROUP BY f.mh_key, mh.mo_ta, f.kh_key, kh.ten, kh.loai_kh
OPTION (MAXDOP 1, MAX_GRANT_PERCENT = 0);
GO

-- [22] olap_ds_mh_kh_tinh (3D)
SELECT f.mh_key AS mh_key,
       mh.mo_ta AS mo_ta,
       f.kh_key AS kh_key,
       kh.ten AS ten,
       kh.loai_kh AS loai_kh,
       v.bang AS bang,
       SUM(f.so_luong) AS tong_so_luong,
       SUM(f.doanh_thu) AS tong_doanh_thu
INTO dbo.[olap_ds_mh_kh_tinh]
FROM DW_Core.dbo.Fact_BanHang f
JOIN DW_Core.dbo.Dim_KhachHang kh ON kh.kh_key = f.kh_key
JOIN DW_Core.dbo.Dim_MatHang mh ON mh.mh_key = f.mh_key
JOIN DW_Core.dbo.Dim_CuaHang ch ON ch.ch_key = f.ch_key
JOIN DW_Core.dbo.Dim_VPDD v ON v.vp_key = ch.vp_key
GROUP BY f.mh_key, mh.mo_ta, f.kh_key, kh.ten, kh.loai_kh, v.bang
OPTION (MAXDOP 1, MAX_GRANT_PERCENT = 0);
GO

-- [23] olap_ds_mh_kh_tp (3D)
SELECT f.mh_key AS mh_key,
       mh.mo_ta AS mo_ta,
       f.kh_key AS kh_key,
       kh.ten AS ten,
       kh.loai_kh AS loai_kh,
       v.bang AS bang,
       v.ten_tp AS ten_tp,
       SUM(f.so_luong) AS tong_so_luong,
       SUM(f.doanh_thu) AS tong_doanh_thu
INTO dbo.[olap_ds_mh_kh_tp]
FROM DW_Core.dbo.Fact_BanHang f
JOIN DW_Core.dbo.Dim_KhachHang kh ON kh.kh_key = f.kh_key
JOIN DW_Core.dbo.Dim_MatHang mh ON mh.mh_key = f.mh_key
JOIN DW_Core.dbo.Dim_CuaHang ch ON ch.ch_key = f.ch_key
JOIN DW_Core.dbo.Dim_VPDD v ON v.vp_key = ch.vp_key
GROUP BY f.mh_key, mh.mo_ta, f.kh_key, kh.ten, kh.loai_kh, v.bang, v.ten_tp
OPTION (MAXDOP 1, MAX_GRANT_PERCENT = 0);
GO

-- [24] olap_ds_mh_kh_ch (3D)
SELECT f.mh_key AS mh_key,
       mh.mo_ta AS mo_ta,
       f.kh_key AS kh_key,
       kh.ten AS ten,
       kh.loai_kh AS loai_kh,
       v.bang AS bang,
       v.ten_tp AS ten_tp,
       f.ch_key AS ch_key,
       SUM(f.so_luong) AS tong_so_luong,
       SUM(f.doanh_thu) AS tong_doanh_thu
INTO dbo.[olap_ds_mh_kh_ch]
FROM DW_Core.dbo.Fact_BanHang f
JOIN DW_Core.dbo.Dim_KhachHang kh ON kh.kh_key = f.kh_key
JOIN DW_Core.dbo.Dim_MatHang mh ON mh.mh_key = f.mh_key
JOIN DW_Core.dbo.Dim_CuaHang ch ON ch.ch_key = f.ch_key
JOIN DW_Core.dbo.Dim_VPDD v ON v.vp_key = ch.vp_key
GROUP BY f.mh_key, mh.mo_ta, f.kh_key, kh.ten, kh.loai_kh, v.bang, v.ten_tp, f.ch_key
OPTION (MAXDOP 1, MAX_GRANT_PERCENT = 0);
GO

-- [25] olap_ds_nam (1D)
SELECT t.nam AS nam,
       SUM(f.so_luong) AS tong_so_luong,
       SUM(f.doanh_thu) AS tong_doanh_thu
INTO dbo.[olap_ds_nam]
FROM DW_Core.dbo.Fact_BanHang f
JOIN DW_Core.dbo.Dim_Ngay n ON n.ngay_key = f.ngay_key
JOIN DW_Core.dbo.Dim_ThoiGian t ON t.time_key = n.time_key
GROUP BY t.nam
OPTION (MAXDOP 1, MAX_GRANT_PERCENT = 0);
GO

-- [26] olap_ds_nam_tinh (2D)
SELECT t.nam AS nam,
       v.bang AS bang,
       SUM(f.so_luong) AS tong_so_luong,
       SUM(f.doanh_thu) AS tong_doanh_thu
INTO dbo.[olap_ds_nam_tinh]
FROM DW_Core.dbo.Fact_BanHang f
JOIN DW_Core.dbo.Dim_Ngay n ON n.ngay_key = f.ngay_key
JOIN DW_Core.dbo.Dim_ThoiGian t ON t.time_key = n.time_key
JOIN DW_Core.dbo.Dim_CuaHang ch ON ch.ch_key = f.ch_key
JOIN DW_Core.dbo.Dim_VPDD v ON v.vp_key = ch.vp_key
GROUP BY t.nam, v.bang
OPTION (MAXDOP 1, MAX_GRANT_PERCENT = 0);
GO

-- [27] olap_ds_nam_tp (2D)
SELECT t.nam AS nam,
       v.bang AS bang,
       v.ten_tp AS ten_tp,
       SUM(f.so_luong) AS tong_so_luong,
       SUM(f.doanh_thu) AS tong_doanh_thu
INTO dbo.[olap_ds_nam_tp]
FROM DW_Core.dbo.Fact_BanHang f
JOIN DW_Core.dbo.Dim_Ngay n ON n.ngay_key = f.ngay_key
JOIN DW_Core.dbo.Dim_ThoiGian t ON t.time_key = n.time_key
JOIN DW_Core.dbo.Dim_CuaHang ch ON ch.ch_key = f.ch_key
JOIN DW_Core.dbo.Dim_VPDD v ON v.vp_key = ch.vp_key
GROUP BY t.nam, v.bang, v.ten_tp
OPTION (MAXDOP 1, MAX_GRANT_PERCENT = 0);
GO

-- [28] olap_ds_nam_ch (2D)
SELECT t.nam AS nam,
       v.bang AS bang,
       v.ten_tp AS ten_tp,
       f.ch_key AS ch_key,
       SUM(f.so_luong) AS tong_so_luong,
       SUM(f.doanh_thu) AS tong_doanh_thu
INTO dbo.[olap_ds_nam_ch]
FROM DW_Core.dbo.Fact_BanHang f
JOIN DW_Core.dbo.Dim_Ngay n ON n.ngay_key = f.ngay_key
JOIN DW_Core.dbo.Dim_ThoiGian t ON t.time_key = n.time_key
JOIN DW_Core.dbo.Dim_CuaHang ch ON ch.ch_key = f.ch_key
JOIN DW_Core.dbo.Dim_VPDD v ON v.vp_key = ch.vp_key
GROUP BY t.nam, v.bang, v.ten_tp, f.ch_key
OPTION (MAXDOP 1, MAX_GRANT_PERCENT = 0);
GO

-- [29] olap_ds_nam_loai_kh (2D)
SELECT t.nam AS nam,
       kh.loai_kh AS loai_kh,
       SUM(f.so_luong) AS tong_so_luong,
       SUM(f.doanh_thu) AS tong_doanh_thu
INTO dbo.[olap_ds_nam_loai_kh]
FROM DW_Core.dbo.Fact_BanHang f
JOIN DW_Core.dbo.Dim_Ngay n ON n.ngay_key = f.ngay_key
JOIN DW_Core.dbo.Dim_ThoiGian t ON t.time_key = n.time_key
JOIN DW_Core.dbo.Dim_KhachHang kh ON kh.kh_key = f.kh_key
GROUP BY t.nam, kh.loai_kh
OPTION (MAXDOP 1, MAX_GRANT_PERCENT = 0);
GO

-- [30] olap_ds_nam_loai_kh_tinh (3D)
SELECT t.nam AS nam,
       kh.loai_kh AS loai_kh,
       v.bang AS bang,
       SUM(f.so_luong) AS tong_so_luong,
       SUM(f.doanh_thu) AS tong_doanh_thu
INTO dbo.[olap_ds_nam_loai_kh_tinh]
FROM DW_Core.dbo.Fact_BanHang f
JOIN DW_Core.dbo.Dim_Ngay n ON n.ngay_key = f.ngay_key
JOIN DW_Core.dbo.Dim_ThoiGian t ON t.time_key = n.time_key
JOIN DW_Core.dbo.Dim_KhachHang kh ON kh.kh_key = f.kh_key
JOIN DW_Core.dbo.Dim_CuaHang ch ON ch.ch_key = f.ch_key
JOIN DW_Core.dbo.Dim_VPDD v ON v.vp_key = ch.vp_key
GROUP BY t.nam, kh.loai_kh, v.bang
OPTION (MAXDOP 1, MAX_GRANT_PERCENT = 0);
GO

-- [31] olap_ds_nam_loai_kh_tp (3D)
SELECT t.nam AS nam,
       kh.loai_kh AS loai_kh,
       v.bang AS bang,
       v.ten_tp AS ten_tp,
       SUM(f.so_luong) AS tong_so_luong,
       SUM(f.doanh_thu) AS tong_doanh_thu
INTO dbo.[olap_ds_nam_loai_kh_tp]
FROM DW_Core.dbo.Fact_BanHang f
JOIN DW_Core.dbo.Dim_Ngay n ON n.ngay_key = f.ngay_key
JOIN DW_Core.dbo.Dim_ThoiGian t ON t.time_key = n.time_key
JOIN DW_Core.dbo.Dim_KhachHang kh ON kh.kh_key = f.kh_key
JOIN DW_Core.dbo.Dim_CuaHang ch ON ch.ch_key = f.ch_key
JOIN DW_Core.dbo.Dim_VPDD v ON v.vp_key = ch.vp_key
GROUP BY t.nam, kh.loai_kh, v.bang, v.ten_tp
OPTION (MAXDOP 1, MAX_GRANT_PERCENT = 0);
GO

-- [32] olap_ds_nam_loai_kh_ch (3D)
SELECT t.nam AS nam,
       kh.loai_kh AS loai_kh,
       v.bang AS bang,
       v.ten_tp AS ten_tp,
       f.ch_key AS ch_key,
       SUM(f.so_luong) AS tong_so_luong,
       SUM(f.doanh_thu) AS tong_doanh_thu
INTO dbo.[olap_ds_nam_loai_kh_ch]
FROM DW_Core.dbo.Fact_BanHang f
JOIN DW_Core.dbo.Dim_Ngay n ON n.ngay_key = f.ngay_key
JOIN DW_Core.dbo.Dim_ThoiGian t ON t.time_key = n.time_key
JOIN DW_Core.dbo.Dim_KhachHang kh ON kh.kh_key = f.kh_key
JOIN DW_Core.dbo.Dim_CuaHang ch ON ch.ch_key = f.ch_key
JOIN DW_Core.dbo.Dim_VPDD v ON v.vp_key = ch.vp_key
GROUP BY t.nam, kh.loai_kh, v.bang, v.ten_tp, f.ch_key
OPTION (MAXDOP 1, MAX_GRANT_PERCENT = 0);
GO

-- [33] olap_ds_nam_kh (2D)
SELECT t.nam AS nam,
       f.kh_key AS kh_key,
       kh.ten AS ten,
       kh.loai_kh AS loai_kh,
       SUM(f.so_luong) AS tong_so_luong,
       SUM(f.doanh_thu) AS tong_doanh_thu
INTO dbo.[olap_ds_nam_kh]
FROM DW_Core.dbo.Fact_BanHang f
JOIN DW_Core.dbo.Dim_Ngay n ON n.ngay_key = f.ngay_key
JOIN DW_Core.dbo.Dim_ThoiGian t ON t.time_key = n.time_key
JOIN DW_Core.dbo.Dim_KhachHang kh ON kh.kh_key = f.kh_key
GROUP BY t.nam, f.kh_key, kh.ten, kh.loai_kh
OPTION (MAXDOP 1, MAX_GRANT_PERCENT = 0);
GO

-- [34] olap_ds_nam_kh_tinh (3D)
SELECT t.nam AS nam,
       f.kh_key AS kh_key,
       kh.ten AS ten,
       kh.loai_kh AS loai_kh,
       v.bang AS bang,
       SUM(f.so_luong) AS tong_so_luong,
       SUM(f.doanh_thu) AS tong_doanh_thu
INTO dbo.[olap_ds_nam_kh_tinh]
FROM DW_Core.dbo.Fact_BanHang f
JOIN DW_Core.dbo.Dim_Ngay n ON n.ngay_key = f.ngay_key
JOIN DW_Core.dbo.Dim_ThoiGian t ON t.time_key = n.time_key
JOIN DW_Core.dbo.Dim_KhachHang kh ON kh.kh_key = f.kh_key
JOIN DW_Core.dbo.Dim_CuaHang ch ON ch.ch_key = f.ch_key
JOIN DW_Core.dbo.Dim_VPDD v ON v.vp_key = ch.vp_key
GROUP BY t.nam, f.kh_key, kh.ten, kh.loai_kh, v.bang
OPTION (MAXDOP 1, MAX_GRANT_PERCENT = 0);
GO

-- [35] olap_ds_nam_kh_tp (3D)
SELECT t.nam AS nam,
       f.kh_key AS kh_key,
       kh.ten AS ten,
       kh.loai_kh AS loai_kh,
       v.bang AS bang,
       v.ten_tp AS ten_tp,
       SUM(f.so_luong) AS tong_so_luong,
       SUM(f.doanh_thu) AS tong_doanh_thu
INTO dbo.[olap_ds_nam_kh_tp]
FROM DW_Core.dbo.Fact_BanHang f
JOIN DW_Core.dbo.Dim_Ngay n ON n.ngay_key = f.ngay_key
JOIN DW_Core.dbo.Dim_ThoiGian t ON t.time_key = n.time_key
JOIN DW_Core.dbo.Dim_KhachHang kh ON kh.kh_key = f.kh_key
JOIN DW_Core.dbo.Dim_CuaHang ch ON ch.ch_key = f.ch_key
JOIN DW_Core.dbo.Dim_VPDD v ON v.vp_key = ch.vp_key
GROUP BY t.nam, f.kh_key, kh.ten, kh.loai_kh, v.bang, v.ten_tp
OPTION (MAXDOP 1, MAX_GRANT_PERCENT = 0);
GO

-- [36] olap_ds_nam_kh_ch (3D)
SELECT t.nam AS nam,
       f.kh_key AS kh_key,
       kh.ten AS ten,
       kh.loai_kh AS loai_kh,
       v.bang AS bang,
       v.ten_tp AS ten_tp,
       f.ch_key AS ch_key,
       SUM(f.so_luong) AS tong_so_luong,
       SUM(f.doanh_thu) AS tong_doanh_thu
INTO dbo.[olap_ds_nam_kh_ch]
FROM DW_Core.dbo.Fact_BanHang f
JOIN DW_Core.dbo.Dim_Ngay n ON n.ngay_key = f.ngay_key
JOIN DW_Core.dbo.Dim_ThoiGian t ON t.time_key = n.time_key
JOIN DW_Core.dbo.Dim_KhachHang kh ON kh.kh_key = f.kh_key
JOIN DW_Core.dbo.Dim_CuaHang ch ON ch.ch_key = f.ch_key
JOIN DW_Core.dbo.Dim_VPDD v ON v.vp_key = ch.vp_key
GROUP BY t.nam, f.kh_key, kh.ten, kh.loai_kh, v.bang, v.ten_tp, f.ch_key
OPTION (MAXDOP 1, MAX_GRANT_PERCENT = 0);
GO

-- [37] olap_ds_nam_mh (2D)
SELECT t.nam AS nam,
       f.mh_key AS mh_key,
       mh.mo_ta AS mo_ta,
       SUM(f.so_luong) AS tong_so_luong,
       SUM(f.doanh_thu) AS tong_doanh_thu
INTO dbo.[olap_ds_nam_mh]
FROM DW_Core.dbo.Fact_BanHang f
JOIN DW_Core.dbo.Dim_Ngay n ON n.ngay_key = f.ngay_key
JOIN DW_Core.dbo.Dim_ThoiGian t ON t.time_key = n.time_key
JOIN DW_Core.dbo.Dim_MatHang mh ON mh.mh_key = f.mh_key
GROUP BY t.nam, f.mh_key, mh.mo_ta
OPTION (MAXDOP 1, MAX_GRANT_PERCENT = 0);
GO

-- [38] olap_ds_nam_mh_tinh (3D)
SELECT t.nam AS nam,
       f.mh_key AS mh_key,
       mh.mo_ta AS mo_ta,
       v.bang AS bang,
       SUM(f.so_luong) AS tong_so_luong,
       SUM(f.doanh_thu) AS tong_doanh_thu
INTO dbo.[olap_ds_nam_mh_tinh]
FROM DW_Core.dbo.Fact_BanHang f
JOIN DW_Core.dbo.Dim_Ngay n ON n.ngay_key = f.ngay_key
JOIN DW_Core.dbo.Dim_ThoiGian t ON t.time_key = n.time_key
JOIN DW_Core.dbo.Dim_MatHang mh ON mh.mh_key = f.mh_key
JOIN DW_Core.dbo.Dim_CuaHang ch ON ch.ch_key = f.ch_key
JOIN DW_Core.dbo.Dim_VPDD v ON v.vp_key = ch.vp_key
GROUP BY t.nam, f.mh_key, mh.mo_ta, v.bang
OPTION (MAXDOP 1, MAX_GRANT_PERCENT = 0);
GO

-- [39] olap_ds_nam_mh_tp (3D)
SELECT t.nam AS nam,
       f.mh_key AS mh_key,
       mh.mo_ta AS mo_ta,
       v.bang AS bang,
       v.ten_tp AS ten_tp,
       SUM(f.so_luong) AS tong_so_luong,
       SUM(f.doanh_thu) AS tong_doanh_thu
INTO dbo.[olap_ds_nam_mh_tp]
FROM DW_Core.dbo.Fact_BanHang f
JOIN DW_Core.dbo.Dim_Ngay n ON n.ngay_key = f.ngay_key
JOIN DW_Core.dbo.Dim_ThoiGian t ON t.time_key = n.time_key
JOIN DW_Core.dbo.Dim_MatHang mh ON mh.mh_key = f.mh_key
JOIN DW_Core.dbo.Dim_CuaHang ch ON ch.ch_key = f.ch_key
JOIN DW_Core.dbo.Dim_VPDD v ON v.vp_key = ch.vp_key
GROUP BY t.nam, f.mh_key, mh.mo_ta, v.bang, v.ten_tp
OPTION (MAXDOP 1, MAX_GRANT_PERCENT = 0);
GO

-- [40] olap_ds_nam_mh_ch (3D)
SELECT t.nam AS nam,
       f.mh_key AS mh_key,
       mh.mo_ta AS mo_ta,
       v.bang AS bang,
       v.ten_tp AS ten_tp,
       f.ch_key AS ch_key,
       SUM(f.so_luong) AS tong_so_luong,
       SUM(f.doanh_thu) AS tong_doanh_thu
INTO dbo.[olap_ds_nam_mh_ch]
FROM DW_Core.dbo.Fact_BanHang f
JOIN DW_Core.dbo.Dim_Ngay n ON n.ngay_key = f.ngay_key
JOIN DW_Core.dbo.Dim_ThoiGian t ON t.time_key = n.time_key
JOIN DW_Core.dbo.Dim_MatHang mh ON mh.mh_key = f.mh_key
JOIN DW_Core.dbo.Dim_CuaHang ch ON ch.ch_key = f.ch_key
JOIN DW_Core.dbo.Dim_VPDD v ON v.vp_key = ch.vp_key
GROUP BY t.nam, f.mh_key, mh.mo_ta, v.bang, v.ten_tp, f.ch_key
OPTION (MAXDOP 1, MAX_GRANT_PERCENT = 0);
GO

-- [41] olap_ds_nam_mh_loai_kh (3D)
SELECT t.nam AS nam,
       f.mh_key AS mh_key,
       mh.mo_ta AS mo_ta,
       kh.loai_kh AS loai_kh,
       SUM(f.so_luong) AS tong_so_luong,
       SUM(f.doanh_thu) AS tong_doanh_thu
INTO dbo.[olap_ds_nam_mh_loai_kh]
FROM DW_Core.dbo.Fact_BanHang f
JOIN DW_Core.dbo.Dim_Ngay n ON n.ngay_key = f.ngay_key
JOIN DW_Core.dbo.Dim_ThoiGian t ON t.time_key = n.time_key
JOIN DW_Core.dbo.Dim_KhachHang kh ON kh.kh_key = f.kh_key
JOIN DW_Core.dbo.Dim_MatHang mh ON mh.mh_key = f.mh_key
GROUP BY t.nam, f.mh_key, mh.mo_ta, kh.loai_kh
OPTION (MAXDOP 1, MAX_GRANT_PERCENT = 0);
GO

-- [42] olap_ds_nam_mh_loai_kh_tinh (4D)
SELECT t.nam AS nam,
       f.mh_key AS mh_key,
       mh.mo_ta AS mo_ta,
       kh.loai_kh AS loai_kh,
       v.bang AS bang,
       SUM(f.so_luong) AS tong_so_luong,
       SUM(f.doanh_thu) AS tong_doanh_thu
INTO dbo.[olap_ds_nam_mh_loai_kh_tinh]
FROM DW_Core.dbo.Fact_BanHang f
JOIN DW_Core.dbo.Dim_Ngay n ON n.ngay_key = f.ngay_key
JOIN DW_Core.dbo.Dim_ThoiGian t ON t.time_key = n.time_key
JOIN DW_Core.dbo.Dim_KhachHang kh ON kh.kh_key = f.kh_key
JOIN DW_Core.dbo.Dim_MatHang mh ON mh.mh_key = f.mh_key
JOIN DW_Core.dbo.Dim_CuaHang ch ON ch.ch_key = f.ch_key
JOIN DW_Core.dbo.Dim_VPDD v ON v.vp_key = ch.vp_key
GROUP BY t.nam, f.mh_key, mh.mo_ta, kh.loai_kh, v.bang
OPTION (MAXDOP 1, MAX_GRANT_PERCENT = 0);
GO

-- [43] olap_ds_nam_mh_loai_kh_tp (4D)
SELECT t.nam AS nam,
       f.mh_key AS mh_key,
       mh.mo_ta AS mo_ta,
       kh.loai_kh AS loai_kh,
       v.bang AS bang,
       v.ten_tp AS ten_tp,
       SUM(f.so_luong) AS tong_so_luong,
       SUM(f.doanh_thu) AS tong_doanh_thu
INTO dbo.[olap_ds_nam_mh_loai_kh_tp]
FROM DW_Core.dbo.Fact_BanHang f
JOIN DW_Core.dbo.Dim_Ngay n ON n.ngay_key = f.ngay_key
JOIN DW_Core.dbo.Dim_ThoiGian t ON t.time_key = n.time_key
JOIN DW_Core.dbo.Dim_KhachHang kh ON kh.kh_key = f.kh_key
JOIN DW_Core.dbo.Dim_MatHang mh ON mh.mh_key = f.mh_key
JOIN DW_Core.dbo.Dim_CuaHang ch ON ch.ch_key = f.ch_key
JOIN DW_Core.dbo.Dim_VPDD v ON v.vp_key = ch.vp_key
GROUP BY t.nam, f.mh_key, mh.mo_ta, kh.loai_kh, v.bang, v.ten_tp
OPTION (MAXDOP 1, MAX_GRANT_PERCENT = 0);
GO

-- [44] olap_ds_nam_mh_loai_kh_ch (4D)
SELECT t.nam AS nam,
       f.mh_key AS mh_key,
       mh.mo_ta AS mo_ta,
       kh.loai_kh AS loai_kh,
       v.bang AS bang,
       v.ten_tp AS ten_tp,
       f.ch_key AS ch_key,
       SUM(f.so_luong) AS tong_so_luong,
       SUM(f.doanh_thu) AS tong_doanh_thu
INTO dbo.[olap_ds_nam_mh_loai_kh_ch]
FROM DW_Core.dbo.Fact_BanHang f
JOIN DW_Core.dbo.Dim_Ngay n ON n.ngay_key = f.ngay_key
JOIN DW_Core.dbo.Dim_ThoiGian t ON t.time_key = n.time_key
JOIN DW_Core.dbo.Dim_KhachHang kh ON kh.kh_key = f.kh_key
JOIN DW_Core.dbo.Dim_MatHang mh ON mh.mh_key = f.mh_key
JOIN DW_Core.dbo.Dim_CuaHang ch ON ch.ch_key = f.ch_key
JOIN DW_Core.dbo.Dim_VPDD v ON v.vp_key = ch.vp_key
GROUP BY t.nam, f.mh_key, mh.mo_ta, kh.loai_kh, v.bang, v.ten_tp, f.ch_key
OPTION (MAXDOP 1, MAX_GRANT_PERCENT = 0);
GO

-- [45] olap_ds_nam_mh_kh (3D)
SELECT t.nam AS nam,
       f.mh_key AS mh_key,
       mh.mo_ta AS mo_ta,
       f.kh_key AS kh_key,
       kh.ten AS ten,
       kh.loai_kh AS loai_kh,
       SUM(f.so_luong) AS tong_so_luong,
       SUM(f.doanh_thu) AS tong_doanh_thu
INTO dbo.[olap_ds_nam_mh_kh]
FROM DW_Core.dbo.Fact_BanHang f
JOIN DW_Core.dbo.Dim_Ngay n ON n.ngay_key = f.ngay_key
JOIN DW_Core.dbo.Dim_ThoiGian t ON t.time_key = n.time_key
JOIN DW_Core.dbo.Dim_KhachHang kh ON kh.kh_key = f.kh_key
JOIN DW_Core.dbo.Dim_MatHang mh ON mh.mh_key = f.mh_key
GROUP BY t.nam, f.mh_key, mh.mo_ta, f.kh_key, kh.ten, kh.loai_kh
OPTION (MAXDOP 1, MAX_GRANT_PERCENT = 0);
GO

-- [46] olap_ds_nam_mh_kh_tinh (4D)
SELECT t.nam AS nam,
       f.mh_key AS mh_key,
       mh.mo_ta AS mo_ta,
       f.kh_key AS kh_key,
       kh.ten AS ten,
       kh.loai_kh AS loai_kh,
       v.bang AS bang,
       SUM(f.so_luong) AS tong_so_luong,
       SUM(f.doanh_thu) AS tong_doanh_thu
INTO dbo.[olap_ds_nam_mh_kh_tinh]
FROM DW_Core.dbo.Fact_BanHang f
JOIN DW_Core.dbo.Dim_Ngay n ON n.ngay_key = f.ngay_key
JOIN DW_Core.dbo.Dim_ThoiGian t ON t.time_key = n.time_key
JOIN DW_Core.dbo.Dim_KhachHang kh ON kh.kh_key = f.kh_key
JOIN DW_Core.dbo.Dim_MatHang mh ON mh.mh_key = f.mh_key
JOIN DW_Core.dbo.Dim_CuaHang ch ON ch.ch_key = f.ch_key
JOIN DW_Core.dbo.Dim_VPDD v ON v.vp_key = ch.vp_key
GROUP BY t.nam, f.mh_key, mh.mo_ta, f.kh_key, kh.ten, kh.loai_kh, v.bang
OPTION (MAXDOP 1, MAX_GRANT_PERCENT = 0);
GO

-- [47] olap_ds_nam_mh_kh_tp (4D)
SELECT t.nam AS nam,
       f.mh_key AS mh_key,
       mh.mo_ta AS mo_ta,
       f.kh_key AS kh_key,
       kh.ten AS ten,
       kh.loai_kh AS loai_kh,
       v.bang AS bang,
       v.ten_tp AS ten_tp,
       SUM(f.so_luong) AS tong_so_luong,
       SUM(f.doanh_thu) AS tong_doanh_thu
INTO dbo.[olap_ds_nam_mh_kh_tp]
FROM DW_Core.dbo.Fact_BanHang f
JOIN DW_Core.dbo.Dim_Ngay n ON n.ngay_key = f.ngay_key
JOIN DW_Core.dbo.Dim_ThoiGian t ON t.time_key = n.time_key
JOIN DW_Core.dbo.Dim_KhachHang kh ON kh.kh_key = f.kh_key
JOIN DW_Core.dbo.Dim_MatHang mh ON mh.mh_key = f.mh_key
JOIN DW_Core.dbo.Dim_CuaHang ch ON ch.ch_key = f.ch_key
JOIN DW_Core.dbo.Dim_VPDD v ON v.vp_key = ch.vp_key
GROUP BY t.nam, f.mh_key, mh.mo_ta, f.kh_key, kh.ten, kh.loai_kh, v.bang, v.ten_tp
OPTION (MAXDOP 1, MAX_GRANT_PERCENT = 0);
GO

-- [48] olap_ds_nam_mh_kh_ch (4D)
SELECT t.nam AS nam,
       f.mh_key AS mh_key,
       mh.mo_ta AS mo_ta,
       f.kh_key AS kh_key,
       kh.ten AS ten,
       kh.loai_kh AS loai_kh,
       v.bang AS bang,
       v.ten_tp AS ten_tp,
       f.ch_key AS ch_key,
       SUM(f.so_luong) AS tong_so_luong,
       SUM(f.doanh_thu) AS tong_doanh_thu
INTO dbo.[olap_ds_nam_mh_kh_ch]
FROM DW_Core.dbo.Fact_BanHang f
JOIN DW_Core.dbo.Dim_Ngay n ON n.ngay_key = f.ngay_key
JOIN DW_Core.dbo.Dim_ThoiGian t ON t.time_key = n.time_key
JOIN DW_Core.dbo.Dim_KhachHang kh ON kh.kh_key = f.kh_key
JOIN DW_Core.dbo.Dim_MatHang mh ON mh.mh_key = f.mh_key
JOIN DW_Core.dbo.Dim_CuaHang ch ON ch.ch_key = f.ch_key
JOIN DW_Core.dbo.Dim_VPDD v ON v.vp_key = ch.vp_key
GROUP BY t.nam, f.mh_key, mh.mo_ta, f.kh_key, kh.ten, kh.loai_kh, v.bang, v.ten_tp, f.ch_key
OPTION (MAXDOP 1, MAX_GRANT_PERCENT = 0);
GO

-- [49] olap_ds_quy (1D)
SELECT t.nam AS nam,
       t.quy AS quy,
       SUM(f.so_luong) AS tong_so_luong,
       SUM(f.doanh_thu) AS tong_doanh_thu
INTO dbo.[olap_ds_quy]
FROM DW_Core.dbo.Fact_BanHang f
JOIN DW_Core.dbo.Dim_Ngay n ON n.ngay_key = f.ngay_key
JOIN DW_Core.dbo.Dim_ThoiGian t ON t.time_key = n.time_key
GROUP BY t.nam, t.quy
OPTION (MAXDOP 1, MAX_GRANT_PERCENT = 0);
GO

-- [50] olap_ds_quy_tinh (2D)
SELECT t.nam AS nam,
       t.quy AS quy,
       v.bang AS bang,
       SUM(f.so_luong) AS tong_so_luong,
       SUM(f.doanh_thu) AS tong_doanh_thu
INTO dbo.[olap_ds_quy_tinh]
FROM DW_Core.dbo.Fact_BanHang f
JOIN DW_Core.dbo.Dim_Ngay n ON n.ngay_key = f.ngay_key
JOIN DW_Core.dbo.Dim_ThoiGian t ON t.time_key = n.time_key
JOIN DW_Core.dbo.Dim_CuaHang ch ON ch.ch_key = f.ch_key
JOIN DW_Core.dbo.Dim_VPDD v ON v.vp_key = ch.vp_key
GROUP BY t.nam, t.quy, v.bang
OPTION (MAXDOP 1, MAX_GRANT_PERCENT = 0);
GO

-- [51] olap_ds_quy_tp (2D)
SELECT t.nam AS nam,
       t.quy AS quy,
       v.bang AS bang,
       v.ten_tp AS ten_tp,
       SUM(f.so_luong) AS tong_so_luong,
       SUM(f.doanh_thu) AS tong_doanh_thu
INTO dbo.[olap_ds_quy_tp]
FROM DW_Core.dbo.Fact_BanHang f
JOIN DW_Core.dbo.Dim_Ngay n ON n.ngay_key = f.ngay_key
JOIN DW_Core.dbo.Dim_ThoiGian t ON t.time_key = n.time_key
JOIN DW_Core.dbo.Dim_CuaHang ch ON ch.ch_key = f.ch_key
JOIN DW_Core.dbo.Dim_VPDD v ON v.vp_key = ch.vp_key
GROUP BY t.nam, t.quy, v.bang, v.ten_tp
OPTION (MAXDOP 1, MAX_GRANT_PERCENT = 0);
GO

-- [52] olap_ds_quy_ch (2D)
SELECT t.nam AS nam,
       t.quy AS quy,
       v.bang AS bang,
       v.ten_tp AS ten_tp,
       f.ch_key AS ch_key,
       SUM(f.so_luong) AS tong_so_luong,
       SUM(f.doanh_thu) AS tong_doanh_thu
INTO dbo.[olap_ds_quy_ch]
FROM DW_Core.dbo.Fact_BanHang f
JOIN DW_Core.dbo.Dim_Ngay n ON n.ngay_key = f.ngay_key
JOIN DW_Core.dbo.Dim_ThoiGian t ON t.time_key = n.time_key
JOIN DW_Core.dbo.Dim_CuaHang ch ON ch.ch_key = f.ch_key
JOIN DW_Core.dbo.Dim_VPDD v ON v.vp_key = ch.vp_key
GROUP BY t.nam, t.quy, v.bang, v.ten_tp, f.ch_key
OPTION (MAXDOP 1, MAX_GRANT_PERCENT = 0);
GO

-- [53] olap_ds_quy_loai_kh (2D)
SELECT t.nam AS nam,
       t.quy AS quy,
       kh.loai_kh AS loai_kh,
       SUM(f.so_luong) AS tong_so_luong,
       SUM(f.doanh_thu) AS tong_doanh_thu
INTO dbo.[olap_ds_quy_loai_kh]
FROM DW_Core.dbo.Fact_BanHang f
JOIN DW_Core.dbo.Dim_Ngay n ON n.ngay_key = f.ngay_key
JOIN DW_Core.dbo.Dim_ThoiGian t ON t.time_key = n.time_key
JOIN DW_Core.dbo.Dim_KhachHang kh ON kh.kh_key = f.kh_key
GROUP BY t.nam, t.quy, kh.loai_kh
OPTION (MAXDOP 1, MAX_GRANT_PERCENT = 0);
GO

-- [54] olap_ds_quy_loai_kh_tinh (3D)
SELECT t.nam AS nam,
       t.quy AS quy,
       kh.loai_kh AS loai_kh,
       v.bang AS bang,
       SUM(f.so_luong) AS tong_so_luong,
       SUM(f.doanh_thu) AS tong_doanh_thu
INTO dbo.[olap_ds_quy_loai_kh_tinh]
FROM DW_Core.dbo.Fact_BanHang f
JOIN DW_Core.dbo.Dim_Ngay n ON n.ngay_key = f.ngay_key
JOIN DW_Core.dbo.Dim_ThoiGian t ON t.time_key = n.time_key
JOIN DW_Core.dbo.Dim_KhachHang kh ON kh.kh_key = f.kh_key
JOIN DW_Core.dbo.Dim_CuaHang ch ON ch.ch_key = f.ch_key
JOIN DW_Core.dbo.Dim_VPDD v ON v.vp_key = ch.vp_key
GROUP BY t.nam, t.quy, kh.loai_kh, v.bang
OPTION (MAXDOP 1, MAX_GRANT_PERCENT = 0);
GO

-- [55] olap_ds_quy_loai_kh_tp (3D)
SELECT t.nam AS nam,
       t.quy AS quy,
       kh.loai_kh AS loai_kh,
       v.bang AS bang,
       v.ten_tp AS ten_tp,
       SUM(f.so_luong) AS tong_so_luong,
       SUM(f.doanh_thu) AS tong_doanh_thu
INTO dbo.[olap_ds_quy_loai_kh_tp]
FROM DW_Core.dbo.Fact_BanHang f
JOIN DW_Core.dbo.Dim_Ngay n ON n.ngay_key = f.ngay_key
JOIN DW_Core.dbo.Dim_ThoiGian t ON t.time_key = n.time_key
JOIN DW_Core.dbo.Dim_KhachHang kh ON kh.kh_key = f.kh_key
JOIN DW_Core.dbo.Dim_CuaHang ch ON ch.ch_key = f.ch_key
JOIN DW_Core.dbo.Dim_VPDD v ON v.vp_key = ch.vp_key
GROUP BY t.nam, t.quy, kh.loai_kh, v.bang, v.ten_tp
OPTION (MAXDOP 1, MAX_GRANT_PERCENT = 0);
GO

-- [56] olap_ds_quy_loai_kh_ch (3D)
SELECT t.nam AS nam,
       t.quy AS quy,
       kh.loai_kh AS loai_kh,
       v.bang AS bang,
       v.ten_tp AS ten_tp,
       f.ch_key AS ch_key,
       SUM(f.so_luong) AS tong_so_luong,
       SUM(f.doanh_thu) AS tong_doanh_thu
INTO dbo.[olap_ds_quy_loai_kh_ch]
FROM DW_Core.dbo.Fact_BanHang f
JOIN DW_Core.dbo.Dim_Ngay n ON n.ngay_key = f.ngay_key
JOIN DW_Core.dbo.Dim_ThoiGian t ON t.time_key = n.time_key
JOIN DW_Core.dbo.Dim_KhachHang kh ON kh.kh_key = f.kh_key
JOIN DW_Core.dbo.Dim_CuaHang ch ON ch.ch_key = f.ch_key
JOIN DW_Core.dbo.Dim_VPDD v ON v.vp_key = ch.vp_key
GROUP BY t.nam, t.quy, kh.loai_kh, v.bang, v.ten_tp, f.ch_key
OPTION (MAXDOP 1, MAX_GRANT_PERCENT = 0);
GO

-- [57] olap_ds_quy_kh (2D)
SELECT t.nam AS nam,
       t.quy AS quy,
       f.kh_key AS kh_key,
       kh.ten AS ten,
       kh.loai_kh AS loai_kh,
       SUM(f.so_luong) AS tong_so_luong,
       SUM(f.doanh_thu) AS tong_doanh_thu
INTO dbo.[olap_ds_quy_kh]
FROM DW_Core.dbo.Fact_BanHang f
JOIN DW_Core.dbo.Dim_Ngay n ON n.ngay_key = f.ngay_key
JOIN DW_Core.dbo.Dim_ThoiGian t ON t.time_key = n.time_key
JOIN DW_Core.dbo.Dim_KhachHang kh ON kh.kh_key = f.kh_key
GROUP BY t.nam, t.quy, f.kh_key, kh.ten, kh.loai_kh
OPTION (MAXDOP 1, MAX_GRANT_PERCENT = 0);
GO

-- [58] olap_ds_quy_kh_tinh (3D)
SELECT t.nam AS nam,
       t.quy AS quy,
       f.kh_key AS kh_key,
       kh.ten AS ten,
       kh.loai_kh AS loai_kh,
       v.bang AS bang,
       SUM(f.so_luong) AS tong_so_luong,
       SUM(f.doanh_thu) AS tong_doanh_thu
INTO dbo.[olap_ds_quy_kh_tinh]
FROM DW_Core.dbo.Fact_BanHang f
JOIN DW_Core.dbo.Dim_Ngay n ON n.ngay_key = f.ngay_key
JOIN DW_Core.dbo.Dim_ThoiGian t ON t.time_key = n.time_key
JOIN DW_Core.dbo.Dim_KhachHang kh ON kh.kh_key = f.kh_key
JOIN DW_Core.dbo.Dim_CuaHang ch ON ch.ch_key = f.ch_key
JOIN DW_Core.dbo.Dim_VPDD v ON v.vp_key = ch.vp_key
GROUP BY t.nam, t.quy, f.kh_key, kh.ten, kh.loai_kh, v.bang
OPTION (MAXDOP 1, MAX_GRANT_PERCENT = 0);
GO

-- [59] olap_ds_quy_kh_tp (3D)
SELECT t.nam AS nam,
       t.quy AS quy,
       f.kh_key AS kh_key,
       kh.ten AS ten,
       kh.loai_kh AS loai_kh,
       v.bang AS bang,
       v.ten_tp AS ten_tp,
       SUM(f.so_luong) AS tong_so_luong,
       SUM(f.doanh_thu) AS tong_doanh_thu
INTO dbo.[olap_ds_quy_kh_tp]
FROM DW_Core.dbo.Fact_BanHang f
JOIN DW_Core.dbo.Dim_Ngay n ON n.ngay_key = f.ngay_key
JOIN DW_Core.dbo.Dim_ThoiGian t ON t.time_key = n.time_key
JOIN DW_Core.dbo.Dim_KhachHang kh ON kh.kh_key = f.kh_key
JOIN DW_Core.dbo.Dim_CuaHang ch ON ch.ch_key = f.ch_key
JOIN DW_Core.dbo.Dim_VPDD v ON v.vp_key = ch.vp_key
GROUP BY t.nam, t.quy, f.kh_key, kh.ten, kh.loai_kh, v.bang, v.ten_tp
OPTION (MAXDOP 1, MAX_GRANT_PERCENT = 0);
GO

-- [60] olap_ds_quy_kh_ch (3D)
SELECT t.nam AS nam,
       t.quy AS quy,
       f.kh_key AS kh_key,
       kh.ten AS ten,
       kh.loai_kh AS loai_kh,
       v.bang AS bang,
       v.ten_tp AS ten_tp,
       f.ch_key AS ch_key,
       SUM(f.so_luong) AS tong_so_luong,
       SUM(f.doanh_thu) AS tong_doanh_thu
INTO dbo.[olap_ds_quy_kh_ch]
FROM DW_Core.dbo.Fact_BanHang f
JOIN DW_Core.dbo.Dim_Ngay n ON n.ngay_key = f.ngay_key
JOIN DW_Core.dbo.Dim_ThoiGian t ON t.time_key = n.time_key
JOIN DW_Core.dbo.Dim_KhachHang kh ON kh.kh_key = f.kh_key
JOIN DW_Core.dbo.Dim_CuaHang ch ON ch.ch_key = f.ch_key
JOIN DW_Core.dbo.Dim_VPDD v ON v.vp_key = ch.vp_key
GROUP BY t.nam, t.quy, f.kh_key, kh.ten, kh.loai_kh, v.bang, v.ten_tp, f.ch_key
OPTION (MAXDOP 1, MAX_GRANT_PERCENT = 0);
GO

-- [61] olap_ds_quy_mh (2D)
SELECT t.nam AS nam,
       t.quy AS quy,
       f.mh_key AS mh_key,
       mh.mo_ta AS mo_ta,
       SUM(f.so_luong) AS tong_so_luong,
       SUM(f.doanh_thu) AS tong_doanh_thu
INTO dbo.[olap_ds_quy_mh]
FROM DW_Core.dbo.Fact_BanHang f
JOIN DW_Core.dbo.Dim_Ngay n ON n.ngay_key = f.ngay_key
JOIN DW_Core.dbo.Dim_ThoiGian t ON t.time_key = n.time_key
JOIN DW_Core.dbo.Dim_MatHang mh ON mh.mh_key = f.mh_key
GROUP BY t.nam, t.quy, f.mh_key, mh.mo_ta
OPTION (MAXDOP 1, MAX_GRANT_PERCENT = 0);
GO

-- [62] olap_ds_quy_mh_tinh (3D)
SELECT t.nam AS nam,
       t.quy AS quy,
       f.mh_key AS mh_key,
       mh.mo_ta AS mo_ta,
       v.bang AS bang,
       SUM(f.so_luong) AS tong_so_luong,
       SUM(f.doanh_thu) AS tong_doanh_thu
INTO dbo.[olap_ds_quy_mh_tinh]
FROM DW_Core.dbo.Fact_BanHang f
JOIN DW_Core.dbo.Dim_Ngay n ON n.ngay_key = f.ngay_key
JOIN DW_Core.dbo.Dim_ThoiGian t ON t.time_key = n.time_key
JOIN DW_Core.dbo.Dim_MatHang mh ON mh.mh_key = f.mh_key
JOIN DW_Core.dbo.Dim_CuaHang ch ON ch.ch_key = f.ch_key
JOIN DW_Core.dbo.Dim_VPDD v ON v.vp_key = ch.vp_key
GROUP BY t.nam, t.quy, f.mh_key, mh.mo_ta, v.bang
OPTION (MAXDOP 1, MAX_GRANT_PERCENT = 0);
GO

-- [63] olap_ds_quy_mh_tp (3D)
SELECT t.nam AS nam,
       t.quy AS quy,
       f.mh_key AS mh_key,
       mh.mo_ta AS mo_ta,
       v.bang AS bang,
       v.ten_tp AS ten_tp,
       SUM(f.so_luong) AS tong_so_luong,
       SUM(f.doanh_thu) AS tong_doanh_thu
INTO dbo.[olap_ds_quy_mh_tp]
FROM DW_Core.dbo.Fact_BanHang f
JOIN DW_Core.dbo.Dim_Ngay n ON n.ngay_key = f.ngay_key
JOIN DW_Core.dbo.Dim_ThoiGian t ON t.time_key = n.time_key
JOIN DW_Core.dbo.Dim_MatHang mh ON mh.mh_key = f.mh_key
JOIN DW_Core.dbo.Dim_CuaHang ch ON ch.ch_key = f.ch_key
JOIN DW_Core.dbo.Dim_VPDD v ON v.vp_key = ch.vp_key
GROUP BY t.nam, t.quy, f.mh_key, mh.mo_ta, v.bang, v.ten_tp
OPTION (MAXDOP 1, MAX_GRANT_PERCENT = 0);
GO

-- [64] olap_ds_quy_mh_ch (3D)
SELECT t.nam AS nam,
       t.quy AS quy,
       f.mh_key AS mh_key,
       mh.mo_ta AS mo_ta,
       v.bang AS bang,
       v.ten_tp AS ten_tp,
       f.ch_key AS ch_key,
       SUM(f.so_luong) AS tong_so_luong,
       SUM(f.doanh_thu) AS tong_doanh_thu
INTO dbo.[olap_ds_quy_mh_ch]
FROM DW_Core.dbo.Fact_BanHang f
JOIN DW_Core.dbo.Dim_Ngay n ON n.ngay_key = f.ngay_key
JOIN DW_Core.dbo.Dim_ThoiGian t ON t.time_key = n.time_key
JOIN DW_Core.dbo.Dim_MatHang mh ON mh.mh_key = f.mh_key
JOIN DW_Core.dbo.Dim_CuaHang ch ON ch.ch_key = f.ch_key
JOIN DW_Core.dbo.Dim_VPDD v ON v.vp_key = ch.vp_key
GROUP BY t.nam, t.quy, f.mh_key, mh.mo_ta, v.bang, v.ten_tp, f.ch_key
OPTION (MAXDOP 1, MAX_GRANT_PERCENT = 0);
GO

-- [65] olap_ds_quy_mh_loai_kh (3D)
SELECT t.nam AS nam,
       t.quy AS quy,
       f.mh_key AS mh_key,
       mh.mo_ta AS mo_ta,
       kh.loai_kh AS loai_kh,
       SUM(f.so_luong) AS tong_so_luong,
       SUM(f.doanh_thu) AS tong_doanh_thu
INTO dbo.[olap_ds_quy_mh_loai_kh]
FROM DW_Core.dbo.Fact_BanHang f
JOIN DW_Core.dbo.Dim_Ngay n ON n.ngay_key = f.ngay_key
JOIN DW_Core.dbo.Dim_ThoiGian t ON t.time_key = n.time_key
JOIN DW_Core.dbo.Dim_KhachHang kh ON kh.kh_key = f.kh_key
JOIN DW_Core.dbo.Dim_MatHang mh ON mh.mh_key = f.mh_key
GROUP BY t.nam, t.quy, f.mh_key, mh.mo_ta, kh.loai_kh
OPTION (MAXDOP 1, MAX_GRANT_PERCENT = 0);
GO

-- [66] olap_ds_quy_mh_loai_kh_tinh (4D)
SELECT t.nam AS nam,
       t.quy AS quy,
       f.mh_key AS mh_key,
       mh.mo_ta AS mo_ta,
       kh.loai_kh AS loai_kh,
       v.bang AS bang,
       SUM(f.so_luong) AS tong_so_luong,
       SUM(f.doanh_thu) AS tong_doanh_thu
INTO dbo.[olap_ds_quy_mh_loai_kh_tinh]
FROM DW_Core.dbo.Fact_BanHang f
JOIN DW_Core.dbo.Dim_Ngay n ON n.ngay_key = f.ngay_key
JOIN DW_Core.dbo.Dim_ThoiGian t ON t.time_key = n.time_key
JOIN DW_Core.dbo.Dim_KhachHang kh ON kh.kh_key = f.kh_key
JOIN DW_Core.dbo.Dim_MatHang mh ON mh.mh_key = f.mh_key
JOIN DW_Core.dbo.Dim_CuaHang ch ON ch.ch_key = f.ch_key
JOIN DW_Core.dbo.Dim_VPDD v ON v.vp_key = ch.vp_key
GROUP BY t.nam, t.quy, f.mh_key, mh.mo_ta, kh.loai_kh, v.bang
OPTION (MAXDOP 1, MAX_GRANT_PERCENT = 0);
GO

-- [67] olap_ds_quy_mh_loai_kh_tp (4D)
SELECT t.nam AS nam,
       t.quy AS quy,
       f.mh_key AS mh_key,
       mh.mo_ta AS mo_ta,
       kh.loai_kh AS loai_kh,
       v.bang AS bang,
       v.ten_tp AS ten_tp,
       SUM(f.so_luong) AS tong_so_luong,
       SUM(f.doanh_thu) AS tong_doanh_thu
INTO dbo.[olap_ds_quy_mh_loai_kh_tp]
FROM DW_Core.dbo.Fact_BanHang f
JOIN DW_Core.dbo.Dim_Ngay n ON n.ngay_key = f.ngay_key
JOIN DW_Core.dbo.Dim_ThoiGian t ON t.time_key = n.time_key
JOIN DW_Core.dbo.Dim_KhachHang kh ON kh.kh_key = f.kh_key
JOIN DW_Core.dbo.Dim_MatHang mh ON mh.mh_key = f.mh_key
JOIN DW_Core.dbo.Dim_CuaHang ch ON ch.ch_key = f.ch_key
JOIN DW_Core.dbo.Dim_VPDD v ON v.vp_key = ch.vp_key
GROUP BY t.nam, t.quy, f.mh_key, mh.mo_ta, kh.loai_kh, v.bang, v.ten_tp
OPTION (MAXDOP 1, MAX_GRANT_PERCENT = 0);
GO

-- [68] olap_ds_quy_mh_loai_kh_ch (4D)
SELECT t.nam AS nam,
       t.quy AS quy,
       f.mh_key AS mh_key,
       mh.mo_ta AS mo_ta,
       kh.loai_kh AS loai_kh,
       v.bang AS bang,
       v.ten_tp AS ten_tp,
       f.ch_key AS ch_key,
       SUM(f.so_luong) AS tong_so_luong,
       SUM(f.doanh_thu) AS tong_doanh_thu
INTO dbo.[olap_ds_quy_mh_loai_kh_ch]
FROM DW_Core.dbo.Fact_BanHang f
JOIN DW_Core.dbo.Dim_Ngay n ON n.ngay_key = f.ngay_key
JOIN DW_Core.dbo.Dim_ThoiGian t ON t.time_key = n.time_key
JOIN DW_Core.dbo.Dim_KhachHang kh ON kh.kh_key = f.kh_key
JOIN DW_Core.dbo.Dim_MatHang mh ON mh.mh_key = f.mh_key
JOIN DW_Core.dbo.Dim_CuaHang ch ON ch.ch_key = f.ch_key
JOIN DW_Core.dbo.Dim_VPDD v ON v.vp_key = ch.vp_key
GROUP BY t.nam, t.quy, f.mh_key, mh.mo_ta, kh.loai_kh, v.bang, v.ten_tp, f.ch_key
OPTION (MAXDOP 1, MAX_GRANT_PERCENT = 0);
GO

-- [69] olap_ds_quy_mh_kh (3D)
SELECT t.nam AS nam,
       t.quy AS quy,
       f.mh_key AS mh_key,
       mh.mo_ta AS mo_ta,
       f.kh_key AS kh_key,
       kh.ten AS ten,
       kh.loai_kh AS loai_kh,
       SUM(f.so_luong) AS tong_so_luong,
       SUM(f.doanh_thu) AS tong_doanh_thu
INTO dbo.[olap_ds_quy_mh_kh]
FROM DW_Core.dbo.Fact_BanHang f
JOIN DW_Core.dbo.Dim_Ngay n ON n.ngay_key = f.ngay_key
JOIN DW_Core.dbo.Dim_ThoiGian t ON t.time_key = n.time_key
JOIN DW_Core.dbo.Dim_KhachHang kh ON kh.kh_key = f.kh_key
JOIN DW_Core.dbo.Dim_MatHang mh ON mh.mh_key = f.mh_key
GROUP BY t.nam, t.quy, f.mh_key, mh.mo_ta, f.kh_key, kh.ten, kh.loai_kh
OPTION (MAXDOP 1, MAX_GRANT_PERCENT = 0);
GO

-- [70] olap_ds_quy_mh_kh_tinh (4D)
SELECT t.nam AS nam,
       t.quy AS quy,
       f.mh_key AS mh_key,
       mh.mo_ta AS mo_ta,
       f.kh_key AS kh_key,
       kh.ten AS ten,
       kh.loai_kh AS loai_kh,
       v.bang AS bang,
       SUM(f.so_luong) AS tong_so_luong,
       SUM(f.doanh_thu) AS tong_doanh_thu
INTO dbo.[olap_ds_quy_mh_kh_tinh]
FROM DW_Core.dbo.Fact_BanHang f
JOIN DW_Core.dbo.Dim_Ngay n ON n.ngay_key = f.ngay_key
JOIN DW_Core.dbo.Dim_ThoiGian t ON t.time_key = n.time_key
JOIN DW_Core.dbo.Dim_KhachHang kh ON kh.kh_key = f.kh_key
JOIN DW_Core.dbo.Dim_MatHang mh ON mh.mh_key = f.mh_key
JOIN DW_Core.dbo.Dim_CuaHang ch ON ch.ch_key = f.ch_key
JOIN DW_Core.dbo.Dim_VPDD v ON v.vp_key = ch.vp_key
GROUP BY t.nam, t.quy, f.mh_key, mh.mo_ta, f.kh_key, kh.ten, kh.loai_kh, v.bang
OPTION (MAXDOP 1, MAX_GRANT_PERCENT = 0);
GO

-- [71] olap_ds_quy_mh_kh_tp (4D)
SELECT t.nam AS nam,
       t.quy AS quy,
       f.mh_key AS mh_key,
       mh.mo_ta AS mo_ta,
       f.kh_key AS kh_key,
       kh.ten AS ten,
       kh.loai_kh AS loai_kh,
       v.bang AS bang,
       v.ten_tp AS ten_tp,
       SUM(f.so_luong) AS tong_so_luong,
       SUM(f.doanh_thu) AS tong_doanh_thu
INTO dbo.[olap_ds_quy_mh_kh_tp]
FROM DW_Core.dbo.Fact_BanHang f
JOIN DW_Core.dbo.Dim_Ngay n ON n.ngay_key = f.ngay_key
JOIN DW_Core.dbo.Dim_ThoiGian t ON t.time_key = n.time_key
JOIN DW_Core.dbo.Dim_KhachHang kh ON kh.kh_key = f.kh_key
JOIN DW_Core.dbo.Dim_MatHang mh ON mh.mh_key = f.mh_key
JOIN DW_Core.dbo.Dim_CuaHang ch ON ch.ch_key = f.ch_key
JOIN DW_Core.dbo.Dim_VPDD v ON v.vp_key = ch.vp_key
GROUP BY t.nam, t.quy, f.mh_key, mh.mo_ta, f.kh_key, kh.ten, kh.loai_kh, v.bang, v.ten_tp
OPTION (MAXDOP 1, MAX_GRANT_PERCENT = 0);
GO

-- [72] olap_ds_quy_mh_kh_ch (4D)
SELECT t.nam AS nam,
       t.quy AS quy,
       f.mh_key AS mh_key,
       mh.mo_ta AS mo_ta,
       f.kh_key AS kh_key,
       kh.ten AS ten,
       kh.loai_kh AS loai_kh,
       v.bang AS bang,
       v.ten_tp AS ten_tp,
       f.ch_key AS ch_key,
       SUM(f.so_luong) AS tong_so_luong,
       SUM(f.doanh_thu) AS tong_doanh_thu
INTO dbo.[olap_ds_quy_mh_kh_ch]
FROM DW_Core.dbo.Fact_BanHang f
JOIN DW_Core.dbo.Dim_Ngay n ON n.ngay_key = f.ngay_key
JOIN DW_Core.dbo.Dim_ThoiGian t ON t.time_key = n.time_key
JOIN DW_Core.dbo.Dim_KhachHang kh ON kh.kh_key = f.kh_key
JOIN DW_Core.dbo.Dim_MatHang mh ON mh.mh_key = f.mh_key
JOIN DW_Core.dbo.Dim_CuaHang ch ON ch.ch_key = f.ch_key
JOIN DW_Core.dbo.Dim_VPDD v ON v.vp_key = ch.vp_key
GROUP BY t.nam, t.quy, f.mh_key, mh.mo_ta, f.kh_key, kh.ten, kh.loai_kh, v.bang, v.ten_tp, f.ch_key
OPTION (MAXDOP 1, MAX_GRANT_PERCENT = 0);
GO

-- [73] olap_ds_thang (1D)
SELECT t.nam AS nam,
       t.quy AS quy,
       t.thang AS thang,
       SUM(f.so_luong) AS tong_so_luong,
       SUM(f.doanh_thu) AS tong_doanh_thu
INTO dbo.[olap_ds_thang]
FROM DW_Core.dbo.Fact_BanHang f
JOIN DW_Core.dbo.Dim_Ngay n ON n.ngay_key = f.ngay_key
JOIN DW_Core.dbo.Dim_ThoiGian t ON t.time_key = n.time_key
GROUP BY t.nam, t.quy, t.thang
OPTION (MAXDOP 1, MAX_GRANT_PERCENT = 0);
GO

-- [74] olap_ds_thang_tinh (2D)
SELECT t.nam AS nam,
       t.quy AS quy,
       t.thang AS thang,
       v.bang AS bang,
       SUM(f.so_luong) AS tong_so_luong,
       SUM(f.doanh_thu) AS tong_doanh_thu
INTO dbo.[olap_ds_thang_tinh]
FROM DW_Core.dbo.Fact_BanHang f
JOIN DW_Core.dbo.Dim_Ngay n ON n.ngay_key = f.ngay_key
JOIN DW_Core.dbo.Dim_ThoiGian t ON t.time_key = n.time_key
JOIN DW_Core.dbo.Dim_CuaHang ch ON ch.ch_key = f.ch_key
JOIN DW_Core.dbo.Dim_VPDD v ON v.vp_key = ch.vp_key
GROUP BY t.nam, t.quy, t.thang, v.bang
OPTION (MAXDOP 1, MAX_GRANT_PERCENT = 0);
GO

-- [75] olap_ds_thang_tp (2D)
SELECT t.nam AS nam,
       t.quy AS quy,
       t.thang AS thang,
       v.bang AS bang,
       v.ten_tp AS ten_tp,
       SUM(f.so_luong) AS tong_so_luong,
       SUM(f.doanh_thu) AS tong_doanh_thu
INTO dbo.[olap_ds_thang_tp]
FROM DW_Core.dbo.Fact_BanHang f
JOIN DW_Core.dbo.Dim_Ngay n ON n.ngay_key = f.ngay_key
JOIN DW_Core.dbo.Dim_ThoiGian t ON t.time_key = n.time_key
JOIN DW_Core.dbo.Dim_CuaHang ch ON ch.ch_key = f.ch_key
JOIN DW_Core.dbo.Dim_VPDD v ON v.vp_key = ch.vp_key
GROUP BY t.nam, t.quy, t.thang, v.bang, v.ten_tp
OPTION (MAXDOP 1, MAX_GRANT_PERCENT = 0);
GO

-- [76] olap_ds_thang_ch (2D)
SELECT t.nam AS nam,
       t.quy AS quy,
       t.thang AS thang,
       v.bang AS bang,
       v.ten_tp AS ten_tp,
       f.ch_key AS ch_key,
       SUM(f.so_luong) AS tong_so_luong,
       SUM(f.doanh_thu) AS tong_doanh_thu
INTO dbo.[olap_ds_thang_ch]
FROM DW_Core.dbo.Fact_BanHang f
JOIN DW_Core.dbo.Dim_Ngay n ON n.ngay_key = f.ngay_key
JOIN DW_Core.dbo.Dim_ThoiGian t ON t.time_key = n.time_key
JOIN DW_Core.dbo.Dim_CuaHang ch ON ch.ch_key = f.ch_key
JOIN DW_Core.dbo.Dim_VPDD v ON v.vp_key = ch.vp_key
GROUP BY t.nam, t.quy, t.thang, v.bang, v.ten_tp, f.ch_key
OPTION (MAXDOP 1, MAX_GRANT_PERCENT = 0);
GO

-- [77] olap_ds_thang_loai_kh (2D)
SELECT t.nam AS nam,
       t.quy AS quy,
       t.thang AS thang,
       kh.loai_kh AS loai_kh,
       SUM(f.so_luong) AS tong_so_luong,
       SUM(f.doanh_thu) AS tong_doanh_thu
INTO dbo.[olap_ds_thang_loai_kh]
FROM DW_Core.dbo.Fact_BanHang f
JOIN DW_Core.dbo.Dim_Ngay n ON n.ngay_key = f.ngay_key
JOIN DW_Core.dbo.Dim_ThoiGian t ON t.time_key = n.time_key
JOIN DW_Core.dbo.Dim_KhachHang kh ON kh.kh_key = f.kh_key
GROUP BY t.nam, t.quy, t.thang, kh.loai_kh
OPTION (MAXDOP 1, MAX_GRANT_PERCENT = 0);
GO

-- [78] olap_ds_thang_loai_kh_tinh (3D)
SELECT t.nam AS nam,
       t.quy AS quy,
       t.thang AS thang,
       kh.loai_kh AS loai_kh,
       v.bang AS bang,
       SUM(f.so_luong) AS tong_so_luong,
       SUM(f.doanh_thu) AS tong_doanh_thu
INTO dbo.[olap_ds_thang_loai_kh_tinh]
FROM DW_Core.dbo.Fact_BanHang f
JOIN DW_Core.dbo.Dim_Ngay n ON n.ngay_key = f.ngay_key
JOIN DW_Core.dbo.Dim_ThoiGian t ON t.time_key = n.time_key
JOIN DW_Core.dbo.Dim_KhachHang kh ON kh.kh_key = f.kh_key
JOIN DW_Core.dbo.Dim_CuaHang ch ON ch.ch_key = f.ch_key
JOIN DW_Core.dbo.Dim_VPDD v ON v.vp_key = ch.vp_key
GROUP BY t.nam, t.quy, t.thang, kh.loai_kh, v.bang
OPTION (MAXDOP 1, MAX_GRANT_PERCENT = 0);
GO

-- [79] olap_ds_thang_loai_kh_tp (3D)
SELECT t.nam AS nam,
       t.quy AS quy,
       t.thang AS thang,
       kh.loai_kh AS loai_kh,
       v.bang AS bang,
       v.ten_tp AS ten_tp,
       SUM(f.so_luong) AS tong_so_luong,
       SUM(f.doanh_thu) AS tong_doanh_thu
INTO dbo.[olap_ds_thang_loai_kh_tp]
FROM DW_Core.dbo.Fact_BanHang f
JOIN DW_Core.dbo.Dim_Ngay n ON n.ngay_key = f.ngay_key
JOIN DW_Core.dbo.Dim_ThoiGian t ON t.time_key = n.time_key
JOIN DW_Core.dbo.Dim_KhachHang kh ON kh.kh_key = f.kh_key
JOIN DW_Core.dbo.Dim_CuaHang ch ON ch.ch_key = f.ch_key
JOIN DW_Core.dbo.Dim_VPDD v ON v.vp_key = ch.vp_key
GROUP BY t.nam, t.quy, t.thang, kh.loai_kh, v.bang, v.ten_tp
OPTION (MAXDOP 1, MAX_GRANT_PERCENT = 0);
GO

-- [80] olap_ds_thang_loai_kh_ch (3D)
SELECT t.nam AS nam,
       t.quy AS quy,
       t.thang AS thang,
       kh.loai_kh AS loai_kh,
       v.bang AS bang,
       v.ten_tp AS ten_tp,
       f.ch_key AS ch_key,
       SUM(f.so_luong) AS tong_so_luong,
       SUM(f.doanh_thu) AS tong_doanh_thu
INTO dbo.[olap_ds_thang_loai_kh_ch]
FROM DW_Core.dbo.Fact_BanHang f
JOIN DW_Core.dbo.Dim_Ngay n ON n.ngay_key = f.ngay_key
JOIN DW_Core.dbo.Dim_ThoiGian t ON t.time_key = n.time_key
JOIN DW_Core.dbo.Dim_KhachHang kh ON kh.kh_key = f.kh_key
JOIN DW_Core.dbo.Dim_CuaHang ch ON ch.ch_key = f.ch_key
JOIN DW_Core.dbo.Dim_VPDD v ON v.vp_key = ch.vp_key
GROUP BY t.nam, t.quy, t.thang, kh.loai_kh, v.bang, v.ten_tp, f.ch_key
OPTION (MAXDOP 1, MAX_GRANT_PERCENT = 0);
GO

-- [81] olap_ds_thang_kh (2D)
SELECT t.nam AS nam,
       t.quy AS quy,
       t.thang AS thang,
       f.kh_key AS kh_key,
       kh.ten AS ten,
       kh.loai_kh AS loai_kh,
       SUM(f.so_luong) AS tong_so_luong,
       SUM(f.doanh_thu) AS tong_doanh_thu
INTO dbo.[olap_ds_thang_kh]
FROM DW_Core.dbo.Fact_BanHang f
JOIN DW_Core.dbo.Dim_Ngay n ON n.ngay_key = f.ngay_key
JOIN DW_Core.dbo.Dim_ThoiGian t ON t.time_key = n.time_key
JOIN DW_Core.dbo.Dim_KhachHang kh ON kh.kh_key = f.kh_key
GROUP BY t.nam, t.quy, t.thang, f.kh_key, kh.ten, kh.loai_kh
OPTION (MAXDOP 1, MAX_GRANT_PERCENT = 0);
GO

-- [82] olap_ds_thang_kh_tinh (3D)
SELECT t.nam AS nam,
       t.quy AS quy,
       t.thang AS thang,
       f.kh_key AS kh_key,
       kh.ten AS ten,
       kh.loai_kh AS loai_kh,
       v.bang AS bang,
       SUM(f.so_luong) AS tong_so_luong,
       SUM(f.doanh_thu) AS tong_doanh_thu
INTO dbo.[olap_ds_thang_kh_tinh]
FROM DW_Core.dbo.Fact_BanHang f
JOIN DW_Core.dbo.Dim_Ngay n ON n.ngay_key = f.ngay_key
JOIN DW_Core.dbo.Dim_ThoiGian t ON t.time_key = n.time_key
JOIN DW_Core.dbo.Dim_KhachHang kh ON kh.kh_key = f.kh_key
JOIN DW_Core.dbo.Dim_CuaHang ch ON ch.ch_key = f.ch_key
JOIN DW_Core.dbo.Dim_VPDD v ON v.vp_key = ch.vp_key
GROUP BY t.nam, t.quy, t.thang, f.kh_key, kh.ten, kh.loai_kh, v.bang
OPTION (MAXDOP 1, MAX_GRANT_PERCENT = 0);
GO

-- [83] olap_ds_thang_kh_tp (3D)
SELECT t.nam AS nam,
       t.quy AS quy,
       t.thang AS thang,
       f.kh_key AS kh_key,
       kh.ten AS ten,
       kh.loai_kh AS loai_kh,
       v.bang AS bang,
       v.ten_tp AS ten_tp,
       SUM(f.so_luong) AS tong_so_luong,
       SUM(f.doanh_thu) AS tong_doanh_thu
INTO dbo.[olap_ds_thang_kh_tp]
FROM DW_Core.dbo.Fact_BanHang f
JOIN DW_Core.dbo.Dim_Ngay n ON n.ngay_key = f.ngay_key
JOIN DW_Core.dbo.Dim_ThoiGian t ON t.time_key = n.time_key
JOIN DW_Core.dbo.Dim_KhachHang kh ON kh.kh_key = f.kh_key
JOIN DW_Core.dbo.Dim_CuaHang ch ON ch.ch_key = f.ch_key
JOIN DW_Core.dbo.Dim_VPDD v ON v.vp_key = ch.vp_key
GROUP BY t.nam, t.quy, t.thang, f.kh_key, kh.ten, kh.loai_kh, v.bang, v.ten_tp
OPTION (MAXDOP 1, MAX_GRANT_PERCENT = 0);
GO

-- [84] olap_ds_thang_kh_ch (3D)
SELECT t.nam AS nam,
       t.quy AS quy,
       t.thang AS thang,
       f.kh_key AS kh_key,
       kh.ten AS ten,
       kh.loai_kh AS loai_kh,
       v.bang AS bang,
       v.ten_tp AS ten_tp,
       f.ch_key AS ch_key,
       SUM(f.so_luong) AS tong_so_luong,
       SUM(f.doanh_thu) AS tong_doanh_thu
INTO dbo.[olap_ds_thang_kh_ch]
FROM DW_Core.dbo.Fact_BanHang f
JOIN DW_Core.dbo.Dim_Ngay n ON n.ngay_key = f.ngay_key
JOIN DW_Core.dbo.Dim_ThoiGian t ON t.time_key = n.time_key
JOIN DW_Core.dbo.Dim_KhachHang kh ON kh.kh_key = f.kh_key
JOIN DW_Core.dbo.Dim_CuaHang ch ON ch.ch_key = f.ch_key
JOIN DW_Core.dbo.Dim_VPDD v ON v.vp_key = ch.vp_key
GROUP BY t.nam, t.quy, t.thang, f.kh_key, kh.ten, kh.loai_kh, v.bang, v.ten_tp, f.ch_key
OPTION (MAXDOP 1, MAX_GRANT_PERCENT = 0);
GO

-- [85] olap_ds_thang_mh (2D)
SELECT t.nam AS nam,
       t.quy AS quy,
       t.thang AS thang,
       f.mh_key AS mh_key,
       mh.mo_ta AS mo_ta,
       SUM(f.so_luong) AS tong_so_luong,
       SUM(f.doanh_thu) AS tong_doanh_thu
INTO dbo.[olap_ds_thang_mh]
FROM DW_Core.dbo.Fact_BanHang f
JOIN DW_Core.dbo.Dim_Ngay n ON n.ngay_key = f.ngay_key
JOIN DW_Core.dbo.Dim_ThoiGian t ON t.time_key = n.time_key
JOIN DW_Core.dbo.Dim_MatHang mh ON mh.mh_key = f.mh_key
GROUP BY t.nam, t.quy, t.thang, f.mh_key, mh.mo_ta
OPTION (MAXDOP 1, MAX_GRANT_PERCENT = 0);
GO

-- [86] olap_ds_thang_mh_tinh (3D)
SELECT t.nam AS nam,
       t.quy AS quy,
       t.thang AS thang,
       f.mh_key AS mh_key,
       mh.mo_ta AS mo_ta,
       v.bang AS bang,
       SUM(f.so_luong) AS tong_so_luong,
       SUM(f.doanh_thu) AS tong_doanh_thu
INTO dbo.[olap_ds_thang_mh_tinh]
FROM DW_Core.dbo.Fact_BanHang f
JOIN DW_Core.dbo.Dim_Ngay n ON n.ngay_key = f.ngay_key
JOIN DW_Core.dbo.Dim_ThoiGian t ON t.time_key = n.time_key
JOIN DW_Core.dbo.Dim_MatHang mh ON mh.mh_key = f.mh_key
JOIN DW_Core.dbo.Dim_CuaHang ch ON ch.ch_key = f.ch_key
JOIN DW_Core.dbo.Dim_VPDD v ON v.vp_key = ch.vp_key
GROUP BY t.nam, t.quy, t.thang, f.mh_key, mh.mo_ta, v.bang
OPTION (MAXDOP 1, MAX_GRANT_PERCENT = 0);
GO

-- [87] olap_ds_thang_mh_tp (3D)
SELECT t.nam AS nam,
       t.quy AS quy,
       t.thang AS thang,
       f.mh_key AS mh_key,
       mh.mo_ta AS mo_ta,
       v.bang AS bang,
       v.ten_tp AS ten_tp,
       SUM(f.so_luong) AS tong_so_luong,
       SUM(f.doanh_thu) AS tong_doanh_thu
INTO dbo.[olap_ds_thang_mh_tp]
FROM DW_Core.dbo.Fact_BanHang f
JOIN DW_Core.dbo.Dim_Ngay n ON n.ngay_key = f.ngay_key
JOIN DW_Core.dbo.Dim_ThoiGian t ON t.time_key = n.time_key
JOIN DW_Core.dbo.Dim_MatHang mh ON mh.mh_key = f.mh_key
JOIN DW_Core.dbo.Dim_CuaHang ch ON ch.ch_key = f.ch_key
JOIN DW_Core.dbo.Dim_VPDD v ON v.vp_key = ch.vp_key
GROUP BY t.nam, t.quy, t.thang, f.mh_key, mh.mo_ta, v.bang, v.ten_tp
OPTION (MAXDOP 1, MAX_GRANT_PERCENT = 0);
GO

-- [88] olap_ds_thang_mh_ch (3D)
SELECT t.nam AS nam,
       t.quy AS quy,
       t.thang AS thang,
       f.mh_key AS mh_key,
       mh.mo_ta AS mo_ta,
       v.bang AS bang,
       v.ten_tp AS ten_tp,
       f.ch_key AS ch_key,
       SUM(f.so_luong) AS tong_so_luong,
       SUM(f.doanh_thu) AS tong_doanh_thu
INTO dbo.[olap_ds_thang_mh_ch]
FROM DW_Core.dbo.Fact_BanHang f
JOIN DW_Core.dbo.Dim_Ngay n ON n.ngay_key = f.ngay_key
JOIN DW_Core.dbo.Dim_ThoiGian t ON t.time_key = n.time_key
JOIN DW_Core.dbo.Dim_MatHang mh ON mh.mh_key = f.mh_key
JOIN DW_Core.dbo.Dim_CuaHang ch ON ch.ch_key = f.ch_key
JOIN DW_Core.dbo.Dim_VPDD v ON v.vp_key = ch.vp_key
GROUP BY t.nam, t.quy, t.thang, f.mh_key, mh.mo_ta, v.bang, v.ten_tp, f.ch_key
OPTION (MAXDOP 1, MAX_GRANT_PERCENT = 0);
GO

-- [89] olap_ds_thang_mh_loai_kh (3D)
SELECT t.nam AS nam,
       t.quy AS quy,
       t.thang AS thang,
       f.mh_key AS mh_key,
       mh.mo_ta AS mo_ta,
       kh.loai_kh AS loai_kh,
       SUM(f.so_luong) AS tong_so_luong,
       SUM(f.doanh_thu) AS tong_doanh_thu
INTO dbo.[olap_ds_thang_mh_loai_kh]
FROM DW_Core.dbo.Fact_BanHang f
JOIN DW_Core.dbo.Dim_Ngay n ON n.ngay_key = f.ngay_key
JOIN DW_Core.dbo.Dim_ThoiGian t ON t.time_key = n.time_key
JOIN DW_Core.dbo.Dim_KhachHang kh ON kh.kh_key = f.kh_key
JOIN DW_Core.dbo.Dim_MatHang mh ON mh.mh_key = f.mh_key
GROUP BY t.nam, t.quy, t.thang, f.mh_key, mh.mo_ta, kh.loai_kh
OPTION (MAXDOP 1, MAX_GRANT_PERCENT = 0);
GO

-- [90] olap_ds_thang_mh_loai_kh_tinh (4D)
SELECT t.nam AS nam,
       t.quy AS quy,
       t.thang AS thang,
       f.mh_key AS mh_key,
       mh.mo_ta AS mo_ta,
       kh.loai_kh AS loai_kh,
       v.bang AS bang,
       SUM(f.so_luong) AS tong_so_luong,
       SUM(f.doanh_thu) AS tong_doanh_thu
INTO dbo.[olap_ds_thang_mh_loai_kh_tinh]
FROM DW_Core.dbo.Fact_BanHang f
JOIN DW_Core.dbo.Dim_Ngay n ON n.ngay_key = f.ngay_key
JOIN DW_Core.dbo.Dim_ThoiGian t ON t.time_key = n.time_key
JOIN DW_Core.dbo.Dim_KhachHang kh ON kh.kh_key = f.kh_key
JOIN DW_Core.dbo.Dim_MatHang mh ON mh.mh_key = f.mh_key
JOIN DW_Core.dbo.Dim_CuaHang ch ON ch.ch_key = f.ch_key
JOIN DW_Core.dbo.Dim_VPDD v ON v.vp_key = ch.vp_key
GROUP BY t.nam, t.quy, t.thang, f.mh_key, mh.mo_ta, kh.loai_kh, v.bang
OPTION (MAXDOP 1, MAX_GRANT_PERCENT = 0);
GO

-- [91] olap_ds_thang_mh_loai_kh_tp (4D)
SELECT t.nam AS nam,
       t.quy AS quy,
       t.thang AS thang,
       f.mh_key AS mh_key,
       mh.mo_ta AS mo_ta,
       kh.loai_kh AS loai_kh,
       v.bang AS bang,
       v.ten_tp AS ten_tp,
       SUM(f.so_luong) AS tong_so_luong,
       SUM(f.doanh_thu) AS tong_doanh_thu
INTO dbo.[olap_ds_thang_mh_loai_kh_tp]
FROM DW_Core.dbo.Fact_BanHang f
JOIN DW_Core.dbo.Dim_Ngay n ON n.ngay_key = f.ngay_key
JOIN DW_Core.dbo.Dim_ThoiGian t ON t.time_key = n.time_key
JOIN DW_Core.dbo.Dim_KhachHang kh ON kh.kh_key = f.kh_key
JOIN DW_Core.dbo.Dim_MatHang mh ON mh.mh_key = f.mh_key
JOIN DW_Core.dbo.Dim_CuaHang ch ON ch.ch_key = f.ch_key
JOIN DW_Core.dbo.Dim_VPDD v ON v.vp_key = ch.vp_key
GROUP BY t.nam, t.quy, t.thang, f.mh_key, mh.mo_ta, kh.loai_kh, v.bang, v.ten_tp
OPTION (MAXDOP 1, MAX_GRANT_PERCENT = 0);
GO

-- [92] olap_ds_thang_mh_loai_kh_ch (4D)
SELECT t.nam AS nam,
       t.quy AS quy,
       t.thang AS thang,
       f.mh_key AS mh_key,
       mh.mo_ta AS mo_ta,
       kh.loai_kh AS loai_kh,
       v.bang AS bang,
       v.ten_tp AS ten_tp,
       f.ch_key AS ch_key,
       SUM(f.so_luong) AS tong_so_luong,
       SUM(f.doanh_thu) AS tong_doanh_thu
INTO dbo.[olap_ds_thang_mh_loai_kh_ch]
FROM DW_Core.dbo.Fact_BanHang f
JOIN DW_Core.dbo.Dim_Ngay n ON n.ngay_key = f.ngay_key
JOIN DW_Core.dbo.Dim_ThoiGian t ON t.time_key = n.time_key
JOIN DW_Core.dbo.Dim_KhachHang kh ON kh.kh_key = f.kh_key
JOIN DW_Core.dbo.Dim_MatHang mh ON mh.mh_key = f.mh_key
JOIN DW_Core.dbo.Dim_CuaHang ch ON ch.ch_key = f.ch_key
JOIN DW_Core.dbo.Dim_VPDD v ON v.vp_key = ch.vp_key
GROUP BY t.nam, t.quy, t.thang, f.mh_key, mh.mo_ta, kh.loai_kh, v.bang, v.ten_tp, f.ch_key
OPTION (MAXDOP 1, MAX_GRANT_PERCENT = 0);
GO

-- [93] olap_ds_thang_mh_kh (3D)
SELECT t.nam AS nam,
       t.quy AS quy,
       t.thang AS thang,
       f.mh_key AS mh_key,
       mh.mo_ta AS mo_ta,
       f.kh_key AS kh_key,
       kh.ten AS ten,
       kh.loai_kh AS loai_kh,
       SUM(f.so_luong) AS tong_so_luong,
       SUM(f.doanh_thu) AS tong_doanh_thu
INTO dbo.[olap_ds_thang_mh_kh]
FROM DW_Core.dbo.Fact_BanHang f
JOIN DW_Core.dbo.Dim_Ngay n ON n.ngay_key = f.ngay_key
JOIN DW_Core.dbo.Dim_ThoiGian t ON t.time_key = n.time_key
JOIN DW_Core.dbo.Dim_KhachHang kh ON kh.kh_key = f.kh_key
JOIN DW_Core.dbo.Dim_MatHang mh ON mh.mh_key = f.mh_key
GROUP BY t.nam, t.quy, t.thang, f.mh_key, mh.mo_ta, f.kh_key, kh.ten, kh.loai_kh
OPTION (MAXDOP 1, MAX_GRANT_PERCENT = 0);
GO

-- [94] olap_ds_thang_mh_kh_tinh (4D)
SELECT t.nam AS nam,
       t.quy AS quy,
       t.thang AS thang,
       f.mh_key AS mh_key,
       mh.mo_ta AS mo_ta,
       f.kh_key AS kh_key,
       kh.ten AS ten,
       kh.loai_kh AS loai_kh,
       v.bang AS bang,
       SUM(f.so_luong) AS tong_so_luong,
       SUM(f.doanh_thu) AS tong_doanh_thu
INTO dbo.[olap_ds_thang_mh_kh_tinh]
FROM DW_Core.dbo.Fact_BanHang f
JOIN DW_Core.dbo.Dim_Ngay n ON n.ngay_key = f.ngay_key
JOIN DW_Core.dbo.Dim_ThoiGian t ON t.time_key = n.time_key
JOIN DW_Core.dbo.Dim_KhachHang kh ON kh.kh_key = f.kh_key
JOIN DW_Core.dbo.Dim_MatHang mh ON mh.mh_key = f.mh_key
JOIN DW_Core.dbo.Dim_CuaHang ch ON ch.ch_key = f.ch_key
JOIN DW_Core.dbo.Dim_VPDD v ON v.vp_key = ch.vp_key
GROUP BY t.nam, t.quy, t.thang, f.mh_key, mh.mo_ta, f.kh_key, kh.ten, kh.loai_kh, v.bang
OPTION (MAXDOP 1, MAX_GRANT_PERCENT = 0);
GO

-- [95] olap_ds_thang_mh_kh_tp (4D)
SELECT t.nam AS nam,
       t.quy AS quy,
       t.thang AS thang,
       f.mh_key AS mh_key,
       mh.mo_ta AS mo_ta,
       f.kh_key AS kh_key,
       kh.ten AS ten,
       kh.loai_kh AS loai_kh,
       v.bang AS bang,
       v.ten_tp AS ten_tp,
       SUM(f.so_luong) AS tong_so_luong,
       SUM(f.doanh_thu) AS tong_doanh_thu
INTO dbo.[olap_ds_thang_mh_kh_tp]
FROM DW_Core.dbo.Fact_BanHang f
JOIN DW_Core.dbo.Dim_Ngay n ON n.ngay_key = f.ngay_key
JOIN DW_Core.dbo.Dim_ThoiGian t ON t.time_key = n.time_key
JOIN DW_Core.dbo.Dim_KhachHang kh ON kh.kh_key = f.kh_key
JOIN DW_Core.dbo.Dim_MatHang mh ON mh.mh_key = f.mh_key
JOIN DW_Core.dbo.Dim_CuaHang ch ON ch.ch_key = f.ch_key
JOIN DW_Core.dbo.Dim_VPDD v ON v.vp_key = ch.vp_key
GROUP BY t.nam, t.quy, t.thang, f.mh_key, mh.mo_ta, f.kh_key, kh.ten, kh.loai_kh, v.bang, v.ten_tp
OPTION (MAXDOP 1, MAX_GRANT_PERCENT = 0);
GO

-- [96] olap_ds_thang_mh_kh_ch (4D)
SELECT t.nam AS nam,
       t.quy AS quy,
       t.thang AS thang,
       f.mh_key AS mh_key,
       mh.mo_ta AS mo_ta,
       f.kh_key AS kh_key,
       kh.ten AS ten,
       kh.loai_kh AS loai_kh,
       v.bang AS bang,
       v.ten_tp AS ten_tp,
       f.ch_key AS ch_key,
       SUM(f.so_luong) AS tong_so_luong,
       SUM(f.doanh_thu) AS tong_doanh_thu
INTO dbo.[olap_ds_thang_mh_kh_ch]
FROM DW_Core.dbo.Fact_BanHang f
JOIN DW_Core.dbo.Dim_Ngay n ON n.ngay_key = f.ngay_key
JOIN DW_Core.dbo.Dim_ThoiGian t ON t.time_key = n.time_key
JOIN DW_Core.dbo.Dim_KhachHang kh ON kh.kh_key = f.kh_key
JOIN DW_Core.dbo.Dim_MatHang mh ON mh.mh_key = f.mh_key
JOIN DW_Core.dbo.Dim_CuaHang ch ON ch.ch_key = f.ch_key
JOIN DW_Core.dbo.Dim_VPDD v ON v.vp_key = ch.vp_key
GROUP BY t.nam, t.quy, t.thang, f.mh_key, mh.mo_ta, f.kh_key, kh.ten, kh.loai_kh, v.bang, v.ten_tp, f.ch_key
OPTION (MAXDOP 1, MAX_GRANT_PERCENT = 0);
GO

-- [97] olap_ds_ngay (1D)
SELECT t.nam AS nam,
       t.quy AS quy,
       t.thang AS thang,
       n.ngay AS ngay,
       SUM(f.so_luong) AS tong_so_luong,
       SUM(f.doanh_thu) AS tong_doanh_thu
INTO dbo.[olap_ds_ngay]
FROM DW_Core.dbo.Fact_BanHang f
JOIN DW_Core.dbo.Dim_Ngay n ON n.ngay_key = f.ngay_key
JOIN DW_Core.dbo.Dim_ThoiGian t ON t.time_key = n.time_key
GROUP BY t.nam, t.quy, t.thang, n.ngay
OPTION (MAXDOP 1, MAX_GRANT_PERCENT = 0);
GO

-- [98] olap_ds_ngay_tinh (2D)
SELECT t.nam AS nam,
       t.quy AS quy,
       t.thang AS thang,
       n.ngay AS ngay,
       v.bang AS bang,
       SUM(f.so_luong) AS tong_so_luong,
       SUM(f.doanh_thu) AS tong_doanh_thu
INTO dbo.[olap_ds_ngay_tinh]
FROM DW_Core.dbo.Fact_BanHang f
JOIN DW_Core.dbo.Dim_Ngay n ON n.ngay_key = f.ngay_key
JOIN DW_Core.dbo.Dim_ThoiGian t ON t.time_key = n.time_key
JOIN DW_Core.dbo.Dim_CuaHang ch ON ch.ch_key = f.ch_key
JOIN DW_Core.dbo.Dim_VPDD v ON v.vp_key = ch.vp_key
GROUP BY t.nam, t.quy, t.thang, n.ngay, v.bang
OPTION (MAXDOP 1, MAX_GRANT_PERCENT = 0);
GO

-- [99] olap_ds_ngay_tp (2D)
SELECT t.nam AS nam,
       t.quy AS quy,
       t.thang AS thang,
       n.ngay AS ngay,
       v.bang AS bang,
       v.ten_tp AS ten_tp,
       SUM(f.so_luong) AS tong_so_luong,
       SUM(f.doanh_thu) AS tong_doanh_thu
INTO dbo.[olap_ds_ngay_tp]
FROM DW_Core.dbo.Fact_BanHang f
JOIN DW_Core.dbo.Dim_Ngay n ON n.ngay_key = f.ngay_key
JOIN DW_Core.dbo.Dim_ThoiGian t ON t.time_key = n.time_key
JOIN DW_Core.dbo.Dim_CuaHang ch ON ch.ch_key = f.ch_key
JOIN DW_Core.dbo.Dim_VPDD v ON v.vp_key = ch.vp_key
GROUP BY t.nam, t.quy, t.thang, n.ngay, v.bang, v.ten_tp
OPTION (MAXDOP 1, MAX_GRANT_PERCENT = 0);
GO

-- [100] olap_ds_ngay_ch (2D)
SELECT t.nam AS nam,
       t.quy AS quy,
       t.thang AS thang,
       n.ngay AS ngay,
       v.bang AS bang,
       v.ten_tp AS ten_tp,
       f.ch_key AS ch_key,
       SUM(f.so_luong) AS tong_so_luong,
       SUM(f.doanh_thu) AS tong_doanh_thu
INTO dbo.[olap_ds_ngay_ch]
FROM DW_Core.dbo.Fact_BanHang f
JOIN DW_Core.dbo.Dim_Ngay n ON n.ngay_key = f.ngay_key
JOIN DW_Core.dbo.Dim_ThoiGian t ON t.time_key = n.time_key
JOIN DW_Core.dbo.Dim_CuaHang ch ON ch.ch_key = f.ch_key
JOIN DW_Core.dbo.Dim_VPDD v ON v.vp_key = ch.vp_key
GROUP BY t.nam, t.quy, t.thang, n.ngay, v.bang, v.ten_tp, f.ch_key
OPTION (MAXDOP 1, MAX_GRANT_PERCENT = 0);
GO

-- [101] olap_ds_ngay_loai_kh (2D)
SELECT t.nam AS nam,
       t.quy AS quy,
       t.thang AS thang,
       n.ngay AS ngay,
       kh.loai_kh AS loai_kh,
       SUM(f.so_luong) AS tong_so_luong,
       SUM(f.doanh_thu) AS tong_doanh_thu
INTO dbo.[olap_ds_ngay_loai_kh]
FROM DW_Core.dbo.Fact_BanHang f
JOIN DW_Core.dbo.Dim_Ngay n ON n.ngay_key = f.ngay_key
JOIN DW_Core.dbo.Dim_ThoiGian t ON t.time_key = n.time_key
JOIN DW_Core.dbo.Dim_KhachHang kh ON kh.kh_key = f.kh_key
GROUP BY t.nam, t.quy, t.thang, n.ngay, kh.loai_kh
OPTION (MAXDOP 1, MAX_GRANT_PERCENT = 0);
GO

-- [102] olap_ds_ngay_loai_kh_tinh (3D)
SELECT t.nam AS nam,
       t.quy AS quy,
       t.thang AS thang,
       n.ngay AS ngay,
       kh.loai_kh AS loai_kh,
       v.bang AS bang,
       SUM(f.so_luong) AS tong_so_luong,
       SUM(f.doanh_thu) AS tong_doanh_thu
INTO dbo.[olap_ds_ngay_loai_kh_tinh]
FROM DW_Core.dbo.Fact_BanHang f
JOIN DW_Core.dbo.Dim_Ngay n ON n.ngay_key = f.ngay_key
JOIN DW_Core.dbo.Dim_ThoiGian t ON t.time_key = n.time_key
JOIN DW_Core.dbo.Dim_KhachHang kh ON kh.kh_key = f.kh_key
JOIN DW_Core.dbo.Dim_CuaHang ch ON ch.ch_key = f.ch_key
JOIN DW_Core.dbo.Dim_VPDD v ON v.vp_key = ch.vp_key
GROUP BY t.nam, t.quy, t.thang, n.ngay, kh.loai_kh, v.bang
OPTION (MAXDOP 1, MAX_GRANT_PERCENT = 0);
GO

-- [103] olap_ds_ngay_loai_kh_tp (3D)
SELECT t.nam AS nam,
       t.quy AS quy,
       t.thang AS thang,
       n.ngay AS ngay,
       kh.loai_kh AS loai_kh,
       v.bang AS bang,
       v.ten_tp AS ten_tp,
       SUM(f.so_luong) AS tong_so_luong,
       SUM(f.doanh_thu) AS tong_doanh_thu
INTO dbo.[olap_ds_ngay_loai_kh_tp]
FROM DW_Core.dbo.Fact_BanHang f
JOIN DW_Core.dbo.Dim_Ngay n ON n.ngay_key = f.ngay_key
JOIN DW_Core.dbo.Dim_ThoiGian t ON t.time_key = n.time_key
JOIN DW_Core.dbo.Dim_KhachHang kh ON kh.kh_key = f.kh_key
JOIN DW_Core.dbo.Dim_CuaHang ch ON ch.ch_key = f.ch_key
JOIN DW_Core.dbo.Dim_VPDD v ON v.vp_key = ch.vp_key
GROUP BY t.nam, t.quy, t.thang, n.ngay, kh.loai_kh, v.bang, v.ten_tp
OPTION (MAXDOP 1, MAX_GRANT_PERCENT = 0);
GO

-- [104] olap_ds_ngay_loai_kh_ch (3D)
SELECT t.nam AS nam,
       t.quy AS quy,
       t.thang AS thang,
       n.ngay AS ngay,
       kh.loai_kh AS loai_kh,
       v.bang AS bang,
       v.ten_tp AS ten_tp,
       f.ch_key AS ch_key,
       SUM(f.so_luong) AS tong_so_luong,
       SUM(f.doanh_thu) AS tong_doanh_thu
INTO dbo.[olap_ds_ngay_loai_kh_ch]
FROM DW_Core.dbo.Fact_BanHang f
JOIN DW_Core.dbo.Dim_Ngay n ON n.ngay_key = f.ngay_key
JOIN DW_Core.dbo.Dim_ThoiGian t ON t.time_key = n.time_key
JOIN DW_Core.dbo.Dim_KhachHang kh ON kh.kh_key = f.kh_key
JOIN DW_Core.dbo.Dim_CuaHang ch ON ch.ch_key = f.ch_key
JOIN DW_Core.dbo.Dim_VPDD v ON v.vp_key = ch.vp_key
GROUP BY t.nam, t.quy, t.thang, n.ngay, kh.loai_kh, v.bang, v.ten_tp, f.ch_key
OPTION (MAXDOP 1, MAX_GRANT_PERCENT = 0);
GO

-- [105] olap_ds_ngay_kh (2D)
SELECT t.nam AS nam,
       t.quy AS quy,
       t.thang AS thang,
       n.ngay AS ngay,
       f.kh_key AS kh_key,
       kh.ten AS ten,
       kh.loai_kh AS loai_kh,
       SUM(f.so_luong) AS tong_so_luong,
       SUM(f.doanh_thu) AS tong_doanh_thu
INTO dbo.[olap_ds_ngay_kh]
FROM DW_Core.dbo.Fact_BanHang f
JOIN DW_Core.dbo.Dim_Ngay n ON n.ngay_key = f.ngay_key
JOIN DW_Core.dbo.Dim_ThoiGian t ON t.time_key = n.time_key
JOIN DW_Core.dbo.Dim_KhachHang kh ON kh.kh_key = f.kh_key
GROUP BY t.nam, t.quy, t.thang, n.ngay, f.kh_key, kh.ten, kh.loai_kh
OPTION (MAXDOP 1, MAX_GRANT_PERCENT = 0);
GO

-- [106] olap_ds_ngay_kh_tinh (3D)
SELECT t.nam AS nam,
       t.quy AS quy,
       t.thang AS thang,
       n.ngay AS ngay,
       f.kh_key AS kh_key,
       kh.ten AS ten,
       kh.loai_kh AS loai_kh,
       v.bang AS bang,
       SUM(f.so_luong) AS tong_so_luong,
       SUM(f.doanh_thu) AS tong_doanh_thu
INTO dbo.[olap_ds_ngay_kh_tinh]
FROM DW_Core.dbo.Fact_BanHang f
JOIN DW_Core.dbo.Dim_Ngay n ON n.ngay_key = f.ngay_key
JOIN DW_Core.dbo.Dim_ThoiGian t ON t.time_key = n.time_key
JOIN DW_Core.dbo.Dim_KhachHang kh ON kh.kh_key = f.kh_key
JOIN DW_Core.dbo.Dim_CuaHang ch ON ch.ch_key = f.ch_key
JOIN DW_Core.dbo.Dim_VPDD v ON v.vp_key = ch.vp_key
GROUP BY t.nam, t.quy, t.thang, n.ngay, f.kh_key, kh.ten, kh.loai_kh, v.bang
OPTION (MAXDOP 1, MAX_GRANT_PERCENT = 0);
GO

-- [107] olap_ds_ngay_kh_tp (3D)
SELECT t.nam AS nam,
       t.quy AS quy,
       t.thang AS thang,
       n.ngay AS ngay,
       f.kh_key AS kh_key,
       kh.ten AS ten,
       kh.loai_kh AS loai_kh,
       v.bang AS bang,
       v.ten_tp AS ten_tp,
       SUM(f.so_luong) AS tong_so_luong,
       SUM(f.doanh_thu) AS tong_doanh_thu
INTO dbo.[olap_ds_ngay_kh_tp]
FROM DW_Core.dbo.Fact_BanHang f
JOIN DW_Core.dbo.Dim_Ngay n ON n.ngay_key = f.ngay_key
JOIN DW_Core.dbo.Dim_ThoiGian t ON t.time_key = n.time_key
JOIN DW_Core.dbo.Dim_KhachHang kh ON kh.kh_key = f.kh_key
JOIN DW_Core.dbo.Dim_CuaHang ch ON ch.ch_key = f.ch_key
JOIN DW_Core.dbo.Dim_VPDD v ON v.vp_key = ch.vp_key
GROUP BY t.nam, t.quy, t.thang, n.ngay, f.kh_key, kh.ten, kh.loai_kh, v.bang, v.ten_tp
OPTION (MAXDOP 1, MAX_GRANT_PERCENT = 0);
GO

-- [108] olap_ds_ngay_kh_ch (3D)
SELECT t.nam AS nam,
       t.quy AS quy,
       t.thang AS thang,
       n.ngay AS ngay,
       f.kh_key AS kh_key,
       kh.ten AS ten,
       kh.loai_kh AS loai_kh,
       v.bang AS bang,
       v.ten_tp AS ten_tp,
       f.ch_key AS ch_key,
       SUM(f.so_luong) AS tong_so_luong,
       SUM(f.doanh_thu) AS tong_doanh_thu
INTO dbo.[olap_ds_ngay_kh_ch]
FROM DW_Core.dbo.Fact_BanHang f
JOIN DW_Core.dbo.Dim_Ngay n ON n.ngay_key = f.ngay_key
JOIN DW_Core.dbo.Dim_ThoiGian t ON t.time_key = n.time_key
JOIN DW_Core.dbo.Dim_KhachHang kh ON kh.kh_key = f.kh_key
JOIN DW_Core.dbo.Dim_CuaHang ch ON ch.ch_key = f.ch_key
JOIN DW_Core.dbo.Dim_VPDD v ON v.vp_key = ch.vp_key
GROUP BY t.nam, t.quy, t.thang, n.ngay, f.kh_key, kh.ten, kh.loai_kh, v.bang, v.ten_tp, f.ch_key
OPTION (MAXDOP 1, MAX_GRANT_PERCENT = 0);
GO

-- [109] olap_ds_ngay_mh (2D)
SELECT t.nam AS nam,
       t.quy AS quy,
       t.thang AS thang,
       n.ngay AS ngay,
       f.mh_key AS mh_key,
       mh.mo_ta AS mo_ta,
       SUM(f.so_luong) AS tong_so_luong,
       SUM(f.doanh_thu) AS tong_doanh_thu
INTO dbo.[olap_ds_ngay_mh]
FROM DW_Core.dbo.Fact_BanHang f
JOIN DW_Core.dbo.Dim_Ngay n ON n.ngay_key = f.ngay_key
JOIN DW_Core.dbo.Dim_ThoiGian t ON t.time_key = n.time_key
JOIN DW_Core.dbo.Dim_MatHang mh ON mh.mh_key = f.mh_key
GROUP BY t.nam, t.quy, t.thang, n.ngay, f.mh_key, mh.mo_ta
OPTION (MAXDOP 1, MAX_GRANT_PERCENT = 0);
GO

-- [110] olap_ds_ngay_mh_tinh (3D)
SELECT t.nam AS nam,
       t.quy AS quy,
       t.thang AS thang,
       n.ngay AS ngay,
       f.mh_key AS mh_key,
       mh.mo_ta AS mo_ta,
       v.bang AS bang,
       SUM(f.so_luong) AS tong_so_luong,
       SUM(f.doanh_thu) AS tong_doanh_thu
INTO dbo.[olap_ds_ngay_mh_tinh]
FROM DW_Core.dbo.Fact_BanHang f
JOIN DW_Core.dbo.Dim_Ngay n ON n.ngay_key = f.ngay_key
JOIN DW_Core.dbo.Dim_ThoiGian t ON t.time_key = n.time_key
JOIN DW_Core.dbo.Dim_MatHang mh ON mh.mh_key = f.mh_key
JOIN DW_Core.dbo.Dim_CuaHang ch ON ch.ch_key = f.ch_key
JOIN DW_Core.dbo.Dim_VPDD v ON v.vp_key = ch.vp_key
GROUP BY t.nam, t.quy, t.thang, n.ngay, f.mh_key, mh.mo_ta, v.bang
OPTION (MAXDOP 1, MAX_GRANT_PERCENT = 0);
GO

-- [111] olap_ds_ngay_mh_tp (3D)
SELECT t.nam AS nam,
       t.quy AS quy,
       t.thang AS thang,
       n.ngay AS ngay,
       f.mh_key AS mh_key,
       mh.mo_ta AS mo_ta,
       v.bang AS bang,
       v.ten_tp AS ten_tp,
       SUM(f.so_luong) AS tong_so_luong,
       SUM(f.doanh_thu) AS tong_doanh_thu
INTO dbo.[olap_ds_ngay_mh_tp]
FROM DW_Core.dbo.Fact_BanHang f
JOIN DW_Core.dbo.Dim_Ngay n ON n.ngay_key = f.ngay_key
JOIN DW_Core.dbo.Dim_ThoiGian t ON t.time_key = n.time_key
JOIN DW_Core.dbo.Dim_MatHang mh ON mh.mh_key = f.mh_key
JOIN DW_Core.dbo.Dim_CuaHang ch ON ch.ch_key = f.ch_key
JOIN DW_Core.dbo.Dim_VPDD v ON v.vp_key = ch.vp_key
GROUP BY t.nam, t.quy, t.thang, n.ngay, f.mh_key, mh.mo_ta, v.bang, v.ten_tp
OPTION (MAXDOP 1, MAX_GRANT_PERCENT = 0);
GO

-- [112] olap_ds_ngay_mh_ch (3D)
SELECT t.nam AS nam,
       t.quy AS quy,
       t.thang AS thang,
       n.ngay AS ngay,
       f.mh_key AS mh_key,
       mh.mo_ta AS mo_ta,
       v.bang AS bang,
       v.ten_tp AS ten_tp,
       f.ch_key AS ch_key,
       SUM(f.so_luong) AS tong_so_luong,
       SUM(f.doanh_thu) AS tong_doanh_thu
INTO dbo.[olap_ds_ngay_mh_ch]
FROM DW_Core.dbo.Fact_BanHang f
JOIN DW_Core.dbo.Dim_Ngay n ON n.ngay_key = f.ngay_key
JOIN DW_Core.dbo.Dim_ThoiGian t ON t.time_key = n.time_key
JOIN DW_Core.dbo.Dim_MatHang mh ON mh.mh_key = f.mh_key
JOIN DW_Core.dbo.Dim_CuaHang ch ON ch.ch_key = f.ch_key
JOIN DW_Core.dbo.Dim_VPDD v ON v.vp_key = ch.vp_key
GROUP BY t.nam, t.quy, t.thang, n.ngay, f.mh_key, mh.mo_ta, v.bang, v.ten_tp, f.ch_key
OPTION (MAXDOP 1, MAX_GRANT_PERCENT = 0);
GO

-- [113] olap_ds_ngay_mh_loai_kh (3D)
SELECT t.nam AS nam,
       t.quy AS quy,
       t.thang AS thang,
       n.ngay AS ngay,
       f.mh_key AS mh_key,
       mh.mo_ta AS mo_ta,
       kh.loai_kh AS loai_kh,
       SUM(f.so_luong) AS tong_so_luong,
       SUM(f.doanh_thu) AS tong_doanh_thu
INTO dbo.[olap_ds_ngay_mh_loai_kh]
FROM DW_Core.dbo.Fact_BanHang f
JOIN DW_Core.dbo.Dim_Ngay n ON n.ngay_key = f.ngay_key
JOIN DW_Core.dbo.Dim_ThoiGian t ON t.time_key = n.time_key
JOIN DW_Core.dbo.Dim_KhachHang kh ON kh.kh_key = f.kh_key
JOIN DW_Core.dbo.Dim_MatHang mh ON mh.mh_key = f.mh_key
GROUP BY t.nam, t.quy, t.thang, n.ngay, f.mh_key, mh.mo_ta, kh.loai_kh
OPTION (MAXDOP 1, MAX_GRANT_PERCENT = 0);
GO

-- [114] olap_ds_ngay_mh_loai_kh_tinh (4D)
SELECT t.nam AS nam,
       t.quy AS quy,
       t.thang AS thang,
       n.ngay AS ngay,
       f.mh_key AS mh_key,
       mh.mo_ta AS mo_ta,
       kh.loai_kh AS loai_kh,
       v.bang AS bang,
       SUM(f.so_luong) AS tong_so_luong,
       SUM(f.doanh_thu) AS tong_doanh_thu
INTO dbo.[olap_ds_ngay_mh_loai_kh_tinh]
FROM DW_Core.dbo.Fact_BanHang f
JOIN DW_Core.dbo.Dim_Ngay n ON n.ngay_key = f.ngay_key
JOIN DW_Core.dbo.Dim_ThoiGian t ON t.time_key = n.time_key
JOIN DW_Core.dbo.Dim_KhachHang kh ON kh.kh_key = f.kh_key
JOIN DW_Core.dbo.Dim_MatHang mh ON mh.mh_key = f.mh_key
JOIN DW_Core.dbo.Dim_CuaHang ch ON ch.ch_key = f.ch_key
JOIN DW_Core.dbo.Dim_VPDD v ON v.vp_key = ch.vp_key
GROUP BY t.nam, t.quy, t.thang, n.ngay, f.mh_key, mh.mo_ta, kh.loai_kh, v.bang
OPTION (MAXDOP 1, MAX_GRANT_PERCENT = 0);
GO

-- [115] olap_ds_ngay_mh_loai_kh_tp (4D)
SELECT t.nam AS nam,
       t.quy AS quy,
       t.thang AS thang,
       n.ngay AS ngay,
       f.mh_key AS mh_key,
       mh.mo_ta AS mo_ta,
       kh.loai_kh AS loai_kh,
       v.bang AS bang,
       v.ten_tp AS ten_tp,
       SUM(f.so_luong) AS tong_so_luong,
       SUM(f.doanh_thu) AS tong_doanh_thu
INTO dbo.[olap_ds_ngay_mh_loai_kh_tp]
FROM DW_Core.dbo.Fact_BanHang f
JOIN DW_Core.dbo.Dim_Ngay n ON n.ngay_key = f.ngay_key
JOIN DW_Core.dbo.Dim_ThoiGian t ON t.time_key = n.time_key
JOIN DW_Core.dbo.Dim_KhachHang kh ON kh.kh_key = f.kh_key
JOIN DW_Core.dbo.Dim_MatHang mh ON mh.mh_key = f.mh_key
JOIN DW_Core.dbo.Dim_CuaHang ch ON ch.ch_key = f.ch_key
JOIN DW_Core.dbo.Dim_VPDD v ON v.vp_key = ch.vp_key
GROUP BY t.nam, t.quy, t.thang, n.ngay, f.mh_key, mh.mo_ta, kh.loai_kh, v.bang, v.ten_tp
OPTION (MAXDOP 1, MAX_GRANT_PERCENT = 0);
GO

-- [116] olap_ds_ngay_mh_loai_kh_ch (4D)
SELECT t.nam AS nam,
       t.quy AS quy,
       t.thang AS thang,
       n.ngay AS ngay,
       f.mh_key AS mh_key,
       mh.mo_ta AS mo_ta,
       kh.loai_kh AS loai_kh,
       v.bang AS bang,
       v.ten_tp AS ten_tp,
       f.ch_key AS ch_key,
       SUM(f.so_luong) AS tong_so_luong,
       SUM(f.doanh_thu) AS tong_doanh_thu
INTO dbo.[olap_ds_ngay_mh_loai_kh_ch]
FROM DW_Core.dbo.Fact_BanHang f
JOIN DW_Core.dbo.Dim_Ngay n ON n.ngay_key = f.ngay_key
JOIN DW_Core.dbo.Dim_ThoiGian t ON t.time_key = n.time_key
JOIN DW_Core.dbo.Dim_KhachHang kh ON kh.kh_key = f.kh_key
JOIN DW_Core.dbo.Dim_MatHang mh ON mh.mh_key = f.mh_key
JOIN DW_Core.dbo.Dim_CuaHang ch ON ch.ch_key = f.ch_key
JOIN DW_Core.dbo.Dim_VPDD v ON v.vp_key = ch.vp_key
GROUP BY t.nam, t.quy, t.thang, n.ngay, f.mh_key, mh.mo_ta, kh.loai_kh, v.bang, v.ten_tp, f.ch_key
OPTION (MAXDOP 1, MAX_GRANT_PERCENT = 0);
GO

-- [117] olap_ds_ngay_mh_kh (3D)
SELECT t.nam AS nam,
       t.quy AS quy,
       t.thang AS thang,
       n.ngay AS ngay,
       f.mh_key AS mh_key,
       mh.mo_ta AS mo_ta,
       f.kh_key AS kh_key,
       kh.ten AS ten,
       kh.loai_kh AS loai_kh,
       SUM(f.so_luong) AS tong_so_luong,
       SUM(f.doanh_thu) AS tong_doanh_thu
INTO dbo.[olap_ds_ngay_mh_kh]
FROM DW_Core.dbo.Fact_BanHang f
JOIN DW_Core.dbo.Dim_Ngay n ON n.ngay_key = f.ngay_key
JOIN DW_Core.dbo.Dim_ThoiGian t ON t.time_key = n.time_key
JOIN DW_Core.dbo.Dim_KhachHang kh ON kh.kh_key = f.kh_key
JOIN DW_Core.dbo.Dim_MatHang mh ON mh.mh_key = f.mh_key
GROUP BY t.nam, t.quy, t.thang, n.ngay, f.mh_key, mh.mo_ta, f.kh_key, kh.ten, kh.loai_kh
OPTION (MAXDOP 1, MAX_GRANT_PERCENT = 0);
GO

-- [118] olap_ds_ngay_mh_kh_tinh (4D)
SELECT t.nam AS nam,
       t.quy AS quy,
       t.thang AS thang,
       n.ngay AS ngay,
       f.mh_key AS mh_key,
       mh.mo_ta AS mo_ta,
       f.kh_key AS kh_key,
       kh.ten AS ten,
       kh.loai_kh AS loai_kh,
       v.bang AS bang,
       SUM(f.so_luong) AS tong_so_luong,
       SUM(f.doanh_thu) AS tong_doanh_thu
INTO dbo.[olap_ds_ngay_mh_kh_tinh]
FROM DW_Core.dbo.Fact_BanHang f
JOIN DW_Core.dbo.Dim_Ngay n ON n.ngay_key = f.ngay_key
JOIN DW_Core.dbo.Dim_ThoiGian t ON t.time_key = n.time_key
JOIN DW_Core.dbo.Dim_KhachHang kh ON kh.kh_key = f.kh_key
JOIN DW_Core.dbo.Dim_MatHang mh ON mh.mh_key = f.mh_key
JOIN DW_Core.dbo.Dim_CuaHang ch ON ch.ch_key = f.ch_key
JOIN DW_Core.dbo.Dim_VPDD v ON v.vp_key = ch.vp_key
GROUP BY t.nam, t.quy, t.thang, n.ngay, f.mh_key, mh.mo_ta, f.kh_key, kh.ten, kh.loai_kh, v.bang
OPTION (MAXDOP 1, MAX_GRANT_PERCENT = 0);
GO

-- [119] olap_ds_ngay_mh_kh_tp (4D)
SELECT t.nam AS nam,
       t.quy AS quy,
       t.thang AS thang,
       n.ngay AS ngay,
       f.mh_key AS mh_key,
       mh.mo_ta AS mo_ta,
       f.kh_key AS kh_key,
       kh.ten AS ten,
       kh.loai_kh AS loai_kh,
       v.bang AS bang,
       v.ten_tp AS ten_tp,
       SUM(f.so_luong) AS tong_so_luong,
       SUM(f.doanh_thu) AS tong_doanh_thu
INTO dbo.[olap_ds_ngay_mh_kh_tp]
FROM DW_Core.dbo.Fact_BanHang f
JOIN DW_Core.dbo.Dim_Ngay n ON n.ngay_key = f.ngay_key
JOIN DW_Core.dbo.Dim_ThoiGian t ON t.time_key = n.time_key
JOIN DW_Core.dbo.Dim_KhachHang kh ON kh.kh_key = f.kh_key
JOIN DW_Core.dbo.Dim_MatHang mh ON mh.mh_key = f.mh_key
JOIN DW_Core.dbo.Dim_CuaHang ch ON ch.ch_key = f.ch_key
JOIN DW_Core.dbo.Dim_VPDD v ON v.vp_key = ch.vp_key
GROUP BY t.nam, t.quy, t.thang, n.ngay, f.mh_key, mh.mo_ta, f.kh_key, kh.ten, kh.loai_kh, v.bang, v.ten_tp
OPTION (MAXDOP 1, MAX_GRANT_PERCENT = 0);
GO

-- [120] olap_ds_ngay_mh_kh_ch (4D)
SELECT t.nam AS nam,
       t.quy AS quy,
       t.thang AS thang,
       n.ngay AS ngay,
       f.mh_key AS mh_key,
       mh.mo_ta AS mo_ta,
       f.kh_key AS kh_key,
       kh.ten AS ten,
       kh.loai_kh AS loai_kh,
       v.bang AS bang,
       v.ten_tp AS ten_tp,
       f.ch_key AS ch_key,
       SUM(f.so_luong) AS tong_so_luong,
       SUM(f.doanh_thu) AS tong_doanh_thu
INTO dbo.[olap_ds_ngay_mh_kh_ch]
FROM DW_Core.dbo.Fact_BanHang f
JOIN DW_Core.dbo.Dim_Ngay n ON n.ngay_key = f.ngay_key
JOIN DW_Core.dbo.Dim_ThoiGian t ON t.time_key = n.time_key
JOIN DW_Core.dbo.Dim_KhachHang kh ON kh.kh_key = f.kh_key
JOIN DW_Core.dbo.Dim_MatHang mh ON mh.mh_key = f.mh_key
JOIN DW_Core.dbo.Dim_CuaHang ch ON ch.ch_key = f.ch_key
JOIN DW_Core.dbo.Dim_VPDD v ON v.vp_key = ch.vp_key
GROUP BY t.nam, t.quy, t.thang, n.ngay, f.mh_key, mh.mo_ta, f.kh_key, kh.ten, kh.loai_kh, v.bang, v.ten_tp, f.ch_key
OPTION (MAXDOP 1, MAX_GRANT_PERCENT = 0);
GO

-- [121] olap_tk_all (0D)
WITH ranked AS (
    SELECT f.so_luong,
           ROW_NUMBER() OVER (PARTITION BY f.ch_key, f.mh_key ORDER BY f.time_key DESC) AS rn
    FROM DW_Core.dbo.Fact_Kho f
)
SELECT SUM(so_luong) AS tong_ton_kho
INTO dbo.[olap_tk_all]
FROM ranked WHERE rn = 1
OPTION (MAXDOP 1, MAX_GRANT_PERCENT = 0);
GO

-- [122] olap_tk_tinh (1D)
WITH ranked AS (
    SELECT v.bang AS bang,
           f.so_luong,
           ROW_NUMBER() OVER (PARTITION BY f.ch_key, f.mh_key ORDER BY f.time_key DESC) AS rn
    FROM DW_Core.dbo.Fact_Kho f
    JOIN DW_Core.dbo.Dim_CuaHang ch ON ch.ch_key = f.ch_key
    JOIN DW_Core.dbo.Dim_VPDD v ON v.vp_key = ch.vp_key
)
SELECT bang, SUM(so_luong) AS tong_ton_kho
INTO dbo.[olap_tk_tinh]
FROM ranked WHERE rn = 1
GROUP BY bang
OPTION (MAXDOP 1, MAX_GRANT_PERCENT = 0);
GO

-- [123] olap_tk_tp (1D)
WITH ranked AS (
    SELECT v.bang AS bang,
           v.ten_tp AS ten_tp,
           f.so_luong,
           ROW_NUMBER() OVER (PARTITION BY f.ch_key, f.mh_key ORDER BY f.time_key DESC) AS rn
    FROM DW_Core.dbo.Fact_Kho f
    JOIN DW_Core.dbo.Dim_CuaHang ch ON ch.ch_key = f.ch_key
    JOIN DW_Core.dbo.Dim_VPDD v ON v.vp_key = ch.vp_key
)
SELECT bang, ten_tp, SUM(so_luong) AS tong_ton_kho
INTO dbo.[olap_tk_tp]
FROM ranked WHERE rn = 1
GROUP BY bang, ten_tp
OPTION (MAXDOP 1, MAX_GRANT_PERCENT = 0);
GO

-- [124] olap_tk_ch (1D)
WITH ranked AS (
    SELECT v.bang AS bang,
           v.ten_tp AS ten_tp,
           f.ch_key AS ch_key,
           f.so_luong,
           ROW_NUMBER() OVER (PARTITION BY f.ch_key, f.mh_key ORDER BY f.time_key DESC) AS rn
    FROM DW_Core.dbo.Fact_Kho f
    JOIN DW_Core.dbo.Dim_CuaHang ch ON ch.ch_key = f.ch_key
    JOIN DW_Core.dbo.Dim_VPDD v ON v.vp_key = ch.vp_key
)
SELECT bang, ten_tp, ch_key, SUM(so_luong) AS tong_ton_kho
INTO dbo.[olap_tk_ch]
FROM ranked WHERE rn = 1
GROUP BY bang, ten_tp, ch_key
OPTION (MAXDOP 1, MAX_GRANT_PERCENT = 0);
GO

-- [125] olap_tk_mh (1D)
WITH ranked AS (
    SELECT f.mh_key AS mh_key,
           mh.mo_ta AS mo_ta,
           f.so_luong,
           ROW_NUMBER() OVER (PARTITION BY f.ch_key, f.mh_key ORDER BY f.time_key DESC) AS rn
    FROM DW_Core.dbo.Fact_Kho f
    JOIN DW_Core.dbo.Dim_MatHang mh ON mh.mh_key = f.mh_key
)
SELECT mh_key, mo_ta, SUM(so_luong) AS tong_ton_kho
INTO dbo.[olap_tk_mh]
FROM ranked WHERE rn = 1
GROUP BY mh_key, mo_ta
OPTION (MAXDOP 1, MAX_GRANT_PERCENT = 0);
GO

-- [126] olap_tk_mh_tinh (2D)
WITH ranked AS (
    SELECT f.mh_key AS mh_key,
           mh.mo_ta AS mo_ta,
           v.bang AS bang,
           f.so_luong,
           ROW_NUMBER() OVER (PARTITION BY f.ch_key, f.mh_key ORDER BY f.time_key DESC) AS rn
    FROM DW_Core.dbo.Fact_Kho f
    JOIN DW_Core.dbo.Dim_MatHang mh ON mh.mh_key = f.mh_key
    JOIN DW_Core.dbo.Dim_CuaHang ch ON ch.ch_key = f.ch_key
    JOIN DW_Core.dbo.Dim_VPDD v ON v.vp_key = ch.vp_key
)
SELECT mh_key, mo_ta, bang, SUM(so_luong) AS tong_ton_kho
INTO dbo.[olap_tk_mh_tinh]
FROM ranked WHERE rn = 1
GROUP BY mh_key, mo_ta, bang
OPTION (MAXDOP 1, MAX_GRANT_PERCENT = 0);
GO

-- [127] olap_tk_mh_tp (2D)
WITH ranked AS (
    SELECT f.mh_key AS mh_key,
           mh.mo_ta AS mo_ta,
           v.bang AS bang,
           v.ten_tp AS ten_tp,
           f.so_luong,
           ROW_NUMBER() OVER (PARTITION BY f.ch_key, f.mh_key ORDER BY f.time_key DESC) AS rn
    FROM DW_Core.dbo.Fact_Kho f
    JOIN DW_Core.dbo.Dim_MatHang mh ON mh.mh_key = f.mh_key
    JOIN DW_Core.dbo.Dim_CuaHang ch ON ch.ch_key = f.ch_key
    JOIN DW_Core.dbo.Dim_VPDD v ON v.vp_key = ch.vp_key
)
SELECT mh_key, mo_ta, bang, ten_tp, SUM(so_luong) AS tong_ton_kho
INTO dbo.[olap_tk_mh_tp]
FROM ranked WHERE rn = 1
GROUP BY mh_key, mo_ta, bang, ten_tp
OPTION (MAXDOP 1, MAX_GRANT_PERCENT = 0);
GO

-- [128] olap_tk_mh_ch (2D)
WITH ranked AS (
    SELECT f.mh_key AS mh_key,
           mh.mo_ta AS mo_ta,
           v.bang AS bang,
           v.ten_tp AS ten_tp,
           f.ch_key AS ch_key,
           f.so_luong,
           ROW_NUMBER() OVER (PARTITION BY f.ch_key, f.mh_key ORDER BY f.time_key DESC) AS rn
    FROM DW_Core.dbo.Fact_Kho f
    JOIN DW_Core.dbo.Dim_MatHang mh ON mh.mh_key = f.mh_key
    JOIN DW_Core.dbo.Dim_CuaHang ch ON ch.ch_key = f.ch_key
    JOIN DW_Core.dbo.Dim_VPDD v ON v.vp_key = ch.vp_key
)
SELECT mh_key, mo_ta, bang, ten_tp, ch_key, SUM(so_luong) AS tong_ton_kho
INTO dbo.[olap_tk_mh_ch]
FROM ranked WHERE rn = 1
GROUP BY mh_key, mo_ta, bang, ten_tp, ch_key
OPTION (MAXDOP 1, MAX_GRANT_PERCENT = 0);
GO

-- [129] olap_tk_nam (1D)
WITH ranked AS (
    SELECT t.nam AS nam,
           f.so_luong,
           ROW_NUMBER() OVER (PARTITION BY f.ch_key, f.mh_key, t.nam ORDER BY f.time_key DESC) AS rn
    FROM DW_Core.dbo.Fact_Kho f
    JOIN DW_Core.dbo.Dim_ThoiGian t ON t.time_key = f.time_key
)
SELECT nam, SUM(so_luong) AS tong_ton_kho
INTO dbo.[olap_tk_nam]
FROM ranked WHERE rn = 1
GROUP BY nam
OPTION (MAXDOP 1, MAX_GRANT_PERCENT = 0);
GO

-- [130] olap_tk_nam_tinh (2D)
WITH ranked AS (
    SELECT t.nam AS nam,
           v.bang AS bang,
           f.so_luong,
           ROW_NUMBER() OVER (PARTITION BY f.ch_key, f.mh_key, t.nam ORDER BY f.time_key DESC) AS rn
    FROM DW_Core.dbo.Fact_Kho f
    JOIN DW_Core.dbo.Dim_ThoiGian t ON t.time_key = f.time_key
    JOIN DW_Core.dbo.Dim_CuaHang ch ON ch.ch_key = f.ch_key
    JOIN DW_Core.dbo.Dim_VPDD v ON v.vp_key = ch.vp_key
)
SELECT nam, bang, SUM(so_luong) AS tong_ton_kho
INTO dbo.[olap_tk_nam_tinh]
FROM ranked WHERE rn = 1
GROUP BY nam, bang
OPTION (MAXDOP 1, MAX_GRANT_PERCENT = 0);
GO

-- [131] olap_tk_nam_tp (2D)
WITH ranked AS (
    SELECT t.nam AS nam,
           v.bang AS bang,
           v.ten_tp AS ten_tp,
           f.so_luong,
           ROW_NUMBER() OVER (PARTITION BY f.ch_key, f.mh_key, t.nam ORDER BY f.time_key DESC) AS rn
    FROM DW_Core.dbo.Fact_Kho f
    JOIN DW_Core.dbo.Dim_ThoiGian t ON t.time_key = f.time_key
    JOIN DW_Core.dbo.Dim_CuaHang ch ON ch.ch_key = f.ch_key
    JOIN DW_Core.dbo.Dim_VPDD v ON v.vp_key = ch.vp_key
)
SELECT nam, bang, ten_tp, SUM(so_luong) AS tong_ton_kho
INTO dbo.[olap_tk_nam_tp]
FROM ranked WHERE rn = 1
GROUP BY nam, bang, ten_tp
OPTION (MAXDOP 1, MAX_GRANT_PERCENT = 0);
GO

-- [132] olap_tk_nam_ch (2D)
WITH ranked AS (
    SELECT t.nam AS nam,
           v.bang AS bang,
           v.ten_tp AS ten_tp,
           f.ch_key AS ch_key,
           f.so_luong,
           ROW_NUMBER() OVER (PARTITION BY f.ch_key, f.mh_key, t.nam ORDER BY f.time_key DESC) AS rn
    FROM DW_Core.dbo.Fact_Kho f
    JOIN DW_Core.dbo.Dim_ThoiGian t ON t.time_key = f.time_key
    JOIN DW_Core.dbo.Dim_CuaHang ch ON ch.ch_key = f.ch_key
    JOIN DW_Core.dbo.Dim_VPDD v ON v.vp_key = ch.vp_key
)
SELECT nam, bang, ten_tp, ch_key, SUM(so_luong) AS tong_ton_kho
INTO dbo.[olap_tk_nam_ch]
FROM ranked WHERE rn = 1
GROUP BY nam, bang, ten_tp, ch_key
OPTION (MAXDOP 1, MAX_GRANT_PERCENT = 0);
GO

-- [133] olap_tk_nam_mh (2D)
WITH ranked AS (
    SELECT t.nam AS nam,
           f.mh_key AS mh_key,
           mh.mo_ta AS mo_ta,
           f.so_luong,
           ROW_NUMBER() OVER (PARTITION BY f.ch_key, f.mh_key, t.nam ORDER BY f.time_key DESC) AS rn
    FROM DW_Core.dbo.Fact_Kho f
    JOIN DW_Core.dbo.Dim_ThoiGian t ON t.time_key = f.time_key
    JOIN DW_Core.dbo.Dim_MatHang mh ON mh.mh_key = f.mh_key
)
SELECT nam, mh_key, mo_ta, SUM(so_luong) AS tong_ton_kho
INTO dbo.[olap_tk_nam_mh]
FROM ranked WHERE rn = 1
GROUP BY nam, mh_key, mo_ta
OPTION (MAXDOP 1, MAX_GRANT_PERCENT = 0);
GO

-- [134] olap_tk_nam_mh_tinh (3D)
WITH ranked AS (
    SELECT t.nam AS nam,
           f.mh_key AS mh_key,
           mh.mo_ta AS mo_ta,
           v.bang AS bang,
           f.so_luong,
           ROW_NUMBER() OVER (PARTITION BY f.ch_key, f.mh_key, t.nam ORDER BY f.time_key DESC) AS rn
    FROM DW_Core.dbo.Fact_Kho f
    JOIN DW_Core.dbo.Dim_ThoiGian t ON t.time_key = f.time_key
    JOIN DW_Core.dbo.Dim_MatHang mh ON mh.mh_key = f.mh_key
    JOIN DW_Core.dbo.Dim_CuaHang ch ON ch.ch_key = f.ch_key
    JOIN DW_Core.dbo.Dim_VPDD v ON v.vp_key = ch.vp_key
)
SELECT nam, mh_key, mo_ta, bang, SUM(so_luong) AS tong_ton_kho
INTO dbo.[olap_tk_nam_mh_tinh]
FROM ranked WHERE rn = 1
GROUP BY nam, mh_key, mo_ta, bang
OPTION (MAXDOP 1, MAX_GRANT_PERCENT = 0);
GO

-- [135] olap_tk_nam_mh_tp (3D)
WITH ranked AS (
    SELECT t.nam AS nam,
           f.mh_key AS mh_key,
           mh.mo_ta AS mo_ta,
           v.bang AS bang,
           v.ten_tp AS ten_tp,
           f.so_luong,
           ROW_NUMBER() OVER (PARTITION BY f.ch_key, f.mh_key, t.nam ORDER BY f.time_key DESC) AS rn
    FROM DW_Core.dbo.Fact_Kho f
    JOIN DW_Core.dbo.Dim_ThoiGian t ON t.time_key = f.time_key
    JOIN DW_Core.dbo.Dim_MatHang mh ON mh.mh_key = f.mh_key
    JOIN DW_Core.dbo.Dim_CuaHang ch ON ch.ch_key = f.ch_key
    JOIN DW_Core.dbo.Dim_VPDD v ON v.vp_key = ch.vp_key
)
SELECT nam, mh_key, mo_ta, bang, ten_tp, SUM(so_luong) AS tong_ton_kho
INTO dbo.[olap_tk_nam_mh_tp]
FROM ranked WHERE rn = 1
GROUP BY nam, mh_key, mo_ta, bang, ten_tp
OPTION (MAXDOP 1, MAX_GRANT_PERCENT = 0);
GO

-- [136] olap_tk_nam_mh_ch (3D)
WITH ranked AS (
    SELECT t.nam AS nam,
           f.mh_key AS mh_key,
           mh.mo_ta AS mo_ta,
           v.bang AS bang,
           v.ten_tp AS ten_tp,
           f.ch_key AS ch_key,
           f.so_luong,
           ROW_NUMBER() OVER (PARTITION BY f.ch_key, f.mh_key, t.nam ORDER BY f.time_key DESC) AS rn
    FROM DW_Core.dbo.Fact_Kho f
    JOIN DW_Core.dbo.Dim_ThoiGian t ON t.time_key = f.time_key
    JOIN DW_Core.dbo.Dim_MatHang mh ON mh.mh_key = f.mh_key
    JOIN DW_Core.dbo.Dim_CuaHang ch ON ch.ch_key = f.ch_key
    JOIN DW_Core.dbo.Dim_VPDD v ON v.vp_key = ch.vp_key
)
SELECT nam, mh_key, mo_ta, bang, ten_tp, ch_key, SUM(so_luong) AS tong_ton_kho
INTO dbo.[olap_tk_nam_mh_ch]
FROM ranked WHERE rn = 1
GROUP BY nam, mh_key, mo_ta, bang, ten_tp, ch_key
OPTION (MAXDOP 1, MAX_GRANT_PERCENT = 0);
GO

-- [137] olap_tk_quy (1D)
WITH ranked AS (
    SELECT t.nam AS nam,
           t.quy AS quy,
           f.so_luong,
           ROW_NUMBER() OVER (PARTITION BY f.ch_key, f.mh_key, t.nam, t.quy ORDER BY f.time_key DESC) AS rn
    FROM DW_Core.dbo.Fact_Kho f
    JOIN DW_Core.dbo.Dim_ThoiGian t ON t.time_key = f.time_key
)
SELECT nam, quy, SUM(so_luong) AS tong_ton_kho
INTO dbo.[olap_tk_quy]
FROM ranked WHERE rn = 1
GROUP BY nam, quy
OPTION (MAXDOP 1, MAX_GRANT_PERCENT = 0);
GO

-- [138] olap_tk_quy_tinh (2D)
WITH ranked AS (
    SELECT t.nam AS nam,
           t.quy AS quy,
           v.bang AS bang,
           f.so_luong,
           ROW_NUMBER() OVER (PARTITION BY f.ch_key, f.mh_key, t.nam, t.quy ORDER BY f.time_key DESC) AS rn
    FROM DW_Core.dbo.Fact_Kho f
    JOIN DW_Core.dbo.Dim_ThoiGian t ON t.time_key = f.time_key
    JOIN DW_Core.dbo.Dim_CuaHang ch ON ch.ch_key = f.ch_key
    JOIN DW_Core.dbo.Dim_VPDD v ON v.vp_key = ch.vp_key
)
SELECT nam, quy, bang, SUM(so_luong) AS tong_ton_kho
INTO dbo.[olap_tk_quy_tinh]
FROM ranked WHERE rn = 1
GROUP BY nam, quy, bang
OPTION (MAXDOP 1, MAX_GRANT_PERCENT = 0);
GO

-- [139] olap_tk_quy_tp (2D)
WITH ranked AS (
    SELECT t.nam AS nam,
           t.quy AS quy,
           v.bang AS bang,
           v.ten_tp AS ten_tp,
           f.so_luong,
           ROW_NUMBER() OVER (PARTITION BY f.ch_key, f.mh_key, t.nam, t.quy ORDER BY f.time_key DESC) AS rn
    FROM DW_Core.dbo.Fact_Kho f
    JOIN DW_Core.dbo.Dim_ThoiGian t ON t.time_key = f.time_key
    JOIN DW_Core.dbo.Dim_CuaHang ch ON ch.ch_key = f.ch_key
    JOIN DW_Core.dbo.Dim_VPDD v ON v.vp_key = ch.vp_key
)
SELECT nam, quy, bang, ten_tp, SUM(so_luong) AS tong_ton_kho
INTO dbo.[olap_tk_quy_tp]
FROM ranked WHERE rn = 1
GROUP BY nam, quy, bang, ten_tp
OPTION (MAXDOP 1, MAX_GRANT_PERCENT = 0);
GO

-- [140] olap_tk_quy_ch (2D)
WITH ranked AS (
    SELECT t.nam AS nam,
           t.quy AS quy,
           v.bang AS bang,
           v.ten_tp AS ten_tp,
           f.ch_key AS ch_key,
           f.so_luong,
           ROW_NUMBER() OVER (PARTITION BY f.ch_key, f.mh_key, t.nam, t.quy ORDER BY f.time_key DESC) AS rn
    FROM DW_Core.dbo.Fact_Kho f
    JOIN DW_Core.dbo.Dim_ThoiGian t ON t.time_key = f.time_key
    JOIN DW_Core.dbo.Dim_CuaHang ch ON ch.ch_key = f.ch_key
    JOIN DW_Core.dbo.Dim_VPDD v ON v.vp_key = ch.vp_key
)
SELECT nam, quy, bang, ten_tp, ch_key, SUM(so_luong) AS tong_ton_kho
INTO dbo.[olap_tk_quy_ch]
FROM ranked WHERE rn = 1
GROUP BY nam, quy, bang, ten_tp, ch_key
OPTION (MAXDOP 1, MAX_GRANT_PERCENT = 0);
GO

-- [141] olap_tk_quy_mh (2D)
WITH ranked AS (
    SELECT t.nam AS nam,
           t.quy AS quy,
           f.mh_key AS mh_key,
           mh.mo_ta AS mo_ta,
           f.so_luong,
           ROW_NUMBER() OVER (PARTITION BY f.ch_key, f.mh_key, t.nam, t.quy ORDER BY f.time_key DESC) AS rn
    FROM DW_Core.dbo.Fact_Kho f
    JOIN DW_Core.dbo.Dim_ThoiGian t ON t.time_key = f.time_key
    JOIN DW_Core.dbo.Dim_MatHang mh ON mh.mh_key = f.mh_key
)
SELECT nam, quy, mh_key, mo_ta, SUM(so_luong) AS tong_ton_kho
INTO dbo.[olap_tk_quy_mh]
FROM ranked WHERE rn = 1
GROUP BY nam, quy, mh_key, mo_ta
OPTION (MAXDOP 1, MAX_GRANT_PERCENT = 0);
GO

-- [142] olap_tk_quy_mh_tinh (3D)
WITH ranked AS (
    SELECT t.nam AS nam,
           t.quy AS quy,
           f.mh_key AS mh_key,
           mh.mo_ta AS mo_ta,
           v.bang AS bang,
           f.so_luong,
           ROW_NUMBER() OVER (PARTITION BY f.ch_key, f.mh_key, t.nam, t.quy ORDER BY f.time_key DESC) AS rn
    FROM DW_Core.dbo.Fact_Kho f
    JOIN DW_Core.dbo.Dim_ThoiGian t ON t.time_key = f.time_key
    JOIN DW_Core.dbo.Dim_MatHang mh ON mh.mh_key = f.mh_key
    JOIN DW_Core.dbo.Dim_CuaHang ch ON ch.ch_key = f.ch_key
    JOIN DW_Core.dbo.Dim_VPDD v ON v.vp_key = ch.vp_key
)
SELECT nam, quy, mh_key, mo_ta, bang, SUM(so_luong) AS tong_ton_kho
INTO dbo.[olap_tk_quy_mh_tinh]
FROM ranked WHERE rn = 1
GROUP BY nam, quy, mh_key, mo_ta, bang
OPTION (MAXDOP 1, MAX_GRANT_PERCENT = 0);
GO

-- [143] olap_tk_quy_mh_tp (3D)
WITH ranked AS (
    SELECT t.nam AS nam,
           t.quy AS quy,
           f.mh_key AS mh_key,
           mh.mo_ta AS mo_ta,
           v.bang AS bang,
           v.ten_tp AS ten_tp,
           f.so_luong,
           ROW_NUMBER() OVER (PARTITION BY f.ch_key, f.mh_key, t.nam, t.quy ORDER BY f.time_key DESC) AS rn
    FROM DW_Core.dbo.Fact_Kho f
    JOIN DW_Core.dbo.Dim_ThoiGian t ON t.time_key = f.time_key
    JOIN DW_Core.dbo.Dim_MatHang mh ON mh.mh_key = f.mh_key
    JOIN DW_Core.dbo.Dim_CuaHang ch ON ch.ch_key = f.ch_key
    JOIN DW_Core.dbo.Dim_VPDD v ON v.vp_key = ch.vp_key
)
SELECT nam, quy, mh_key, mo_ta, bang, ten_tp, SUM(so_luong) AS tong_ton_kho
INTO dbo.[olap_tk_quy_mh_tp]
FROM ranked WHERE rn = 1
GROUP BY nam, quy, mh_key, mo_ta, bang, ten_tp
OPTION (MAXDOP 1, MAX_GRANT_PERCENT = 0);
GO

-- [144] olap_tk_quy_mh_ch (3D)
WITH ranked AS (
    SELECT t.nam AS nam,
           t.quy AS quy,
           f.mh_key AS mh_key,
           mh.mo_ta AS mo_ta,
           v.bang AS bang,
           v.ten_tp AS ten_tp,
           f.ch_key AS ch_key,
           f.so_luong,
           ROW_NUMBER() OVER (PARTITION BY f.ch_key, f.mh_key, t.nam, t.quy ORDER BY f.time_key DESC) AS rn
    FROM DW_Core.dbo.Fact_Kho f
    JOIN DW_Core.dbo.Dim_ThoiGian t ON t.time_key = f.time_key
    JOIN DW_Core.dbo.Dim_MatHang mh ON mh.mh_key = f.mh_key
    JOIN DW_Core.dbo.Dim_CuaHang ch ON ch.ch_key = f.ch_key
    JOIN DW_Core.dbo.Dim_VPDD v ON v.vp_key = ch.vp_key
)
SELECT nam, quy, mh_key, mo_ta, bang, ten_tp, ch_key, SUM(so_luong) AS tong_ton_kho
INTO dbo.[olap_tk_quy_mh_ch]
FROM ranked WHERE rn = 1
GROUP BY nam, quy, mh_key, mo_ta, bang, ten_tp, ch_key
OPTION (MAXDOP 1, MAX_GRANT_PERCENT = 0);
GO

-- [145] olap_tk_thang (1D)
WITH ranked AS (
    SELECT t.nam AS nam,
           t.quy AS quy,
           t.thang AS thang,
           f.so_luong,
           ROW_NUMBER() OVER (PARTITION BY f.ch_key, f.mh_key, t.nam, t.quy, t.thang ORDER BY f.time_key DESC) AS rn
    FROM DW_Core.dbo.Fact_Kho f
    JOIN DW_Core.dbo.Dim_ThoiGian t ON t.time_key = f.time_key
)
SELECT nam, quy, thang, SUM(so_luong) AS tong_ton_kho
INTO dbo.[olap_tk_thang]
FROM ranked WHERE rn = 1
GROUP BY nam, quy, thang
OPTION (MAXDOP 1, MAX_GRANT_PERCENT = 0);
GO

-- [146] olap_tk_thang_tinh (2D)
WITH ranked AS (
    SELECT t.nam AS nam,
           t.quy AS quy,
           t.thang AS thang,
           v.bang AS bang,
           f.so_luong,
           ROW_NUMBER() OVER (PARTITION BY f.ch_key, f.mh_key, t.nam, t.quy, t.thang ORDER BY f.time_key DESC) AS rn
    FROM DW_Core.dbo.Fact_Kho f
    JOIN DW_Core.dbo.Dim_ThoiGian t ON t.time_key = f.time_key
    JOIN DW_Core.dbo.Dim_CuaHang ch ON ch.ch_key = f.ch_key
    JOIN DW_Core.dbo.Dim_VPDD v ON v.vp_key = ch.vp_key
)
SELECT nam, quy, thang, bang, SUM(so_luong) AS tong_ton_kho
INTO dbo.[olap_tk_thang_tinh]
FROM ranked WHERE rn = 1
GROUP BY nam, quy, thang, bang
OPTION (MAXDOP 1, MAX_GRANT_PERCENT = 0);
GO

-- [147] olap_tk_thang_tp (2D)
WITH ranked AS (
    SELECT t.nam AS nam,
           t.quy AS quy,
           t.thang AS thang,
           v.bang AS bang,
           v.ten_tp AS ten_tp,
           f.so_luong,
           ROW_NUMBER() OVER (PARTITION BY f.ch_key, f.mh_key, t.nam, t.quy, t.thang ORDER BY f.time_key DESC) AS rn
    FROM DW_Core.dbo.Fact_Kho f
    JOIN DW_Core.dbo.Dim_ThoiGian t ON t.time_key = f.time_key
    JOIN DW_Core.dbo.Dim_CuaHang ch ON ch.ch_key = f.ch_key
    JOIN DW_Core.dbo.Dim_VPDD v ON v.vp_key = ch.vp_key
)
SELECT nam, quy, thang, bang, ten_tp, SUM(so_luong) AS tong_ton_kho
INTO dbo.[olap_tk_thang_tp]
FROM ranked WHERE rn = 1
GROUP BY nam, quy, thang, bang, ten_tp
OPTION (MAXDOP 1, MAX_GRANT_PERCENT = 0);
GO

-- [148] olap_tk_thang_ch (2D)
WITH ranked AS (
    SELECT t.nam AS nam,
           t.quy AS quy,
           t.thang AS thang,
           v.bang AS bang,
           v.ten_tp AS ten_tp,
           f.ch_key AS ch_key,
           f.so_luong,
           ROW_NUMBER() OVER (PARTITION BY f.ch_key, f.mh_key, t.nam, t.quy, t.thang ORDER BY f.time_key DESC) AS rn
    FROM DW_Core.dbo.Fact_Kho f
    JOIN DW_Core.dbo.Dim_ThoiGian t ON t.time_key = f.time_key
    JOIN DW_Core.dbo.Dim_CuaHang ch ON ch.ch_key = f.ch_key
    JOIN DW_Core.dbo.Dim_VPDD v ON v.vp_key = ch.vp_key
)
SELECT nam, quy, thang, bang, ten_tp, ch_key, SUM(so_luong) AS tong_ton_kho
INTO dbo.[olap_tk_thang_ch]
FROM ranked WHERE rn = 1
GROUP BY nam, quy, thang, bang, ten_tp, ch_key
OPTION (MAXDOP 1, MAX_GRANT_PERCENT = 0);
GO

-- [149] olap_tk_thang_mh (2D)
WITH ranked AS (
    SELECT t.nam AS nam,
           t.quy AS quy,
           t.thang AS thang,
           f.mh_key AS mh_key,
           mh.mo_ta AS mo_ta,
           f.so_luong,
           ROW_NUMBER() OVER (PARTITION BY f.ch_key, f.mh_key, t.nam, t.quy, t.thang ORDER BY f.time_key DESC) AS rn
    FROM DW_Core.dbo.Fact_Kho f
    JOIN DW_Core.dbo.Dim_ThoiGian t ON t.time_key = f.time_key
    JOIN DW_Core.dbo.Dim_MatHang mh ON mh.mh_key = f.mh_key
)
SELECT nam, quy, thang, mh_key, mo_ta, SUM(so_luong) AS tong_ton_kho
INTO dbo.[olap_tk_thang_mh]
FROM ranked WHERE rn = 1
GROUP BY nam, quy, thang, mh_key, mo_ta
OPTION (MAXDOP 1, MAX_GRANT_PERCENT = 0);
GO

-- [150] olap_tk_thang_mh_tinh (3D)
WITH ranked AS (
    SELECT t.nam AS nam,
           t.quy AS quy,
           t.thang AS thang,
           f.mh_key AS mh_key,
           mh.mo_ta AS mo_ta,
           v.bang AS bang,
           f.so_luong,
           ROW_NUMBER() OVER (PARTITION BY f.ch_key, f.mh_key, t.nam, t.quy, t.thang ORDER BY f.time_key DESC) AS rn
    FROM DW_Core.dbo.Fact_Kho f
    JOIN DW_Core.dbo.Dim_ThoiGian t ON t.time_key = f.time_key
    JOIN DW_Core.dbo.Dim_MatHang mh ON mh.mh_key = f.mh_key
    JOIN DW_Core.dbo.Dim_CuaHang ch ON ch.ch_key = f.ch_key
    JOIN DW_Core.dbo.Dim_VPDD v ON v.vp_key = ch.vp_key
)
SELECT nam, quy, thang, mh_key, mo_ta, bang, SUM(so_luong) AS tong_ton_kho
INTO dbo.[olap_tk_thang_mh_tinh]
FROM ranked WHERE rn = 1
GROUP BY nam, quy, thang, mh_key, mo_ta, bang
OPTION (MAXDOP 1, MAX_GRANT_PERCENT = 0);
GO

-- [151] olap_tk_thang_mh_tp (3D)
WITH ranked AS (
    SELECT t.nam AS nam,
           t.quy AS quy,
           t.thang AS thang,
           f.mh_key AS mh_key,
           mh.mo_ta AS mo_ta,
           v.bang AS bang,
           v.ten_tp AS ten_tp,
           f.so_luong,
           ROW_NUMBER() OVER (PARTITION BY f.ch_key, f.mh_key, t.nam, t.quy, t.thang ORDER BY f.time_key DESC) AS rn
    FROM DW_Core.dbo.Fact_Kho f
    JOIN DW_Core.dbo.Dim_ThoiGian t ON t.time_key = f.time_key
    JOIN DW_Core.dbo.Dim_MatHang mh ON mh.mh_key = f.mh_key
    JOIN DW_Core.dbo.Dim_CuaHang ch ON ch.ch_key = f.ch_key
    JOIN DW_Core.dbo.Dim_VPDD v ON v.vp_key = ch.vp_key
)
SELECT nam, quy, thang, mh_key, mo_ta, bang, ten_tp, SUM(so_luong) AS tong_ton_kho
INTO dbo.[olap_tk_thang_mh_tp]
FROM ranked WHERE rn = 1
GROUP BY nam, quy, thang, mh_key, mo_ta, bang, ten_tp
OPTION (MAXDOP 1, MAX_GRANT_PERCENT = 0);
GO

-- [152] olap_tk_thang_mh_ch (3D)
WITH ranked AS (
    SELECT t.nam AS nam,
           t.quy AS quy,
           t.thang AS thang,
           f.mh_key AS mh_key,
           mh.mo_ta AS mo_ta,
           v.bang AS bang,
           v.ten_tp AS ten_tp,
           f.ch_key AS ch_key,
           f.so_luong,
           ROW_NUMBER() OVER (PARTITION BY f.ch_key, f.mh_key, t.nam, t.quy, t.thang ORDER BY f.time_key DESC) AS rn
    FROM DW_Core.dbo.Fact_Kho f
    JOIN DW_Core.dbo.Dim_ThoiGian t ON t.time_key = f.time_key
    JOIN DW_Core.dbo.Dim_MatHang mh ON mh.mh_key = f.mh_key
    JOIN DW_Core.dbo.Dim_CuaHang ch ON ch.ch_key = f.ch_key
    JOIN DW_Core.dbo.Dim_VPDD v ON v.vp_key = ch.vp_key
)
SELECT nam, quy, thang, mh_key, mo_ta, bang, ten_tp, ch_key, SUM(so_luong) AS tong_ton_kho
INTO dbo.[olap_tk_thang_mh_ch]
FROM ranked WHERE rn = 1
GROUP BY nam, quy, thang, mh_key, mo_ta, bang, ten_tp, ch_key
OPTION (MAXDOP 1, MAX_GRANT_PERCENT = 0);
GO
