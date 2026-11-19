-- Metadata catalog, OLAP index and integration history index.
USE [OLAP_QuanLyBanHang];
GO
IF NOT EXISTS(SELECT 1 FROM sys.indexes WHERE name='IX_TK_MonthlyLookup' AND object_id=OBJECT_ID('dbo.olap_tk_thang_mh_ch')) CREATE INDEX [IX_TK_MonthlyLookup] ON dbo.[olap_tk_thang_mh_ch](ch_key,mh_key,nam,thang) INCLUDE (quy,tong_ton_kho,mo_ta,bang,ten_tp) WITH (MAXDOP=1);
GO
IF NOT EXISTS(SELECT 1 FROM sys.indexes WHERE name='IX_DS_DayStoreLookup' AND object_id=OBJECT_ID('dbo.olap_ds_ngay_mh_kh_ch')) CREATE INDEX [IX_DS_DayStoreLookup] ON dbo.[olap_ds_ngay_mh_kh_ch](nam,quy,thang,bang,ten_tp,ch_key) INCLUDE (mh_key,kh_key,loai_kh,tong_so_luong,tong_doanh_thu) WITH (MAXDOP=1);
GO
USE [IDB_TichHop];
GO
IF NOT EXISTS(SELECT 1 FROM sys.indexes WHERE name='IX_Integration_Run_StatusTime' AND object_id=OBJECT_ID('dbo.Integration_Run')) CREATE INDEX [IX_Integration_Run_StatusTime] ON dbo.[Integration_Run](Status,StartedAt DESC) INCLUDE (FinishedAt,CustomerSource) WITH (MAXDOP=1);
GO
USE DW_Core;
GO
SET XACT_ABORT ON;
BEGIN TRANSACTION;
IF OBJECT_ID('dbo.Metadata_Table') IS NULL CREATE TABLE dbo.Metadata_Table(TableName SYSNAME PRIMARY KEY,ObjectRole VARCHAR(20) NOT NULL,Grain NVARCHAR(300) NOT NULL);
IF OBJECT_ID('dbo.Metadata_Column') IS NULL CREATE TABLE dbo.Metadata_Column(TableName SYSNAME,ColumnName SYSNAME,DataType NVARCHAR(128),IsNullable BIT,IsPrimaryKey BIT,PRIMARY KEY(TableName,ColumnName));
IF OBJECT_ID('dbo.Metadata_Mapping') IS NULL CREATE TABLE dbo.Metadata_Mapping(TargetTable SYSNAME,TargetColumn SYSNAME,SourceExpression NVARCHAR(1000),Transformation NVARCHAR(1000),PRIMARY KEY(TargetTable,TargetColumn));
IF OBJECT_ID('dbo.Metadata_Relationship') IS NULL CREATE TABLE dbo.Metadata_Relationship(FKName SYSNAME,FromTable SYSNAME,FromColumn SYSNAME,ToTable SYSNAME,ToColumn SYSNAME,PRIMARY KEY(FKName,FromColumn));
IF OBJECT_ID('dbo.Metadata_Hierarchy') IS NULL CREATE TABLE dbo.Metadata_Hierarchy(DimensionName SYSNAME,LevelOrder INT,LevelName SYSNAME,KeyColumns NVARCHAR(200),PRIMARY KEY(DimensionName,LevelOrder));
IF OBJECT_ID('dbo.Metadata_Cube') IS NULL CREATE TABLE dbo.Metadata_Cube(TableName SYSNAME PRIMARY KEY,CubeName VARCHAR(20),TimeLevel SYSNAME,DimensionColumns NVARCHAR(2000),Measures NVARCHAR(300),AggregationRule NVARCHAR(500));
DELETE dbo.Metadata_Column;DELETE dbo.Metadata_Mapping;DELETE dbo.Metadata_Relationship;DELETE dbo.Metadata_Hierarchy;DELETE dbo.Metadata_Cube;DELETE dbo.Metadata_Table;
INSERT dbo.Metadata_Table VALUES
 ('Dim_ThoiGian','Dimension',N'YYYYMM'),('Dim_Ngay','Dimension',N'YYYYMMDD'),
 ('Dim_VPDD','Dimension',N'city'),('Dim_CuaHang','Dimension',N'store'),('Dim_MatHang','Dimension',N'product'),('Dim_KhachHang','Dimension',N'customer; overlapping subtypes flattened'),
 ('Fact_BanHang','Fact',N'day + customer + product + fulfilling store (4 dimension FKs)'),('Fact_Kho','Fact',N'month + store + product; periodic snapshot');
