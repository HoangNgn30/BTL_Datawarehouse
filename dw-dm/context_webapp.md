# CONTEXT — WEB APP OLAP QUẢN LÝ BÁN HÀNG

## 1. TỔNG QUAN DỰ ÁN

Đây là web app phục vụ demo đồ án môn **Kho Dữ Liệu & Khai Phá Dữ Liệu**.
Mục tiêu: truy vấn các bảng cuboid đã tính sẵn trong DB OLAP, hiển thị biểu đồ
và demo 7 phép toán OLAP cho giảng viên.

### Stack
- **Backend**: Python + FastAPI
- **Frontend**: HTML + JavaScript thuần + Chart.js
- **DB**: SQL Server (kết nối qua `pyodbc`)
- **Không dùng**: React, Vue, build tool, Node.js

---

## 2. CẤU TRÚC DB

### 2.1 DB nguồn: `OLAP_QuanLyBanHang`
Chứa 56 bảng cuboid đã tính sẵn (GROUP BY trước).

#### Sales Cube — prefix `olap_ds_`
Measures: `tong_so_luong`, `tong_doanh_thu`

| Tên bảng | Các cột GROUP BY |
|----------|-----------------|
| `olap_ds_all` | (không có) |
| `olap_ds_nam` | nam |
| `olap_ds_quy` | nam, quy |
| `olap_ds_thang` | nam, quy, thang |
| `olap_ds_mh` | mh_key, mo_ta, kich_co, gia |
| `olap_ds_loai_kh` | loai_kh |
| `olap_ds_kh` | kh_key, ten, loai_kh |
| `olap_ds_nam_mh` | nam, mh_key, mo_ta |
| `olap_ds_quy_mh` | nam, quy, mh_key, mo_ta |
| `olap_ds_thang_mh` | nam, quy, thang, mh_key, mo_ta |
| `olap_ds_nam_loai_kh` | nam, loai_kh |
| `olap_ds_quy_loai_kh` | nam, quy, loai_kh |
| `olap_ds_thang_loai_kh` | nam, quy, thang, loai_kh |
| `olap_ds_nam_kh` | nam, kh_key, ten, loai_kh |
| `olap_ds_quy_kh` | nam, quy, kh_key, ten, loai_kh |
| `olap_ds_thang_kh` | nam, quy, thang, kh_key, ten, loai_kh |
| `olap_ds_mh_loai_kh` | mh_key, mo_ta, loai_kh |
| `olap_ds_mh_kh` | mh_key, mo_ta, kh_key, ten, loai_kh |
| `olap_ds_loai_kh_kh` | loai_kh, kh_key, ten |
| `olap_ds_nam_mh_loai_kh` | nam, mh_key, mo_ta, loai_kh |
| `olap_ds_quy_mh_loai_kh` | nam, quy, mh_key, mo_ta, loai_kh |
| `olap_ds_thang_mh_loai_kh` | nam, quy, thang, mh_key, mo_ta, loai_kh |
| `olap_ds_nam_mh_kh` | nam, mh_key, mo_ta, kh_key, ten, loai_kh |
| `olap_ds_thang_mh_kh` | nam, quy, thang, mh_key, mo_ta, kh_key, ten, loai_kh |

#### Inventory Cube — prefix `olap_tk_`
Measure: `tong_ton_kho`

