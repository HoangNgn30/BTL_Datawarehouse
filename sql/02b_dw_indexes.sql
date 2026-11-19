-- DW indexes for reports, drill-across and cuboid materialization. Run after DW load.
USE [DW_Core];
GO
IF NOT EXISTS(SELECT 1 FROM sys.indexes WHERE name='IX_BanHang_Customer' AND object_id=OBJECT_ID('dbo.Fact_BanHang')) CREATE INDEX [IX_BanHang_Customer] ON dbo.[Fact_BanHang](kh_key,ngay_key) INCLUDE (mh_key,ch_key,so_luong,doanh_thu) WITH (MAXDOP=1);
GO
IF NOT EXISTS(SELECT 1 FROM sys.indexes WHERE name='IX_BanHang_StoreProduct' AND object_id=OBJECT_ID('dbo.Fact_BanHang')) CREATE INDEX [IX_BanHang_StoreProduct] ON dbo.[Fact_BanHang](ch_key,mh_key,ngay_key) INCLUDE (so_luong,doanh_thu) WITH (MAXDOP=1);
GO
IF NOT EXISTS(SELECT 1 FROM sys.indexes WHERE name='IX_BanHang_Product' AND object_id=OBJECT_ID('dbo.Fact_BanHang')) CREATE INDEX [IX_BanHang_Product] ON dbo.[Fact_BanHang](mh_key,ngay_key) INCLUDE (kh_key,ch_key,so_luong,doanh_thu) WITH (MAXDOP=1);
GO
IF NOT EXISTS(SELECT 1 FROM sys.indexes WHERE name='IX_Kho_StoreProductLatest' AND object_id=OBJECT_ID('dbo.Fact_Kho')) CREATE INDEX [IX_Kho_StoreProductLatest] ON dbo.[Fact_Kho](ch_key,mh_key,time_key DESC) INCLUDE (so_luong) WITH (MAXDOP=1);
GO
IF NOT EXISTS(SELECT 1 FROM sys.indexes WHERE name='IX_Ngay_Month' AND object_id=OBJECT_ID('dbo.Dim_Ngay')) CREATE INDEX [IX_Ngay_Month] ON dbo.[Dim_Ngay](time_key) INCLUDE (ngay) WITH (MAXDOP=1);
GO
IF NOT EXISTS(SELECT 1 FROM sys.indexes WHERE name='IX_CuaHang_City' AND object_id=OBJECT_ID('dbo.Dim_CuaHang')) CREATE INDEX [IX_CuaHang_City] ON dbo.[Dim_CuaHang](vp_key) INCLUDE (so_dt) WITH (MAXDOP=1);
GO
IF NOT EXISTS(SELECT 1 FROM sys.indexes WHERE name='IX_KhachHang_Type' AND object_id=OBJECT_ID('dbo.Dim_KhachHang')) CREATE INDEX [IX_KhachHang_Type] ON dbo.[Dim_KhachHang](loai_kh) INCLUDE (ten,vp_key) WITH (MAXDOP=1);
GO
