"""Oracle VPDD -> isolated SQL Server staging; bootstrap is demo-only and empty-only."""
import argparse
import hashlib
import json
import os
import re
from datetime import date, datetime
from pathlib import Path
import oracledb
import pyodbc
from dotenv import load_dotenv

ROOT = Path(__file__).resolve().parents[1]
load_dotenv(ROOT / 'dw-dm' / '.env')
load_dotenv(ROOT / '.env.oracle')
STAGE = 'STG_OracleVPDD'
TABLES = {
    'KhachHang': ['MaKH','TenKH','MaThanhPho','NgayDatHangDauTien'],
    'KhachHangDuLich': ['MaKH','HuongDanVienDuLich','ThoiGian'],
    'KhachHangBuuDien': ['MaKH','DiaChiBuuDien','ThoiGian'],
}

def sql_connection(database):
    if not re.fullmatch(r'[A-Za-z0-9_]+',database):
        raise ValueError('Invalid database name')
    auth = 'Trusted_Connection=yes;' if os.getenv('DB_TRUSTED','yes').lower() in ('1','true','yes') else f"UID={os.environ['DB_USER']};PWD={os.environ['DB_PASSWORD']};"
    return pyodbc.connect(f"DRIVER={{{os.getenv('DB_DRIVER','ODBC Driver 17 for SQL Server')}}};SERVER={os.getenv('DB_SERVER',r'.\MSSQLSERVER01')};DATABASE={database};{auth}TrustServerCertificate=yes;",timeout=30)

def oracle_connection():
    password = os.getenv('ORACLE_PASSWORD')
    if not password:
        password = Path(os.getenv('ORACLE_PASSWORD_FILE',str(ROOT/'oracle/secrets/app_password'))).read_text().strip()
    return oracledb.connect(user=os.getenv('ORACLE_USER','KDL_VPDD'),password=password,
        dsn=os.getenv('ORACLE_DSN','127.0.0.1:1522/FREEPDB1'),tcp_connect_timeout=30)

def normalize(value):
    if isinstance(value,datetime): return value.isoformat(timespec='microseconds')
    if isinstance(value,date): return datetime.combine(value,datetime.min.time()).isoformat(timespec='microseconds')
    return value

def canonical(rows):
    return sorted(json.dumps([normalize(x) for x in row],ensure_ascii=False,default=str) for row in rows)

def fingerprint(rows):
    return hashlib.sha256('\n'.join(canonical(rows)).encode('utf-8')).hexdigest()

def read_oracle():
    # One consistent database snapshot across all three tables.
    with oracle_connection() as cn:
        cn.cursor().execute('SET TRANSACTION READ ONLY')
        result={table:cn.cursor().execute(f"SELECT {','.join(columns)} FROM {table} ORDER BY MaKH").fetchall() for table,columns in TABLES.items()}
        version=cn.version
        cn.rollback()
    return result,version

def bootstrap():
    with oracle_connection() as ora:
        existing={row[0] for row in ora.cursor().execute('SELECT table_name FROM user_tables')}
        if existing.intersection(t.upper() for t in TABLES):
            raise RuntimeError('Oracle source tables already exist; bootstrap refuses to overwrite them.')
        ddl=(ROOT/'sql/oracle_vpdd.sql').read_text(encoding='utf-8-sig')
        ddl=re.sub(r'--[^\n]*','',ddl)
        for statement in ddl.split(';'):
            if statement.strip(): ora.cursor().execute(statement)
        with sql_connection('IDB_VPDD') as sql:
            for table,columns in TABLES.items():
                data=[tuple(row) for row in sql.cursor().execute(f"SELECT {','.join(columns)} FROM dbo.{table} ORDER BY MaKH")]
                marks=','.join(f':{i+1}' for i in range(len(columns)))
                ora.cursor().executemany(f"INSERT INTO {table} ({','.join(columns)}) VALUES ({marks})",data)
                print(f'Demo bootstrap -> Oracle {table}: {len(data)} rows')
        ora.commit()
    print('Bootstrap complete. Future extraction reads Oracle; SQL demo is not the customer authority.')