| Tên bảng | Các cột GROUP BY |
|----------|-----------------|
| `olap_tk_all` | (không có) |
| `olap_tk_nam` | nam |
| `olap_tk_quy` | nam, quy |
| `olap_tk_thang` | nam, quy, thang |
| `olap_tk_mh` | mh_key, mo_ta |
| `olap_tk_tinh` | bang |
| `olap_tk_tp` | bang, ten_tp |
| `olap_tk_ch` | ch_key |
| `olap_tk_nam_mh` | nam, mh_key, mo_ta |
| `olap_tk_quy_mh` | nam, quy, mh_key, mo_ta |
| `olap_tk_thang_mh` | nam, quy, thang, mh_key, mo_ta |
| `olap_tk_nam_tinh` | nam, bang |
| `olap_tk_quy_tinh` | nam, quy, bang |
| `olap_tk_thang_tinh` | nam, quy, thang, bang |
| `olap_tk_nam_tp` | nam, bang, ten_tp |
| `olap_tk_quy_tp` | nam, quy, bang, ten_tp |
| `olap_tk_thang_tp` | nam, quy, thang, bang, ten_tp |
| `olap_tk_nam_ch` | nam, ch_key |
| `olap_tk_quy_ch` | nam, quy, ch_key |
| `olap_tk_thang_ch` | nam, quy, thang, ch_key |
| `olap_tk_mh_tinh` | mh_key, mo_ta, bang |
| `olap_tk_mh_tp` | mh_key, mo_ta, bang, ten_tp |
| `olap_tk_mh_ch` | mh_key, mo_ta, ch_key |
| `olap_tk_nam_mh_tinh` | nam, mh_key, mo_ta, bang |
| `olap_tk_quy_mh_tinh` | nam, quy, mh_key, mo_ta, bang |
| `olap_tk_thang_mh_tinh` | nam, quy, thang, mh_key, mo_ta, bang |
| `olap_tk_nam_mh_tp` | nam, mh_key, mo_ta, bang, ten_tp |
| `olap_tk_quy_mh_tp` | nam, quy, mh_key, mo_ta, bang, ten_tp |
| `olap_tk_thang_mh_tp` | nam, quy, thang, mh_key, mo_ta, bang, ten_tp |
| `olap_tk_nam_mh_ch` | nam, mh_key, mo_ta, ch_key |
| `olap_tk_quy_mh_ch` | nam, quy, mh_key, mo_ta, ch_key |
| `olap_tk_thang_mh_ch` | nam, quy, thang, mh_key, mo_ta, ch_key |

### 2.2 DB kho: `DW_Core`
Dùng cho drill-through (truy vấn giao dịch gốc).

```
Fact_BanHang(time_key, kh_key, mh_key, so_luong, tong_tien)
Dim_ThoiGian(time_key, thang, quy, nam)
Dim_KhachHang(kh_key, ten, loai_kh)
Dim_MatHang(mh_key, mo_ta, kich_co, trong_luong, gia)
Dim_CuaHang(ch_key, so_dt, vp_key)
Dim_VPDD(vp_key, ten_tp, dia_chi_vp, bang)
```

---

## 3. BACKEND (FastAPI)

### 3.1 Kết nối DB

```python
import pyodbc

CONN_STR_OLAP = (
    "DRIVER={ODBC Driver 17 for SQL Server};"
    "SERVER=localhost;"
    "DATABASE=OLAP_QuanLyBanHang;"
    "UID=sa;"
    "PWD=YOUR_PASSWORD;"
)

CONN_STR_DW = (
    "DRIVER={ODBC Driver 17 for SQL Server};"
    "SERVER=localhost;"
    "DATABASE=DW_Core;"
    "UID=sa;"
    "PWD=YOUR_PASSWORD;"
)
```

### 3.2 Danh sách API cần implement

#### Nhóm 1 — Metadata (build filter UI động)
```
GET /api/metadata/nam          → [2021, 2022, 2023]
GET /api/metadata/loai-kh      → ["BuuDien", "DuLich"]
GET /api/metadata/mat-hang     → [{mh_key, mo_ta}]
GET /api/metadata/tinh         → [bang1, bang2, ...]
```

#### Nhóm 2 — Sales Cube
```
GET /api/doanh-so/tong
    → {tong_so_luong, tong_doanh_thu}

GET /api/doanh-so
    Query params:
      nhom      : "nam" | "quy" | "thang" | "mh" | "loai_kh" | "kh"  (bắt buộc)
      loc_nam   : int (optional filter)
      loc_quy   : int (optional filter)
      loc_loai_kh: str (optional filter)
      loc_mh    : str (optional filter)
    → [{...dimensions, tong_so_luong, tong_doanh_thu}]
```

#### Nhóm 3 — Inventory Cube
```
GET /api/ton-kho/tong
    → {tong_ton_kho}

GET /api/ton-kho
    Query params:
      nhom    : "nam" | "quy" | "thang" | "mh" | "tinh" | "tp" | "ch"  (bắt buộc)
      loc_nam : int (optional)
      loc_bang: str (optional)
      loc_mh  : str (optional)
    → [{...dimensions, tong_ton_kho}]
```

