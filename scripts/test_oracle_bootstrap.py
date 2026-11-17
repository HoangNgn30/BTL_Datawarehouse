"""Bootstrap recovery tests against database adapters, without touching real sources."""
from datetime import date, datetime
import re
import unittest
from unittest.mock import patch
import oracle_sync

SOURCE = {
    'KHACHHANG': [(1, 'Customer', 1, date(2021,1,1))],
    'KHACHHANGDULICH': [(1, 'Guide', datetime(2021,1,1))],
    'KHACHHANGBUUDIEN': [(1, 'Address', datetime(2021,1,1))],
}

class Rows(list):
    def fetchone(self): return self[0]

class SQLSource:
    def __enter__(self): return self
    def __exit__(self,*args): pass
    def cursor(self): return self
    def execute(self,sql):
        name=re.search(r'FROM dbo\.(\w+)',sql,re.I).group(1).upper()
        return Rows(SOURCE[name])

class OracleSource:
    def __init__(self,tables=None,fail_insert=None,fail_create=None):
        self.tables = tables or {}
        self.pending=[]
        self.fail_insert=fail_insert
        self.fail_create=fail_create
    def __enter__(self): return self
    def __exit__(self,*args): self.rollback()
    def cursor(self): return self
    def execute(self,sql):
        sql=sql.strip()
        if 'FROM user_tables' in sql: return Rows((name,) for name in self.tables)
        if sql.upper().startswith('CREATE TABLE'):
            name=re.match(r'CREATE TABLE\s+(\w+)',sql,re.I).group(1).upper()
            if name==self.fail_create:
                self.fail_create=None
                raise RuntimeError('DDL interrupted')
            assert name not in self.tables
            self.tables[name]=[]  # Oracle DDL survives a later DML rollback.
            return Rows()
        name=re.search(r'FROM\s+(\w+)',sql,re.I).group(1).upper()
        if 'COUNT(*)' in sql.upper(): return Rows([(len(self.tables[name]),)])
        assert name in self.tables
        return Rows()  # Empty schema compatibility query.
    def executemany(self,sql,rows):
        name=re.search(r'INSERT INTO\s+(\w+)',sql,re.I).group(1).upper()
        if name==self.fail_insert:
            self.fail_insert=None
            raise RuntimeError('Insert interrupted')
        self.pending.extend((name,tuple(row)) for row in rows)
    def commit(self):
        for name,row in self.pending:self.tables[name].append(row)
        self.pending=[]
    def rollback(self): self.pending=[]

class BootstrapTests(unittest.TestCase):
    def run_bootstrap(self,oracle):
        with patch.object(oracle_sync,'oracle_connection',return_value=oracle),patch.object(oracle_sync,'sql_connection',return_value=SQLSource()):
            oracle_sync.bootstrap()
    def assert_loaded(self,oracle):
        self.assertEqual(oracle.tables,SOURCE)
    def test_source_unavailable_does_not_create_tables(self):
        oracle=OracleSource()
        with patch.object(oracle_sync,'oracle_connection',return_value=oracle),patch.object(oracle_sync,'sql_connection',side_effect=RuntimeError('SQL unavailable')):
            with self.assertRaisesRegex(RuntimeError,'SQL unavailable'): oracle_sync.bootstrap()
        self.assertEqual(oracle.tables,{})
    def test_resume_empty_partial_schema(self):
        oracle=OracleSource({'KHACHHANG':[]})
        self.run_bootstrap(oracle);self.assert_loaded(oracle)
    def test_empty_seed_does_not_create_tables(self):
        oracle=OracleSource()
        with patch.dict(SOURCE,{'KHACHHANG':[]}):
            with self.assertRaisesRegex(RuntimeError,'Empty SQL customer seed'): self.run_bootstrap(oracle)
        self.assertEqual(oracle.tables,{})
    def test_existing_data_is_never_overwritten(self):
        oracle=OracleSource({'KHACHHANG':[(999,'Keep this source')]})
        with self.assertRaisesRegex(RuntimeError,'already exist'): self.run_bootstrap(oracle)
        self.assertEqual(oracle.tables,{'KHACHHANG':[(999,'Keep this source')]})
    def test_insert_failure_rolls_back_and_retry_succeeds(self):
        oracle=OracleSource(fail_insert='KHACHHANGDULICH')
        with self.assertRaisesRegex(RuntimeError,'Insert interrupted'): self.run_bootstrap(oracle)
        self.assertTrue(all(not rows for rows in oracle.tables.values()))
        self.run_bootstrap(oracle);self.assert_loaded(oracle)
    def test_ddl_failure_can_be_retried(self):
        oracle=OracleSource(fail_create='KHACHHANGDULICH')
        with self.assertRaisesRegex(RuntimeError,'DDL interrupted'): self.run_bootstrap(oracle)
        self.assertEqual(oracle.tables,{'KHACHHANG':[]})
        self.run_bootstrap(oracle);self.assert_loaded(oracle)

if __name__=='__main__':unittest.main()