def prepare_stage():
    with sql_connection('master') as cn:
        cn.autocommit=True
        cn.cursor().execute(f"IF DB_ID('{STAGE}') IS NULL CREATE DATABASE [{STAGE}]")
    with sql_connection(STAGE) as cn:
        cn.cursor().execute("""
        IF OBJECT_ID('dbo.KhachHang') IS NULL CREATE TABLE dbo.KhachHang (
          MaKH INT PRIMARY KEY,TenKH NVARCHAR(100) NOT NULL,MaThanhPho INT NOT NULL,NgayDatHangDauTien DATE);
        IF OBJECT_ID('dbo.KhachHangDuLich') IS NULL CREATE TABLE dbo.KhachHangDuLich (
          MaKH INT PRIMARY KEY REFERENCES dbo.KhachHang(MaKH),HuongDanVienDuLich NVARCHAR(100),ThoiGian DATETIME2(6));
        IF OBJECT_ID('dbo.KhachHangBuuDien') IS NULL CREATE TABLE dbo.KhachHangBuuDien (
          MaKH INT PRIMARY KEY REFERENCES dbo.KhachHang(MaKH),DiaChiBuuDien NVARCHAR(200),ThoiGian DATETIME2(6));
        IF OBJECT_ID('dbo.ExtractAudit') IS NULL CREATE TABLE dbo.ExtractAudit (
          RunID INT IDENTITY PRIMARY KEY,ExtractedAt DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
          SourceDB NVARCHAR(100) NOT NULL,TableName NVARCHAR(100) NOT NULL,ExtractedRows INT NOT NULL,SHA256 CHAR(64) NOT NULL);
        """)
        cn.commit()

def extract():
    data,version=read_oracle()
    if not data['KhachHang']: raise RuntimeError('Empty Oracle customer source; refusing to erase staging.')
    prepare_stage()
    with sql_connection(STAGE) as cn:
        cur=cn.cursor()
        cur.execute('SET XACT_ABORT ON')
        for table in reversed(TABLES): cur.execute(f'DELETE FROM dbo.{table}')
        for table,columns in TABLES.items():
            marks=','.join('?' for _ in columns)
            cur.executemany(f"INSERT INTO dbo.{table} ({','.join(columns)}) VALUES ({marks})",data[table])
            cur.execute('INSERT INTO dbo.ExtractAudit(SourceDB,TableName,ExtractedRows,SHA256) VALUES (?,?,?,?)',
                f'Oracle {version}',table,len(data[table]),fingerprint(data[table]))
        # Reject cross-source orphan keys before committing a new staging snapshot.
        unknown_city=cur.execute('SELECT COUNT(*) FROM dbo.KhachHang k LEFT JOIN IDB_BanHang.dbo.VanPhongDaiDien v ON v.MaThanhPho=k.MaThanhPho WHERE v.MaThanhPho IS NULL').fetchone()[0]
        unknown_customer=cur.execute('SELECT COUNT(*) FROM IDB_BanHang.dbo.DonDatHang o LEFT JOIN dbo.KhachHang k ON k.MaKH=o.MaKH WHERE k.MaKH IS NULL').fetchone()[0]
        if unknown_city or unknown_customer:
            raise RuntimeError(f'Cross-source orphan keys: cities={unknown_city}, order customers={unknown_customer}; staging rolled back.')
        cn.commit()
    for table,rows in data.items(): print(f'Oracle -> {STAGE}.{table}: {len(rows)} rows; SHA256={fingerprint(rows)}')

def verify(check_dw=True):
    data,version=read_oracle()
    with sql_connection(STAGE) as cn:
        for table,columns in TABLES.items():
            actual=cn.cursor().execute(f"SELECT {','.join(columns)} FROM dbo.{table}").fetchall()
            if canonical(data[table])!=canonical(actual): raise AssertionError(f'Oracle/staging differs: {table}')
            print(f'[OK] Oracle {version} -> staging {table}: {len(actual)} rows')
    if check_dw:
        customers={row[0]:row for row in data['KhachHang']}
        dl={row[0]:row for row in data['KhachHangDuLich']}
        bd={row[0]:row for row in data['KhachHangBuuDien']}
        expected=[]
        for key,row in customers.items():
            kind='CaHai' if key in dl and key in bd else 'DuLich' if key in dl else 'BuuDien' if key in bd else 'Khac'
            expected.append((str(key),row[1],str(row[2]),row[3],key in dl,key in bd,dl[key][1] if key in dl else None,bd[key][1] if key in bd else None,kind))
        with sql_connection('DW_Core') as cn:
            actual=cn.cursor().execute('SELECT kh_key,ten,vp_key,ngay_dat_dau_tien,la_du_lich,la_buu_dien,huong_dan_vien,dia_chi_buu_dien,loai_kh FROM dbo.Dim_KhachHang').fetchall()
        if canonical(expected)!=canonical(actual): raise AssertionError('Oracle -> Dim_KhachHang differs')
        print(f'[OK] Oracle -> galaxy Dim_KhachHang: {len(actual)} rows, all attributes')
    print('Oracle verification passed')

if __name__=='__main__':
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('action',choices=['bootstrap-demo','extract','verify','verify-stage'])
    args=parser.parse_args()
    if args.action=='bootstrap-demo':bootstrap()
    elif args.action=='extract':extract()
    else:verify(args.action=='verify')
