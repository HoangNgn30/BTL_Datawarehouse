"""Integration regressions against an initialized SQL Server (DB_* environment)."""
import sys
from pathlib import Path
from itertools import product
sys.path.insert(0,str(Path(__file__).resolve().parents[1]/'dw-dm'))
from main import app, query_all, DB_DW
from cube_schema import SALES_AXES, INVENTORY_AXES
from fastapi.testclient import TestClient

def run():
    checked = 0
    with TestClient(app) as client:
        def get(path, params=None, status=200):
            nonlocal checked
            r=client.get(path,params=params)
            assert r.status_code == status, (path,params,r.status_code,r.text[:300])
            checked+=1
            return r.json() if 'application/json' in r.headers.get('content-type','') else r.text
        # Every cuboid of both lattices is reachable through the API.
        for t,p,k,l in product(*(levels for _,_,levels in SALES_AXES)):
            res=get('/api/doanh-so/v2',dict(time_axis=t,mh_axis=p,kh_axis=k,loc_axis=l,limit=5))
            assert len(res['data']) <= 5 and res['tong_so_dong'] >= len(res['data'])
        for t,p,l in product(*(levels for _,_,levels in INVENTORY_AXES)):
            get('/api/ton-kho/v2',dict(time_axis=t,mh_axis=p,loc_axis=l,limit=5))
        for path,params in [
            ('/api/doanh-so',dict(nhom='loai_kh',loc_nam=2022)),
            ('/api/doanh-so',dict(nhom='kh',loc_mh='1',limit=50)),
            ('/api/doanh-so',dict(nhom='nam',loc_quy=2)),
            ('/api/doanh-so',dict(nhom='tp',loc_bang='Texas')),
            ('/api/doanh-so',dict(nhom='ch',loc_nam=2022,loc_loai_kh='DuLich')),
            ('/api/ton-kho',dict(nhom='tinh',loc_mh='1')),
            ('/api/ton-kho',dict(nhom='nam',loc_quy=2)),
            ('/api/olap/slice',dict(cube='ds',chieu='nam',gia_tri='2022')),
            ('/api/olap/slice',dict(cube='ds',chieu='bang',gia_tri='Texas')),
            ('/api/olap/dice',dict(cube='ds',nhom='tp',loc_nam=2022,loc_bang='California',loc_loai_kh='DuLich')),
            ('/api/olap/drill-down',dict(cube='ds',xuong='ch',loc_bang='Texas')),
            ('/api/olap/drill-down',dict(cube='ds',xuong='ngay',loc_nam=2022,loc_quy=1)),
            ('/api/olap/drill-through',dict(nam=2022,quy=2,limit=5)),
            ('/api/olap/drill-through',dict(ch_key='1',bang='New York',limit=5)),
            ('/api/olap/drill-through-kho',dict(nam=2022,quy=2,limit=5)),
            ('/api/olap/drill-across',dict(nhom='quy')),
            ('/api/olap/drill-across',dict(nhom='nam',vi_tri='tinh')),
            ('/api/olap/roll-up',dict(cube='tk',tu='thang',len='quy')),
            ('/api/olap/roll-up',dict(cube='ds',tu='ch',len='tinh')),
            ('/api/olap/roll-up',dict(cube='ds',tu='ngay',len='thang'))]:
            get(path,params)
        get('/api/olap/roll-up',dict(cube='tk',tu='ngay',len='thang'),400)
        get('/api/olap/roll-up',dict(cube='ds',tu='ch',len='nam'),400)
        get('/api/ton-kho/v2',dict(time_axis='ngay'),400)
        # Roll-up along location adds stores into their state; the total never changes.
        stores=get('/api/doanh-so',dict(nhom='ch'))['data']
        states=get('/api/doanh-so',dict(nhom='tinh'))['data']
        total=get('/api/doanh-so/tong')
        from decimal import Decimal
        assert sum(Decimal(r['tong_doanh_thu']) for r in stores)==sum(Decimal(r['tong_doanh_thu']) for r in states)==Decimal(total['tong_doanh_thu'])
        for pair in [('nam','mh'),('nam','loai_kh'),('bang','nam'),('loai_kh','bang')]:
            a=get('/api/olap/pivot',dict(cube='ds',hang=pair[0],cot=pair[1]))
            b=get('/api/olap/pivot',dict(cube='ds',hang=pair[1],cot=pair[0]))
            assert a['matrix'] == list(map(list,zip(*b['matrix']))), pair
        get('/api/olap/pivot',dict(cube='ds',hang='nam',cot='nam'),400)
        across=get('/api/olap/drill-across',dict(nhom='nam',vi_tri='tinh'))
        assert all(r['tong_ton_kho'] is not None for r in across)
        for i,params in enumerate(({},dict(kh='1'),dict(kh='1'),dict(mh='1'),dict(ma_don='1'),dict(kh='1'),dict(mh='1',tp='1'),dict(ma_don='1'),dict(loai='ca_hai')),1):
            assert get(f'/api/bao-cao/{i}',params), f'Empty report {i}'
        get('/api/bao-cao/9',dict(loai='du_lich'))
        get('/api/bao-cao/9',dict(loai='buu_dien'))
        get('/api/bao-cao/9',dict(loai='invalid'),400)
        meta=get('/api/bao-cao/meta')
        for category,key in [('khach_hang','kh_key'),('mat_hang','mh_key'),('cua_hang','ch_key'),('thanh_pho','vp_key')]:
            ids=[int(row[key]) for row in meta[category]]
            assert ids == sorted(ids), (category,ids[:12])
        assert meta['don_hang']['min'] == 1 and meta['don_hang']['so_don'] >= 50000, meta['don_hang']
        report=get('/api/bao-cao/1')
        keys=[(int(r['ch_key']),int(r['mh_key'])) for r in report]
        assert keys == sorted(keys)
        customers=get('/api/bao-cao/9',dict(loai='ca_hai'))
        assert [int(r['kh_key']) for r in customers] == sorted(int(r['kh_key']) for r in customers)
        get('/api/doanh-so/v2',dict(time_axis='invalid'),400)
        get('/api/ton-kho/v2',dict(loc_quy=1,loc_thang=7),400)
        get('/api/olap/drill-through',dict(limit=-1),422)
        # A year grouped query filtered to Q2 must return the Q2 closing balance.
        actual=get('/api/ton-kho/v2',dict(time_axis='nam',loc_nam=2022,loc_quy=2))['data'][0]['tong_ton_kho']
        expected=query_all(DB_DW,'SELECT SUM(so_luong) n FROM Fact_Kho WHERE time_key=202206')[0]['n']
        assert actual == expected
        get('/');get('/bao-cao')
    print(f'{checked} API/UI checks passed')
if __name__=='__main__':run()