INSERT dbo.Metadata_Column
SELECT t.TableName,c.name,ty.name+CASE WHEN ty.name IN ('nvarchar','varchar') THEN '('+CAST(CASE WHEN ty.name='nvarchar' THEN c.max_length/2 ELSE c.max_length END AS VARCHAR(10))+')' WHEN ty.name IN ('decimal','numeric') THEN '('+CAST(c.precision AS VARCHAR(10))+','+CAST(c.scale AS VARCHAR(10))+')' ELSE '' END,
 c.is_nullable,CASE WHEN EXISTS(SELECT 1 FROM sys.index_columns ic JOIN sys.indexes i ON i.object_id=ic.object_id AND i.index_id=ic.index_id WHERE i.is_primary_key=1 AND ic.object_id=c.object_id AND ic.column_id=c.column_id) THEN 1 ELSE 0 END
FROM dbo.Metadata_Table t JOIN sys.columns c ON c.object_id=OBJECT_ID('dbo.'+t.TableName) JOIN sys.types ty ON ty.user_type_id=c.user_type_id;
INSERT dbo.Metadata_Relationship
SELECT f.name,OBJECT_NAME(f.parent_object_id),COL_NAME(fc.parent_object_id,fc.parent_column_id),OBJECT_NAME(f.referenced_object_id),COL_NAME(fc.referenced_object_id,fc.referenced_column_id)
FROM sys.foreign_keys f JOIN sys.foreign_key_columns fc ON fc.constraint_object_id=f.object_id JOIN dbo.Metadata_Table t ON t.TableName=OBJECT_NAME(f.parent_object_id);
INSERT dbo.Metadata_Hierarchy VALUES
 ('Time',0,'all',''),('Time',1,'nam','nam'),('Time',2,'quy','nam,quy'),('Time',3,'thang','nam,quy,thang'),('Time',4,'ngay','nam,quy,thang,ngay'),
 ('Product',0,'all',''),('Product',1,'mh','mh_key'),
 ('Customer',0,'all',''),('Customer',1,'loai_kh','loai_kh'),('Customer',2,'kh','kh_key'),
 ('Location',0,'all',''),('Location',1,'tinh','bang'),('Location',2,'tp','bang,ten_tp'),('Location',3,'ch','bang,ten_tp,ch_key');
INSERT dbo.Metadata_Cube
SELECT t.name,CASE WHEN t.name LIKE 'olap_ds_%' THEN 'Sales' ELSE 'Inventory' END,
 CASE WHEN t.name LIKE '%[_]ngay%' THEN 'ngay' WHEN t.name LIKE '%[_]thang%' THEN 'thang' WHEN t.name LIKE '%[_]quy%' THEN 'quy' WHEN t.name LIKE '%[_]nam%' THEN 'nam' ELSE 'all' END,
 STRING_AGG(CAST(CASE WHEN c.name NOT IN ('tong_so_luong','tong_doanh_thu','tong_ton_kho') THEN c.name END AS NVARCHAR(MAX)),','),
 CASE WHEN t.name LIKE 'olap_ds_%' THEN 'tong_so_luong,tong_doanh_thu' ELSE 'tong_ton_kho' END,
 CASE WHEN t.name LIKE 'olap_ds_%' THEN N'SUM over dimensions' ELSE N'Last snapshot in period per store/product, then SUM across store/product; never SUM over time' END
