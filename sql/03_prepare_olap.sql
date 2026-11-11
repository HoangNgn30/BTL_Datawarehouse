/* 03 - Chuan bi CSDL OLAP: tao neu chua co va xoa moi bang olap_* (de chay lai 56 cuboid) */
USE master;
GO
IF DB_ID('OLAP_QuanLyBanHang') IS NULL CREATE DATABASE OLAP_QuanLyBanHang;
GO
USE OLAP_QuanLyBanHang;
GO
DECLARE @s NVARCHAR(MAX) = N'';
SELECT @s += N'DROP TABLE dbo.' + QUOTENAME(name) + N';' FROM sys.tables WHERE name LIKE 'olap[_]%';
EXEC sp_executesql @s;
GO

