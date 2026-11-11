/* Source allocation and inventory ledger for the reproducible demo.
   The stock seeded in 01_idb_source.sql is the opening balance on 2021-01-01.
   Allocate orders chronologically, exhaust local stock before other cities.
   Demand may be split across stores. Fail if the network cannot fulfill it.
*/
USE IDB_BanHang;
GO
SET XACT_ABORT ON;
BEGIN TRANSACTION;

CREATE TABLE dbo.PhanBoDonHang (
    MaDon INT NOT NULL, MaMH INT NOT NULL, MaCuaHang INT NOT NULL,
    SoLuongCap INT NOT NULL CHECK (SoLuongCap > 0),
    PRIMARY KEY (MaDon, MaMH, MaCuaHang),
    FOREIGN KEY (MaDon, MaMH) REFERENCES dbo.MatHangDuocDat(MaDon, MaMH),
    FOREIGN KEY (MaCuaHang, MaMH) REFERENCES dbo.MatHangLuuTru(MaCuaHang, MaMH));
CREATE TABLE dbo.BienDongKho (
    MaBienDong INT IDENTITY PRIMARY KEY,
    MaCuaHang INT NOT NULL, MaMH INT NOT NULL, Ngay DATE NOT NULL,
    Loai VARCHAR(10) NOT NULL CHECK (Loai IN ('DAUKY','XUAT')),
    SoLuong INT NOT NULL, MaDon INT NULL,
    FOREIGN KEY (MaCuaHang, MaMH) REFERENCES dbo.MatHangLuuTru(MaCuaHang, MaMH));
CREATE TABLE dbo.TonKhoThang (
    ThangKey BIGINT NOT NULL, MaCuaHang INT NOT NULL, MaMH INT NOT NULL,
    SoLuong INT NOT NULL CHECK (SoLuong >= 0),
    PRIMARY KEY (ThangKey, MaCuaHang, MaMH),
    FOREIGN KEY (MaCuaHang, MaMH) REFERENCES dbo.MatHangLuuTru(MaCuaHang, MaMH));

INSERT dbo.BienDongKho (MaCuaHang, MaMH, Ngay, Loai, SoLuong)
SELECT MaCuaHang, MaMH, '20210101', 'DAUKY', SoLuongTrongKho FROM dbo.MatHangLuuTru;
SELECT MaCuaHang, MaMH, SoLuongTrongKho AS ConLai INTO #Available FROM dbo.MatHangLuuTru;

DECLARE @don INT, @mh INT, @qty INT, @tp INT, @ngay DATE, @ch INT, @available INT, @take INT;
DECLARE orders_cursor CURSOR LOCAL FAST_FORWARD FOR
SELECT o.MaDon, d.MaMH, d.SoLuongDat, k.MaThanhPho, o.NgayDatHang
FROM dbo.DonDatHang o JOIN dbo.MatHangDuocDat d ON d.MaDon = o.MaDon
JOIN IDB_VPDD.dbo.KhachHang k ON k.MaKH = o.MaKH
ORDER BY o.NgayDatHang, o.MaDon, d.MaMH;
OPEN orders_cursor;
FETCH NEXT FROM orders_cursor INTO @don, @mh, @qty, @tp, @ngay;
WHILE @@FETCH_STATUS = 0
BEGIN
    WHILE @qty > 0
    BEGIN
        SET @ch = NULL;
        SELECT TOP (1) @ch = a.MaCuaHang, @available = a.ConLai
        FROM #Available a JOIN dbo.CuaHang c ON c.MaCuaHang = a.MaCuaHang
        WHERE a.MaMH = @mh AND a.ConLai > 0
        ORDER BY CASE WHEN c.MaThanhPho = @tp THEN 0 ELSE 1 END, a.ConLai DESC, a.MaCuaHang;
        IF @ch IS NULL THROW 51001, 'Nguon khong du hang de dap ung don. Can mo hinh don thieu hang.', 1;
        SET @take = CASE WHEN @available >= @qty THEN @qty ELSE @available END;
        INSERT dbo.PhanBoDonHang VALUES (@don, @mh, @ch, @take);
        INSERT dbo.BienDongKho (MaCuaHang, MaMH, Ngay, Loai, SoLuong, MaDon)
        VALUES (@ch, @mh, @ngay, 'XUAT', -@take, @don);
        UPDATE #Available SET ConLai = ConLai - @take WHERE MaCuaHang = @ch AND MaMH = @mh;
        SET @qty -= @take;
    END;
    FETCH NEXT FROM orders_cursor INTO @don, @mh, @qty, @tp, @ngay;
END;
CLOSE orders_cursor;
DEALLOCATE orders_cursor;

UPDATE l SET SoLuongTrongKho = a.ConLai, ThoiGian = '20231231'
FROM dbo.MatHangLuuTru l JOIN #Available a ON a.MaCuaHang = l.MaCuaHang AND a.MaMH = l.MaMH;

;WITH months AS (
    SELECT CAST('20210101' AS DATE) AS d
    UNION ALL SELECT DATEADD(MONTH, 1, d) FROM months WHERE d < '20231201'
)
INSERT dbo.TonKhoThang (ThangKey, MaCuaHang, MaMH, SoLuong)
SELECT YEAR(m.d)*100 + MONTH(m.d), a.MaCuaHang, a.MaMH, SUM(b.SoLuong)
FROM months m CROSS JOIN #Available a
JOIN dbo.BienDongKho b ON b.MaCuaHang = a.MaCuaHang AND b.MaMH = a.MaMH
    AND b.Ngay < DATEADD(MONTH, 1, m.d)
GROUP BY m.d, a.MaCuaHang, a.MaMH OPTION (MAXRECURSION 1000);
DROP TABLE #Available;
COMMIT;
GO
