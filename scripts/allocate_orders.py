"""Phan bo don hang, ghi so cai ton kho va so du cuoi thang tai nguon IDB_BanHang.

Quy tac (tai lap duoc, khong ngau nhien):
- Ton trong MatHangLuuTru truoc khi chay la ton dau ky ngay 01/01/2021 va cung la muc ton muc tieu.
- Dau moi thang (tu thang 2/2021), cap cua hang-mat hang nao con duoi 30% muc muc tieu thi nhap bo sung
  len dung muc muc tieu.
- Dong don duoc xu ly theo ngay dat, ma don, ma mat hang. Lay hang o cac cua hang cung thanh pho voi khach
  truoc, sau do cac thanh pho khac; trong cung muc uu tien chon cua hang con nhieu hang nhat roi ma nho nhat.
  Mot dong don co the duoc tach cho nhieu cua hang. Neu ca mang luoi thieu hang thi dung lai, khong cap am.
- TonKhoThang = so du cuoi moi thang; MatHangLuuTru duoc cap nhat thanh ton hien tai (cuoi ky).
"""
import os
import sys
from collections import defaultdict
from datetime import date, timedelta
from oracle_sync import sql_connection

RESTOCK_RATIO = 0.30
FIRST_MONTH = 202101


def month_key(day):
    return day.year * 100 + day.month


def next_month(key):
    year, month = divmod(key, 100)
    return (year + 1) * 100 + 1 if month == 12 else key + 1


def first_day(key):
    return date(key // 100, key % 100, 1)


def run():
    customer_source = os.getenv('DB_ALLOCATION_CUSTOMER_SOURCE', 'IDB_VPDD')
    if customer_source not in ('IDB_VPDD', 'STG_OracleVPDD'):
        raise ValueError('Unsupported customer source')
    with sql_connection('IDB_BanHang') as cn:
        cur = cn.cursor()
        if cur.execute('SELECT COUNT(*) FROM dbo.PhanBoDonHang').fetchone()[0]:
            raise RuntimeError('Nguon da duoc phan bo. Tao lai nguon demo bang -ResetDemo truoc khi chay lai.')
        store_city = dict(cur.execute('SELECT MaCuaHang, MaThanhPho FROM dbo.CuaHang').fetchall())
        target = {(s, p): q for s, p, q in cur.execute(
            'SELECT MaCuaHang, MaMH, SoLuongTrongKho FROM dbo.MatHangLuuTru').fetchall()}
        lines = cur.execute(f'''
            SELECT o.NgayDatHang, o.MaDon, d.MaMH, d.SoLuongDat, k.MaThanhPho
            FROM dbo.DonDatHang o JOIN dbo.MatHangDuocDat d ON d.MaDon = o.MaDon
            JOIN [{customer_source}].dbo.KhachHang k ON k.MaKH = o.MaKH
            ORDER BY o.NgayDatHang, o.MaDon, d.MaMH''').fetchall()
        if not lines:
            raise RuntimeError('Khong co dong don hang de phan bo.')

        stock = dict(target)
        stores_of = defaultdict(list)
        for store, product in target:
            stores_of[product].append(store)
        ledger, allocations, snapshots = [], [], []

        def add_ledger(store, product, day, kind, quantity, order=None):
            ledger.append((len(ledger) + 1, store, product, day, kind, quantity, order))

        for (store, product), quantity in sorted(target.items()):
            add_ledger(store, product, date(2021, 1, 1), 'DAUKY', quantity)

        by_month = defaultdict(list)
        for line in lines:
            by_month[month_key(line[0])].append(line)
        last_month = max(by_month)
        month = FIRST_MONTH
        restocks = 0
        while month <= last_month:
            if month != FIRST_MONTH:
                for pair in sorted(stock):
                    if stock[pair] < RESTOCK_RATIO * target[pair]:
                        add_ledger(*pair, first_day(month), 'NHAP', target[pair] - stock[pair])
                        stock[pair] = target[pair]
                        restocks += 1
            for day, order, product, quantity, city in by_month.get(month, []):
                remaining = quantity
                while remaining:
                    candidates = [s for s in stores_of[product] if stock[(s, product)] > 0]
                    if not candidates:
                        raise RuntimeError(f'Khong du hang cho don {order}, mat hang {product}.')
                    store = min(candidates, key=lambda s: (store_city[s] != city, -stock[(s, product)], s))
                    take = min(remaining, stock[(store, product)])
                    stock[(store, product)] -= take
                    remaining -= take
                    allocations.append((order, product, store, take))
                    add_ledger(store, product, day, 'XUAT', -take, order)
            for (store, product), quantity in sorted(stock.items()):
                snapshots.append((month, store, product, quantity))
            month = next_month(month)

        merged = defaultdict(int)
        for order, product, store, take in allocations:
            merged[(order, product, store)] += take
        allocation_rows = [(*key, value) for key, value in merged.items()]

        cur.fast_executemany = True
        cur.executemany('INSERT dbo.PhanBoDonHang (MaDon, MaMH, MaCuaHang, SoLuongCap) VALUES (?,?,?,?)', allocation_rows)
        cur.executemany('INSERT dbo.BienDongKho (MaBienDong, MaCuaHang, MaMH, Ngay, Loai, SoLuong, MaDon) VALUES (?,?,?,?,?,?,?)', ledger)
        cur.executemany('INSERT dbo.TonKhoThang (ThangKey, MaCuaHang, MaMH, SoLuong) VALUES (?,?,?,?)', snapshots)
        cur.executemany('UPDATE dbo.MatHangLuuTru SET SoLuongTrongKho = ?, ThoiGian = ? WHERE MaCuaHang = ? AND MaMH = ?',
                        [(quantity, first_day(next_month(last_month)) - timedelta(days=1), store, product)
                         for (store, product), quantity in stock.items()])
        cn.commit()
    print(f'Order lines: {len(lines)}; allocations: {len(allocation_rows)}; '
          f'ledger: {len(ledger)} (restocks: {restocks}); monthly snapshots: {len(snapshots)}')


if __name__ == '__main__':
    sys.exit(run())
