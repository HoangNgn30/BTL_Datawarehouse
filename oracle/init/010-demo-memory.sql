WHENEVER SQLERROR EXIT SQL.SQLCODE
-- Demo sizing: avoid exhausting a laptop while SQL Server runs alongside Oracle.
ALTER SYSTEM SET sga_target=768M SCOPE=BOTH;
ALTER SYSTEM SET pga_aggregate_target=128M SCOPE=BOTH;