FROM OLAP_QuanLyBanHang.sys.tables t JOIN OLAP_QuanLyBanHang.sys.columns c ON c.object_id=t.object_id
WHERE t.name LIKE 'olap[_]%' GROUP BY t.name;
INSERT dbo.Metadata_Mapping VALUES
('Dim_VPDD','vp_key',N'IDB_TichHop.dbo.VanPhongDaiDien',N'MaThanhPho; business key converted to NVARCHAR when target is a dimension key'),
('Dim_VPDD','ten_tp',N'IDB_TichHop.dbo.VanPhongDaiDien',N'TenThanhPho'),
('Dim_VPDD','dia_chi_vp',N'IDB_TichHop.dbo.VanPhongDaiDien',N'DiaChiVP'),
('Dim_VPDD','bang',N'IDB_TichHop.dbo.VanPhongDaiDien',N'Bang'),
('Dim_CuaHang','ch_key',N'IDB_TichHop.dbo.CuaHang',N'MaCuaHang; business key converted to NVARCHAR when target is a dimension key'),
('Dim_CuaHang','so_dt',N'IDB_TichHop.dbo.CuaHang',N'SoDienThoai'),
('Dim_CuaHang','vp_key',N'IDB_TichHop.dbo.CuaHang',N'MaThanhPho; business key converted to NVARCHAR when target is a dimension key'),
('Dim_MatHang','mh_key',N'IDB_TichHop.dbo.MatHang',N'MaMH; business key converted to NVARCHAR when target is a dimension key'),
('Dim_MatHang','mo_ta',N'IDB_TichHop.dbo.MatHang',N'MoTa'),
('Dim_MatHang','kich_co',N'IDB_TichHop.dbo.MatHang',N'KichCo'),
('Dim_MatHang','trong_luong',N'IDB_TichHop.dbo.MatHang',N'TrongLuong'),
('Dim_MatHang','gia',N'IDB_TichHop.dbo.MatHang',N'Gia'),
('Dim_KhachHang','kh_key',N'IDB_TichHop.dbo.KhachHang LEFT JOIN KhachHangDuLich LEFT JOIN KhachHangBuuDien',N'MaKH; business key converted to NVARCHAR when target is a dimension key'),
('Dim_KhachHang','ten',N'IDB_TichHop.dbo.KhachHang LEFT JOIN KhachHangDuLich LEFT JOIN KhachHangBuuDien',N'TenKH'),
('Dim_KhachHang','vp_key',N'IDB_TichHop.dbo.KhachHang LEFT JOIN KhachHangDuLich LEFT JOIN KhachHangBuuDien',N'MaThanhPho; business key converted to NVARCHAR when target is a dimension key'),
('Dim_KhachHang','ngay_dat_dau_tien',N'IDB_TichHop.dbo.KhachHang LEFT JOIN KhachHangDuLich LEFT JOIN KhachHangBuuDien',N'NgayDatHangDauTien'),
('Dim_KhachHang','la_du_lich',N'IDB_TichHop.dbo.KhachHang LEFT JOIN KhachHangDuLich LEFT JOIN KhachHangBuuDien',N'KhachHangDuLich.MaKH IS NOT NULL'),
('Dim_KhachHang','la_buu_dien',N'IDB_TichHop.dbo.KhachHang LEFT JOIN KhachHangDuLich LEFT JOIN KhachHangBuuDien',N'KhachHangBuuDien.MaKH IS NOT NULL'),
('Dim_KhachHang','huong_dan_vien',N'IDB_TichHop.dbo.KhachHang LEFT JOIN KhachHangDuLich LEFT JOIN KhachHangBuuDien',N'HuongDanVienDuLich'),
('Dim_KhachHang','dia_chi_buu_dien',N'IDB_TichHop.dbo.KhachHang LEFT JOIN KhachHangDuLich LEFT JOIN KhachHangBuuDien',N'DiaChiBuuDien'),
('Dim_KhachHang','loai_kh',N'IDB_TichHop.dbo.KhachHang LEFT JOIN KhachHangDuLich LEFT JOIN KhachHangBuuDien',N'CASE subtype presence: CaHai / DuLich / BuuDien / Khac'),
('Dim_ThoiGian','time_key',N'MIN/MAX month bounds of IDB_TichHop.dbo.TonKhoThang UNION ALL order months from IDB_TichHop.dbo.DonDatHang',N'YEAR(d)*100+MONTH(d)'),
('Dim_ThoiGian','thang',N'MIN/MAX month bounds of IDB_TichHop.dbo.TonKhoThang UNION ALL order months from IDB_TichHop.dbo.DonDatHang',N'MONTH(d)'),
('Dim_ThoiGian','quy',N'MIN/MAX month bounds of IDB_TichHop.dbo.TonKhoThang UNION ALL order months from IDB_TichHop.dbo.DonDatHang',N'DATEPART(QUARTER,d)'),
('Dim_ThoiGian','nam',N'MIN/MAX month bounds of IDB_TichHop.dbo.TonKhoThang UNION ALL order months from IDB_TichHop.dbo.DonDatHang',N'YEAR(d)'),
('Dim_Ngay','ngay_key',N'Continuous calendar over the months of Dim_ThoiGian',N'YEAR(d)*10000+MONTH(d)*100+DAY(d)'),
('Dim_Ngay','ngay',N'Continuous calendar over the months of Dim_ThoiGian',N'd'),
('Dim_Ngay','time_key',N'Continuous calendar over the months of Dim_ThoiGian',N'YEAR(d)*100+MONTH(d); FK to Dim_ThoiGian'),
('Fact_BanHang','ngay_key',N'IDB_TichHop.dbo.PhanBoDonHang JOIN MatHangDuocDat JOIN DonDatHang',N'YYYYMMDD(NgayDatHang); FK to Dim_Ngay'),
('Fact_BanHang','kh_key',N'IDB_TichHop.dbo.PhanBoDonHang JOIN MatHangDuocDat JOIN DonDatHang',N'MaKH of the order; FK to Dim_KhachHang'),
('Fact_BanHang','mh_key',N'IDB_TichHop.dbo.PhanBoDonHang JOIN MatHangDuocDat JOIN DonDatHang',N'MaMH; FK to Dim_MatHang'),
('Fact_BanHang','ch_key',N'IDB_TichHop.dbo.PhanBoDonHang JOIN MatHangDuocDat JOIN DonDatHang',N'MaCuaHang of the fulfilling store; FK to Dim_CuaHang'),
('Fact_BanHang','so_luong',N'IDB_TichHop.dbo.PhanBoDonHang JOIN MatHangDuocDat JOIN DonDatHang',N'SUM(SoLuongCap) GROUP BY day, customer, product, store'),
('Fact_BanHang','doanh_thu',N'IDB_TichHop.dbo.PhanBoDonHang JOIN MatHangDuocDat JOIN DonDatHang',N'SUM(SoLuongCap*GiaDat) GROUP BY day, customer, product, store'),
('Fact_Kho','time_key',N'IDB_TichHop.dbo.TonKhoThang',N'ThangKey'),
('Fact_Kho','ch_key',N'IDB_TichHop.dbo.TonKhoThang',N'MaCuaHang; business key converted to NVARCHAR when target is a dimension key'),
('Fact_Kho','mh_key',N'IDB_TichHop.dbo.TonKhoThang',N'MaMH; business key converted to NVARCHAR when target is a dimension key'),
('Fact_Kho','so_luong',N'IDB_TichHop.dbo.TonKhoThang',N'SoLuong');
COMMIT TRANSACTION;
