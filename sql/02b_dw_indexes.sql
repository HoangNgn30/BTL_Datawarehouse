-- DW indexes for drill-through and cuboid materialization. Run after DW load.
USE [DW_Core];
GO
IF NOT EXISTS(SELECT 1 FROM sys.indexes WHERE name='IX_BanHang_TimeCustomerProduct' AND object_id=OBJECT_ID('dbo.Fact_BanHang')) CREATE INDEX [IX_BanHang_TimeCustomerProduct] ON dbo.[Fact_BanHang](time_key,kh_key,mh_key) INCLUDE (so_luong,tong_tien,ngay_key) WITH (MAXDOP=1);
GO
USE [DW_Core];
GO
IF NOT EXISTS(SELECT 1 FROM sys.indexes WHERE name='IX_BanHang_Customer' AND object_id=OBJECT_ID('dbo.Fact_BanHang')) CREATE INDEX [IX_BanHang_Customer] ON dbo.[Fact_BanHang](kh_key,time_key) INCLUDE (mh_key,so_luong,tong_tien) WITH (MAXDOP=1);
GO
USE [DW_Core];
GO
IF NOT EXISTS(SELECT 1 FROM sys.indexes WHERE name='IX_Kho_StoreProductLatest' AND object_id=OBJECT_ID('dbo.Fact_Kho')) CREATE INDEX [IX_Kho_StoreProductLatest] ON dbo.[Fact_Kho](ch_key,mh_key,time_key DESC) INCLUDE (so_luong) WITH (MAXDOP=1);
GO
USE [DW_Core];
GO
IF NOT EXISTS(SELECT 1 FROM sys.indexes WHERE name='IX_PhanBo_Store' AND object_id=OBJECT_ID('dbo.Fact_PhanBo')) CREATE INDEX [IX_PhanBo_Store] ON dbo.[Fact_PhanBo](ch_key,mh_key) INCLUDE (so_luong_cap) WITH (MAXDOP=1);
GO
USE [DW_Core];
GO
IF NOT EXISTS(SELECT 1 FROM sys.indexes WHERE name='IX_CuaHang_City' AND object_id=OBJECT_ID('dbo.Dim_CuaHang')) CREATE INDEX [IX_CuaHang_City] ON dbo.[Dim_CuaHang](vp_key) INCLUDE (so_dt) WITH (MAXDOP=1);
GO
USE [DW_Core];
GO
IF NOT EXISTS(SELECT 1 FROM sys.indexes WHERE name='IX_KhachHang_Type' AND object_id=OBJECT_ID('dbo.Dim_KhachHang')) CREATE INDEX [IX_KhachHang_Type] ON dbo.[Dim_KhachHang](loai_kh) INCLUDE (ten,vp_key) WITH (MAXDOP=1);
GO
