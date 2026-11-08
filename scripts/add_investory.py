import pyodbc
import random

conn = pyodbc.connect(
    "DRIVER={ODBC Driver 17 for SQL Server};"  # đổi driver này
    "SERVER=localhost;"
    "DATABASE=DW_Core;"
    "UID=sa;"           # thêm dòng này
    "PWD=123456;"  # thêm mật khẩu sa của bạn
)
cursor = conn.cursor()

# Tất cả các tháng cần có (khớp với Fact_BanHang)
all_months = []
for y in range(2021, 2024):       # 2021, 2022, 2023
    for m in range(1, 13):
        all_months.append(y * 100 + m)   # 202101 ... 202312

# Đọc snapshot gốc (anchor point)
cursor.execute("""
    SELECT ch_key, mh_key, time_key, so_luong
    FROM Fact_Kho
""")
rows = cursor.fetchall()

# Nhóm theo (ch_key, mh_key) → lấy time_key mới nhất làm anchor
from collections import defaultdict
anchor = {}   # (ch_key, mh_key) → (time_key, so_luong)
for ch, mh, tk, sl in rows:
    key = (ch, mh)
    if key not in anchor or tk > anchor[key][0]:
        anchor[key] = (tk, sl)

# Đọc các key đã tồn tại để không INSERT trùng
cursor.execute("SELECT time_key, ch_key, mh_key FROM Fact_Kho")
existed = set((r[0], r[1], r[2]) for r in cursor.fetchall())

# Sinh data ngược từ anchor về 202101
batch = []
for (ch_key, mh_key), (anchor_tk, anchor_sl) in anchor.items():
    # Sắp xếp all_months theo thứ tự ngược (từ mới → cũ)
    months_desc = sorted(all_months, reverse=True)
    
    sl_prev = anchor_sl  # bắt đầu từ anchor
    for tk in months_desc:
        if tk == anchor_tk:
            sl_prev = anchor_sl   # giữ nguyên điểm neo
            continue
        if (tk, ch_key, mh_key) in existed:
            continue
        
        if tk < anchor_tk:
            # Đi ngược về quá khứ: tháng cũ hơn thường tồn kho thấp hơn 1 chút
            sl_new = max(1, int(sl_prev * random.uniform(0.88, 1.12)))
        else:
            # Nếu có tháng sau anchor (không có ở đây nhưng phòng trường hợp)
            sl_new = max(1, int(sl_prev * random.uniform(0.90, 1.10)))
        
        batch.append((tk, ch_key, mh_key, sl_new))
        sl_prev = sl_new  # chain tiếp tháng trước đó

# INSERT batch
cursor.fast_executemany = True
total = len(batch)
for i in range(0, total, 1000):
    cursor.executemany(
        "INSERT INTO Fact_Kho(time_key, ch_key, mh_key, so_luong) VALUES (?,?,?,?)",
        batch[i:i+1000]
    )
    conn.commit()
    print(f"  {min(i+1000, total)}/{total} dòng")

print(f"Xong! Đã thêm {total} dòng.")
conn.close()