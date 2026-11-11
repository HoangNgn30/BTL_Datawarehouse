/* 9 bao cao OLAP theo de bai - chay tren DW_Core (v3). Thay @tham_so cho phu hop. */
USE DW_Core;
DECLARE @kh NVARCHAR(20)='1', @mh NVARCHAR(20)='1', @don NVARCHAR(20)='1',
        @tp NVARCHAR(20)='1', @muc INT=100;

-- 1. Cua hang + thanh pho, bang, SDT + mat hang ban o kho do
SELECT ch.ch_key, v.ten_tp, v.bang, ch.so_dt, mh.mo_ta, mh.kich_co, mh.trong_luong, mh.gia
FROM Dim_CuaHang ch JOIN Dim_VPDD v ON v.vp_key=ch.vp_key
JOIN (SELECT DISTINCT ch_key, mh_key FROM Fact_Kho) k ON k.ch_key=ch.ch_key
JOIN Dim_MatHang mh ON mh.mh_key=k.mh_key;

-- 2. Don dat hang voi ten KH va ngay dat
SELECT DISTINCT f.ma_don, kh.ten, n.ngay
FROM Fact_BanHang f JOIN Dim_KhachHang kh ON kh.kh_key=f.kh_key
JOIN Dim_Ngay n ON n.ngay_key=f.ngay_key WHERE f.kh_key=@kh;

-- 3. Cua hang (ten TP, SDT) co ban cac mat hang do mot KH dat
SELECT DISTINCT ch.ch_key, v.ten_tp, ch.so_dt
FROM Fact_BanHang f
JOIN (SELECT DISTINCT ch_key,mh_key FROM Fact_Kho) k ON k.mh_key=f.mh_key
JOIN Dim_CuaHang ch ON ch.ch_key=k.ch_key JOIN Dim_VPDD v ON v.vp_key=ch.vp_key
WHERE f.kh_key=@kh;

-- 4. VPDD (dia chi, TP, bang) cua cac cua hang luu kho mat hang voi so luong > muc
SELECT DISTINCT v.dia_chi_vp, v.ten_tp, v.bang
FROM Fact_Kho k JOIN Dim_CuaHang ch ON ch.ch_key=k.ch_key JOIN Dim_VPDD v ON v.vp_key=ch.vp_key
WHERE k.mh_key=@mh AND k.so_luong>@muc
  AND k.time_key=(SELECT MAX(time_key) FROM Fact_Kho);

-- 5. Moi don: mat hang + mo ta, ma cua hang, TP, cac cua hang co ban mat hang do
SELECT f.ma_don, f.mh_key, mh.mo_ta, pb.ch_key AS ch_dap_ung, pb.so_luong_cap, v.ten_tp AS tp_dap_ung,
       k.ch_key AS ch_co_ban
FROM Fact_BanHang f JOIN Dim_MatHang mh ON mh.mh_key=f.mh_key
LEFT JOIN Fact_PhanBo pb ON pb.ma_don=f.ma_don AND pb.mh_key=f.mh_key
LEFT JOIN Dim_CuaHang c ON c.ch_key=pb.ch_key LEFT JOIN Dim_VPDD v ON v.vp_key=c.vp_key
LEFT JOIN (SELECT DISTINCT ch_key, mh_key FROM Fact_Kho) k ON k.mh_key=f.mh_key
WHERE f.ma_don=@don
ORDER BY f.ma_don;

-- 6. Thanh pho, bang cua mot khach hang
SELECT kh.kh_key, kh.ten, v.ten_tp, v.bang
FROM Dim_KhachHang kh JOIN Dim_VPDD v ON v.vp_key=kh.vp_key WHERE kh.kh_key=@kh;

-- 7. Ton kho mot mat hang tai tat ca cua hang cua mot thanh pho (snapshot moi nhat)
SELECT ch.ch_key, k.mh_key, k.so_luong
FROM Fact_Kho k JOIN Dim_CuaHang ch ON ch.ch_key=k.ch_key
WHERE ch.vp_key=@tp AND k.mh_key=@mh
  AND k.time_key=(SELECT MAX(time_key) FROM Fact_Kho k2 WHERE k2.ch_key=k.ch_key AND k2.mh_key=k.mh_key);

-- 8. Mat hang, so luong dat, KH, cua hang, TP cua mot don
SELECT f.mh_key, mh.mo_ta, f.so_luong, kh.ten, pb.ch_key, pb.so_luong_cap, v.ten_tp
FROM Fact_BanHang f JOIN Dim_MatHang mh ON mh.mh_key=f.mh_key
JOIN Dim_KhachHang kh ON kh.kh_key=f.kh_key
LEFT JOIN Fact_PhanBo pb ON pb.ma_don=f.ma_don AND pb.mh_key=f.mh_key
LEFT JOIN Dim_CuaHang c ON c.ch_key=pb.ch_key LEFT JOIN Dim_VPDD v ON v.vp_key=c.vp_key
WHERE f.ma_don=@don;

-- 9. KH du lich / buu dien / ca hai loai
SELECT kh_key, ten, loai_kh FROM Dim_KhachHang WHERE la_du_lich=1;                      -- du lich
SELECT kh_key, ten, loai_kh FROM Dim_KhachHang WHERE la_buu_dien=1;                     -- buu dien
SELECT kh_key, ten, loai_kh FROM Dim_KhachHang WHERE la_du_lich=1 AND la_buu_dien=1;    -- ca hai

