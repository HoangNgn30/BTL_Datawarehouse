/* 9 bao cao theo de bai. Thay @tham_so cho phu hop.
   - Bao cao tong hop/tra cuu chay tren DW_Core (galaxy schema).
   - Bao cao theo tung ma don (2, 5, 8) doc tang IDB_TichHop: fact ban hang luu o khoa
     ngay + khach + mat hang + cua hang nen khong giu ma don (ma don khong phai chieu phan tich). */
USE DW_Core;
DECLARE @kh NVARCHAR(20)='1', @mh NVARCHAR(20)='1', @don INT=1,
        @tp NVARCHAR(20)='1', @muc INT=100;

-- 1. Cua hang + thanh pho, bang, SDT + mat hang ban o kho do
SELECT ch.ch_key, v.ten_tp, v.bang, ch.so_dt, mh.mo_ta, mh.kich_co, mh.trong_luong, mh.gia
FROM Dim_CuaHang ch JOIN Dim_VPDD v ON v.vp_key=ch.vp_key
JOIN (SELECT DISTINCT ch_key, mh_key FROM Fact_Kho) k ON k.ch_key=ch.ch_key
JOIN Dim_MatHang mh ON mh.mh_key=k.mh_key;

-- 2. Don dat hang voi ten KH va ngay dat
SELECT o.MaDon AS ma_don, k.TenKH AS ten, o.NgayDatHang AS ngay
FROM IDB_TichHop.dbo.DonDatHang o JOIN IDB_TichHop.dbo.KhachHang k ON k.MaKH=o.MaKH
WHERE o.MaKH=CAST(@kh AS INT) ORDER BY o.NgayDatHang, o.MaDon;

-- 3. Cua hang (ten TP, SDT) co ban cac mat hang do mot KH dat
SELECT DISTINCT ch.ch_key, v.ten_tp, ch.so_dt
FROM Fact_BanHang f
JOIN (SELECT DISTINCT ch_key,mh_key FROM Fact_Kho) k ON k.mh_key=f.mh_key
JOIN Dim_CuaHang ch ON ch.ch_key=k.ch_key JOIN Dim_VPDD v ON v.vp_key=ch.vp_key
WHERE f.kh_key=@kh;

-- 4. VPDD (dia chi, TP, bang) cua cac cua hang luu kho mat hang voi so luong > muc (snapshot moi nhat moi cap)
SELECT DISTINCT ch.ch_key, v.dia_chi_vp, v.ten_tp, v.bang, k.so_luong
FROM Fact_Kho k JOIN Dim_CuaHang ch ON ch.ch_key=k.ch_key JOIN Dim_VPDD v ON v.vp_key=ch.vp_key
WHERE k.mh_key=@mh AND k.so_luong>@muc
  AND k.time_key=(SELECT MAX(k2.time_key) FROM Fact_Kho k2 WHERE k2.ch_key=k.ch_key AND k2.mh_key=k.mh_key);

-- 5. Moi don: mat hang + mo ta, cua hang cap, TP, cac cua hang co ban mat hang do
SELECT d.MaDon AS ma_don, d.MaMH AS mh_key, m.MoTa AS mo_ta, p.MaCuaHang AS ch_dap_ung, p.SoLuongCap AS so_luong_cap,
       v.TenThanhPho AS tp_dap_ung,
       (SELECT STRING_AGG(CONCAT(l.MaCuaHang, N' (', v2.TenThanhPho, N')'), N', ') WITHIN GROUP (ORDER BY l.MaCuaHang)
        FROM IDB_TichHop.dbo.MatHangLuuTru l JOIN IDB_TichHop.dbo.CuaHang c2 ON c2.MaCuaHang=l.MaCuaHang
        JOIN IDB_TichHop.dbo.VanPhongDaiDien v2 ON v2.MaThanhPho=c2.MaThanhPho WHERE l.MaMH=d.MaMH) AS cac_ch_co_ban
FROM IDB_TichHop.dbo.MatHangDuocDat d JOIN IDB_TichHop.dbo.MatHang m ON m.MaMH=d.MaMH
JOIN IDB_TichHop.dbo.PhanBoDonHang p ON p.MaDon=d.MaDon AND p.MaMH=d.MaMH
JOIN IDB_TichHop.dbo.CuaHang c ON c.MaCuaHang=p.MaCuaHang JOIN IDB_TichHop.dbo.VanPhongDaiDien v ON v.MaThanhPho=c.MaThanhPho
WHERE d.MaDon=@don ORDER BY d.MaMH, p.MaCuaHang;

-- 6. Thanh pho, bang cua mot khach hang
SELECT kh.kh_key, kh.ten, v.ten_tp, v.bang
FROM Dim_KhachHang kh JOIN Dim_VPDD v ON v.vp_key=kh.vp_key WHERE kh.kh_key=@kh;

-- 7. Ton kho mot mat hang tai tat ca cua hang cua mot thanh pho (snapshot moi nhat moi cap)
SELECT ch.ch_key, k.mh_key, k.so_luong
FROM Fact_Kho k JOIN Dim_CuaHang ch ON ch.ch_key=k.ch_key
WHERE ch.vp_key=@tp AND k.mh_key=@mh
  AND k.time_key=(SELECT MAX(time_key) FROM Fact_Kho k2 WHERE k2.ch_key=k.ch_key AND k2.mh_key=k.mh_key);

-- 8. Mat hang, so luong dat, KH, cua hang, TP cua mot don
SELECT d.MaMH AS mh_key, m.MoTa AS mo_ta, d.SoLuongDat AS so_luong, k.TenKH AS khach_hang,
       p.MaCuaHang AS ch_key, p.SoLuongCap AS so_luong_cap, v.TenThanhPho AS ten_tp
FROM IDB_TichHop.dbo.MatHangDuocDat d JOIN IDB_TichHop.dbo.DonDatHang o ON o.MaDon=d.MaDon
JOIN IDB_TichHop.dbo.MatHang m ON m.MaMH=d.MaMH JOIN IDB_TichHop.dbo.KhachHang k ON k.MaKH=o.MaKH
JOIN IDB_TichHop.dbo.PhanBoDonHang p ON p.MaDon=d.MaDon AND p.MaMH=d.MaMH
JOIN IDB_TichHop.dbo.CuaHang c ON c.MaCuaHang=p.MaCuaHang JOIN IDB_TichHop.dbo.VanPhongDaiDien v ON v.MaThanhPho=c.MaThanhPho
WHERE d.MaDon=@don;

-- 9. KH du lich / buu dien / ca hai loai
SELECT kh_key, ten, loai_kh FROM Dim_KhachHang WHERE la_du_lich=1;                      -- du lich
SELECT kh_key, ten, loai_kh FROM Dim_KhachHang WHERE la_buu_dien=1;                     -- buu dien
SELECT kh_key, ten, loai_kh FROM Dim_KhachHang WHERE la_du_lich=1 AND la_buu_dien=1;    -- ca hai
