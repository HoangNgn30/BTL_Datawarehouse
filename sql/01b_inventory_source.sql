/* Bang phan bo don hang va so cai ton kho tai nguon Ban hang (IDB_BanHang).
   Script nay chi tao cau truc. Du lieu do scripts/allocate_orders.py sinh:
   - ton kho trong MatHangLuuTru luc nay la ton dau ky 01/01/2021 (DAUKY);
   - dau moi thang, cap cua hang-mat hang nao duoi 30% muc dau ky thi nhap bo sung ve muc dau ky (NHAP);
   - don hang duoc phan bo theo ngay, ma don, ma mat hang: uu tien cua hang cung thanh pho voi khach,
     sau do moi chuyen sang thanh pho khac; moi lan cap ghi mot dong XUAT;
   - TonKhoThang la so du cuoi moi thang cua tung cap cua hang-mat hang.
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
    MaBienDong INT PRIMARY KEY,
    MaCuaHang INT NOT NULL, MaMH INT NOT NULL, Ngay DATE NOT NULL,
    Loai VARCHAR(10) NOT NULL CHECK (Loai IN ('DAUKY','NHAP','XUAT')),
    SoLuong INT NOT NULL, MaDon INT NULL,
    FOREIGN KEY (MaCuaHang, MaMH) REFERENCES dbo.MatHangLuuTru(MaCuaHang, MaMH));
CREATE TABLE dbo.TonKhoThang (
    ThangKey BIGINT NOT NULL, MaCuaHang INT NOT NULL, MaMH INT NOT NULL,
    SoLuong INT NOT NULL CHECK (SoLuong >= 0),
    PRIMARY KEY (ThangKey, MaCuaHang, MaMH),
    FOREIGN KEY (MaCuaHang, MaMH) REFERENCES dbo.MatHangLuuTru(MaCuaHang, MaMH));

COMMIT;
GO
