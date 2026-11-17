"""Focused API regressions; SQL is stubbed so invalid requests never need a DB."""
import sys
from pathlib import Path
from unittest.mock import patch, MagicMock
from decimal import Decimal
sys.path.insert(0, str(Path(__file__).resolve().parents[1] / 'dw-dm'))
import main
from fastapi.testclient import TestClient

def run():
    count = 0
    with TestClient(main.app, raise_server_exceptions=False) as client:
        with patch.object(main, 'query_all', return_value=[]):
            for start, end in [('nam','quy'), ('nam','nam'), ('invalid','nam'), ('thang','thang')]:
                response = client.get('/api/olap/roll-up', params={'cube':'ds','tu':start,'len':end})
                assert response.status_code == 400, (start, end, response.status_code)
                count += 1
            for start, end in [('thang','quy'), ('thang','nam'), ('quy','nam')]:
                assert client.get('/api/olap/roll-up', params={'cube':'tk','tu':start,'len':end}).status_code == 200
                count += 1
            assert client.get('/api/olap/slice', params={'cube':'ds','chieu':'nam','gia_tri':'abc'}).status_code == 400
            count += 1
        rows = [dict(nam=2022,mh_key=key,mo_ta='Product',tong_doanh_thu=1) for key in ['10','2','1']]
        with patch.object(main, 'query_all', return_value=rows):
            result = client.get('/api/olap/pivot', params={'cube':'ds','hang':'mh','cot':'nam'}).json()
            assert result['labels_hang'] == ['1','2','10'], result
            count += 1
        bad = client.options('/api/bao-cao/meta', headers={'Origin':'https://untrusted.example','Access-Control-Request-Method':'GET'})
        assert bad.status_code == 400 and 'access-control-allow-origin' not in bad.headers
        count += 1
        good = client.options('/api/bao-cao/meta', headers={'Origin':'http://localhost:3000','Access-Control-Request-Method':'GET'})
        assert good.headers.get('access-control-allow-origin') == 'http://localhost:3000'
        count += 1
        amount = Decimal('9999999999999999.99')
        cursor = MagicMock()
        cursor.description = [('tong_doanh_thu',)]
        cursor.fetchall.return_value = [(amount,)]
        with patch.object(main, 'get_cursor') as connection:
            connection.return_value.__enter__.return_value = cursor
            result = client.get('/api/doanh-so/tong').json()
            assert result['tong_doanh_thu'] == str(amount), result
            count += 1
        with patch.object(main, 'query_all', return_value=[dict(nam=2022,mh_key='1',mo_ta='Product',tong_doanh_thu=amount)]):
            result = client.get('/api/olap/pivot', params={'cube':'ds','hang':'nam','cot':'mh'}).json()
            assert result['matrix'] == [[str(amount)]], result
            count += 1
        with patch.object(main, 'query_all', side_effect=[
            [dict(nam=2023,tong_doanh_thu=amount),dict(nam=2024,tong_doanh_thu=Decimal('0.00'))],
            [dict(nam=2023,tong_ton_kho=0)],
        ]):
            result = client.get('/api/olap/drill-across').json()
            assert result[0]['tong_doanh_thu'] == str(amount), result
            assert result[0]['tong_ton_kho'] == 0, result
            assert result[1]['tong_ton_kho'] is None, result
            assert result[1]['tong_doanh_thu'] == '0.00', result
            count += 1
    print(f'{count}/{count} API contract/security regressions passed')

if __name__ == '__main__': run()