#### Nhóm 4 — 7 phép toán OLAP
```
GET /api/olap/roll-up
    Params: cube ("ds"|"tk"), tu ("thang"|"quy"|"tp"|"ch"), len ("quy"|"nam"|"tinh")
    → gọi lại /api/doanh-so hoặc /api/ton-kho với nhom=level cao hơn

GET /api/olap/drill-down
    Params: cube, tu ("nam"|"quy"|"tinh"), xuong ("quy"|"thang"|"tp"), filters...
    → gọi lại với nhom=level thấp hơn + filter cụ thể

GET /api/olap/slice
    Params: cube, chieu ("nam"|"loai_kh"|"bang"...), gia_tri
    → gọi /api/doanh-so hoặc /api/ton-kho với 1 filter cố định

GET /api/olap/dice
    Params: cube, nam, quy, loai_kh, bang, mh_key (tùy chọn nhiều)
    → gọi lại với nhiều filter đồng thời

GET /api/olap/pivot
    Params: cube, hang ("nam"|"loai_kh"|"mh"), cot ("loai_kh"|"nam"|"bang")
    → trả matrix: {labels_hang, labels_cot, data: [[...]]}

GET /api/olap/drill-across
    Params: nhom ("nam"|"quy"|"thang")
    → kết hợp doanh-so + ton-kho cùng chiều thời gian
    → [{nam, tong_doanh_thu, tong_ton_kho}]

GET /api/olap/drill-through
    Params: kh_key, mh_key, nam (optional)
    → query thẳng DW_Core.Fact_BanHang (KHÔNG qua cuboid)
    → [{time_key, so_luong, tong_tien, ten_kh, mo_ta_mh}]
```

### 3.3 Cuboid Routing Logic

Backend tự chọn bảng cuboid dựa trên `nhom` + filters có mặt:

```python
def chon_cuboid_ds(nhom, co_loai_kh, co_kh, co_mh):
    is_time = nhom in ["nam", "quy", "thang"]
    if is_time:
        if co_kh  and co_mh:      return f"olap_ds_{nhom}_mh_kh"
        if co_loai_kh and co_mh:  return f"olap_ds_{nhom}_mh_loai_kh"
        if co_kh:                 return f"olap_ds_{nhom}_kh"
        if co_loai_kh:            return f"olap_ds_{nhom}_loai_kh"
        if co_mh:                 return f"olap_ds_{nhom}_mh"
        return f"olap_ds_{nhom}"
    if nhom == "mh":
        if co_kh:      return "olap_ds_mh_kh"
        if co_loai_kh: return "olap_ds_mh_loai_kh"
        return "olap_ds_mh"
    if nhom == "loai_kh":
        return "olap_ds_loai_kh_kh" if co_kh else "olap_ds_loai_kh"
    return "olap_ds_kh"

def chon_cuboid_tk(nhom, co_mh, co_tinh, co_tp, co_ch):
    is_time = nhom in ["nam", "quy", "thang"]
    if is_time:
        if co_mh and co_ch:   return f"olap_tk_{nhom}_mh_ch"
        if co_mh and co_tp:   return f"olap_tk_{nhom}_mh_tp"
        if co_mh and co_tinh: return f"olap_tk_{nhom}_mh_tinh"
        if co_mh:             return f"olap_tk_{nhom}_mh"
        if co_ch:             return f"olap_tk_{nhom}_ch"
        if co_tp:             return f"olap_tk_{nhom}_tp"
        if co_tinh:           return f"olap_tk_{nhom}_tinh"
        return f"olap_tk_{nhom}"
    if nhom == "mh":
        if co_ch:   return "olap_tk_mh_ch"
        if co_tp:   return "olap_tk_mh_tp"
        if co_tinh: return "olap_tk_mh_tinh"
        return "olap_tk_mh"
    if nhom in ["tinh", "tp", "ch"]:
        return f"olap_tk_{nhom}"
    return "olap_tk_all"
```

### 3.4 Cách build WHERE clause động

```python
def build_where(filters: dict) -> tuple[str, list]:
    """filters = {"nam": 2022, "loai_kh": "DuLich", ...}"""
    clauses, params = [], []
    for col, val in filters.items():
        if val is not None:
            clauses.append(f"{col} = ?")
            params.append(val)
    where = ("WHERE " + " AND ".join(clauses)) if clauses else ""
    return where, params
```

### 3.5 Serve frontend tĩnh

```python
# Đặt file index.html vào thư mục static/
app.mount("/static", StaticFiles(directory="static"), name="static")

@app.get("/")
def root():
    return FileResponse("static/index.html")
```

---

## 4. FRONTEND (HTML + JS + Chart.js)

