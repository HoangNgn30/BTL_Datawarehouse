"""Verify integrated data, active constraints, complete metadata and required indexes."""
import json
import os
from collections import Counter
from pathlib import Path
import sys
from oracle_sync import sql_connection
sys.path.insert(0,str(Path(__file__).resolve().parents[1]/'dw-dm'))
from cube_schema import cuboid_count

def run():
    source=os.getenv('DB_CUSTOMER_SOURCE','IDB_VPDD')
    if source not in ('IDB_VPDD','STG_OracleVPDD'):raise ValueError('Unsupported source')
    tables=json.loads((Path(__file__).with_name('idb_tables.json')).read_text())
    passed=0
    with sql_connection('IDB_TichHop') as cn:
        def check(name,condition):
            nonlocal passed
            assert condition,name
            passed+=1;print('[OK]',name)
        for table,spec in tables.items():
            columns=','.join(spec['columns'])
            # Compare at the IDB timestamp precision (DATETIME -> DATETIME2 is lossless in SQL).
            source_columns=','.join('CAST(ThoiGian AS DATETIME2(6))' if c=='ThoiGian' else c for c in spec['columns'])
            origin=source if spec['customer'] else 'IDB_BanHang'
            expected=Counter(tuple(r) for r in cn.cursor().execute(f'SELECT {source_columns} FROM [{origin}].dbo.[{table}]'))
            actual=Counter(tuple(r) for r in cn.cursor().execute(f'SELECT {columns} FROM dbo.[{table}]'))
            check(f'{table}: source -> IDB ({sum(actual.values())} rows)',expected==actual)
        invalid=cn.cursor().execute('SELECT COUNT(*) FROM sys.foreign_keys WHERE is_disabled=1 OR is_not_trusted=1').fetchone()[0]
        check('Integrated FKs enabled and trusted',invalid==0)
        # Deliberate invalid write is isolated and always rolled back.
        cn.commit()
        rejected=False
        try:
            cn.cursor().execute("INSERT dbo.DonDatHang(MaDon,NgayDatHang,MaKH) VALUES(-2147483647,'20220101',-2147483647)")
        except __import__('pyodbc').IntegrityError:rejected=True
        finally:cn.rollback()
        check('Order with unknown customer rejected by IDB FK',rejected)
        row=cn.cursor().execute("SELECT TOP(1) Status,CustomerSource FROM dbo.Integration_Run ORDER BY RunID DESC").fetchone()
        check('Successful integration provenance recorded',row[0]=='SUCCESS' and row[1]==source)
    with sql_connection('DW_Core') as cn:
        def scalar(sql):return cn.cursor().execute(sql).fetchone()[0]
        check('8 DW fact/dimension definitions (2 facts, 6 dimensions)',scalar('SELECT COUNT(*) FROM dbo.Metadata_Table')==8)
        check('Every DW column has metadata and mapping',scalar('''SELECT COUNT(*) FROM sys.columns c JOIN dbo.Metadata_Table t ON OBJECT_ID('dbo.'+t.TableName)=c.object_id
        LEFT JOIN dbo.Metadata_Column mc ON mc.TableName=t.TableName AND mc.ColumnName=c.name
        LEFT JOIN dbo.Metadata_Mapping mm ON mm.TargetTable=t.TableName AND mm.TargetColumn=c.name
        WHERE mc.ColumnName IS NULL OR mm.TargetColumn IS NULL''')==0)
        cubes=cuboid_count('ds')+cuboid_count('tk')
        check(f'{cubes} cuboids registered',scalar('SELECT COUNT(*) FROM dbo.Metadata_Cube')==cubes)
        check('14 hierarchy levels registered',scalar('SELECT COUNT(*) FROM dbo.Metadata_Hierarchy')==14)
        pk=[r[0] for r in cn.cursor().execute("SELECT c.name FROM sys.index_columns ic JOIN sys.indexes i ON i.object_id=ic.object_id AND i.index_id=ic.index_id JOIN sys.columns c ON c.object_id=ic.object_id AND c.column_id=ic.column_id WHERE i.is_primary_key=1 AND ic.object_id=OBJECT_ID('dbo.Fact_BanHang') ORDER BY ic.key_ordinal")]
        fks=sorted(r[0] for r in cn.cursor().execute("SELECT COL_NAME(fc.parent_object_id,fc.parent_column_id) FROM sys.foreign_key_columns fc WHERE fc.parent_object_id=OBJECT_ID('dbo.Fact_BanHang')"))
        check('Fact_BanHang key = its 4 dimension foreign keys',sorted(pk)==fks==['ch_key','kh_key','mh_key','ngay_key'])
        check('FK relationships catalog matches DW',scalar('SELECT COUNT(*) FROM dbo.Metadata_Relationship')==scalar("SELECT COUNT(*) FROM sys.foreign_key_columns fc JOIN dbo.Metadata_Table t ON OBJECT_NAME(fc.parent_object_id)=t.TableName"))
        for db,name in [('DW_Core','IX_BanHang_Customer'),('DW_Core','IX_BanHang_StoreProduct'),('DW_Core','IX_BanHang_Product'),('DW_Core','IX_Kho_StoreProductLatest'),('DW_Core','IX_Ngay_Month'),('DW_Core','IX_CuaHang_City'),('DW_Core','IX_KhachHang_Type'),('OLAP_QuanLyBanHang','IX_TK_MonthlyLookup'),('OLAP_QuanLyBanHang','IX_DS_DayStoreLookup'),('IDB_TichHop','IX_Integration_Run_StatusTime')]:
            check(f'Index {name} enabled',scalar(f"SELECT COUNT(*) FROM [{db}].sys.indexes WHERE name='{name}' AND is_disabled=0")==1)
    print(f'{passed}/{passed} IDB/metadata/index checks passed')
if __name__=='__main__':run()
