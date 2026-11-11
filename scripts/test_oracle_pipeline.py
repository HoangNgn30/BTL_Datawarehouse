"""Real integration tests: Oracle authority, Unicode and failed extraction rollback."""
import subprocess
from oracle_sync import ROOT,STAGE,oracle_connection,sql_connection,extract,verify,canonical

def etl():
    for script in ['01c_integrate_idb.sql','02_etl_dw_core.sql','02b_dw_indexes.sql']:
        subprocess.run(['sqlcmd','-S',__import__('os').getenv('DB_SERVER',r'.\MSSQLSERVER01'),'-E','-C','-b','-f','65001','-v','CustomerSource='+STAGE,'-i',str(ROOT/'sql'/script)],check=True,stdout=subprocess.DEVNULL)

def stage_rows():
    with sql_connection(STAGE) as cn:
        return canonical(cn.cursor().execute('SELECT MaKH,TenKH,MaThanhPho,NgayDatHangDauTien FROM dbo.KhachHang').fetchall())

def run():
    with oracle_connection() as ora:
        cur=ora.cursor()
        old=cur.execute('SELECT TenKH,MaThanhPho FROM KhachHang WHERE MaKH=1').fetchone()
        try:
            cur.execute('UPDATE KhachHang SET TenKH=:1 WHERE MaKH=1',['Khách hàng Nguyễn Ánh — kiểm thử Oracle'])
            ora.commit()
            extract();etl();verify()
            with sql_connection('DW_Core') as cn:
                actual=cn.cursor().execute("SELECT ten FROM dbo.Dim_KhachHang WHERE kh_key='1'").fetchone()[0]
            assert actual=='Khách hàng Nguyễn Ánh — kiểm thử Oracle'
            print('[OK] Oracle change propagates to DW; Unicode preserved')
            before=stage_rows()
            cur.execute('UPDATE KhachHang SET MaThanhPho=999999 WHERE MaKH=1');ora.commit()
            try: extract()
            except RuntimeError as error:
                assert 'orphan keys' in str(error)
            else: raise AssertionError('Invalid source unexpectedly committed')
            assert before==stage_rows()
            print('[OK] Cross-source orphan rejected; staging transaction rolled back')
        finally:
            cur.execute('UPDATE KhachHang SET TenKH=:1,MaThanhPho=:2 WHERE MaKH=1',old)
            ora.commit()
            extract();etl();verify()
    print('2/2 Oracle integration regressions passed; source restored')
if __name__=='__main__':run()