### 4.1 Cấu trúc file
```
project/
├── main.py          ← FastAPI backend
├── static/
│   └── index.html   ← toàn bộ frontend (HTML + CSS + JS trong 1 file)
```

### 4.2 Các màn hình / tab cần có

#### Tab 1 — Dashboard tổng quan
- Thẻ KPI: Tổng doanh thu, Tổng số lượng bán, Tổng tồn kho
- Biểu đồ cột: doanh thu theo năm (`olap_ds_nam`)
- Biểu đồ đường: so sánh doanh số vs tồn kho theo năm (`/api/olap/drill-across`)
- Biểu đồ tròn: doanh thu theo loại khách hàng (`olap_ds_loai_kh`)

#### Tab 2 — Sales Cube
- Dropdown chọn chiều nhóm: Năm / Quý / Tháng / Mặt hàng / Loại KH
- Filter tùy chọn: chọn năm, loại KH, mặt hàng
- Bảng kết quả + biểu đồ cột
- Nút Roll-up / Drill-down trên trục thời gian
- Click vào hàng → Drill-through (popup hiện giao dịch gốc)

#### Tab 3 — Inventory Cube
- Dropdown chọn chiều: Năm / Quý / Tháng / Mặt hàng / Tỉnh / TP / Cửa hàng
- Filter: năm, tỉnh, mặt hàng
- Bảng kết quả + biểu đồ cột ngang

#### Tab 4 — Demo 7 phép OLAP
Mỗi phép toán là 1 card có:
- Tên phép toán + mô tả ngắn
- Form input tham số
- Nút "Thực hiện"
- Kết quả hiện ngay dưới dạng bảng/biểu đồ

| Phép toán | Mô tả demo |
|-----------|-----------|
| Roll-up | Gộp doanh số từ tháng lên quý/năm |
| Drill-down | Xem chi tiết từ năm xuống quý/tháng |
| Slice | Cắt 1 chiều: chỉ xem năm 2022 |
| Dice | Cắt nhiều chiều: năm 2022 + loại KH |
| Pivot | Đổi hàng/cột: hàng=năm, cột=loại KH |
| Drill-across | So sánh doanh số vs tồn kho |
| Drill-through | Click vào ô tổng → xem giao dịch gốc |

### 4.3 Gọi API từ JS

```javascript
const API = "http://localhost:8000";

async function fetchData(url) {
    const res = await fetch(API + url);
    return res.json();
}

// Ví dụ: load doanh thu theo năm
const data = await fetchData("/api/doanh-so?nhom=nam");
```

### 4.4 Vẽ biểu đồ với Chart.js

```javascript
// Import từ CDN
// <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>

function veBarChart(canvasId, labels, data, label) {
    const ctx = document.getElementById(canvasId).getContext('2d');
    new Chart(ctx, {
        type: 'bar',
        data: {
            labels: labels,
            datasets: [{ label, data, backgroundColor: '#4f46e5' }]
        }
    });
}
```

---

## 5. CHẠY PROJECT

```bash
# Cài thư viện
pip install fastapi uvicorn pyodbc

# Chạy server
uvicorn main:app --reload --port 8000

# Mở trình duyệt
http://localhost:8000
```

---

## 6. LƯU Ý QUAN TRỌNG

1. **Cuboid routing**: Backend PHẢI tự chọn bảng đúng dựa trên `nhom` + filters.
   Không được query Fact_BanHang trực tiếp — phải qua cuboid (trừ drill-through).

2. **Drill-through**: Query thẳng `DW_Core.dbo.Fact_BanHang` với JOIN các Dim.
   Đây là tính năng duy nhất không dùng cuboid.

3. **Roll-up / Drill-down**: Không tính toán lại — chỉ chuyển sang bảng cuboid
   ở level cao hơn / thấp hơn. Toàn bộ data đã tính sẵn.

4. **Pivot**: Backend trả matrix JSON, frontend dùng Chart.js grouped bar.

5. **Không dùng ORM**: Query thẳng bằng `pyodbc` + f-string SQL.
   Tên bảng được chọn động từ routing function → không thể dùng parameterized query
   cho tên bảng, chỉ dùng `?` cho giá trị WHERE.

6. **Time key format**: `time_key` trong DW_Core là BIGINT dạng YYYYMM (202101).
   Các cuboid đã tách sẵn thành cột `nam`, `quy`, `thang` — dùng trực tiếp.
