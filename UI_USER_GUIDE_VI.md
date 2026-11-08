# 📱 Hướng Dẫn Sử Dụng OLAP Dashboard v2.0

## 🎯 Tổng Quan Công Việc Hoàn Thành

Từ **56 bảng cuboid SQL Server** → **React Interactive UI** với **7 phép toán OLAP**

```
┌─────────────────────────────────────────────────────┐
│  56 Cuboid Tables (OLAP_QuanLyBanHang)             │
│  ├─ 24 Sales Cuboids (olap_s_*)                   │
│  └─ 32 Inventory Cuboids (olap_i_*)               │
└────────────────┬────────────────────────────────────┘
                 │
                 ↓
┌─────────────────────────────────────────────────────┐
│  Backend API (Python FastAPI - main_v2.py)        │
│  30+ Endpoints → Route cuboid queries              │
│  ├─ Metadata endpoints (customers, products...)    │
│  ├─ Sales Drill-Down/Slice/Dice                   │
│  ├─ Inventory Drill-Down/Slice/Dice               │
│  ├─ Cross-Analysis (Sales vs Inventory)           │
│  └─ Drill Through (Raw Fact tables)               │
└────────────────┬────────────────────────────────────┘
                 │
                 ↓
┌─────────────────────────────────────────────────────┐
│  React Frontend (Interactive UI)                    │
│  ├─ 9 Components orchestrated by OLAPDashboard     │
│  ├─ Zustand global state management               │
│  ├─ Recharts visualizations                       │
│  └─ Real-time data filtering & display            │
└─────────────────────────────────────────────────────┘
```

---

## 🚀 Khởi Động Hệ Thống

### **1. Mở Terminal 1 - Backend**
```powershell
cd d:\PTIT\DW-DM\dw\scripts
python main_v2.py
```
✅ Kết quả:
```
INFO:     Uvicorn running on http://127.0.0.1:8000
INFO:     Application startup complete
```

### **2. Mở Terminal 2 - Frontend**
```powershell
cd d:\PTIT\DW-DM\dw\ui\react-app
npm start
```
✅ Kết quả:
```
Compiled successfully!
You can now view olap-dashboard in the browser.
  Local:            http://localhost:3000
```

### **3. Truy Cập Dashboard**
Mở trình duyệt, vào: **http://localhost:3000**

---

## 🎨 Giao Diện Dashboard

```
╔════════════════════════════════════════════════════════════╗
║               📊 OLAP Dashboard v2.0                       ║
║    56 Cuboid Analysis with 7 OLAP Operations              ║
╚════════════════════════════════════════════════════════════╝

┌─────────────────────────────────────────────────────────┐
│  🧩 Khối: [Sales/Inventory] | 📺 Chế độ: [Drill/Pivot/Cross] │
│  🔘 Sales vs Inventory (Drill Across)                  │
└─────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────┐
│  💰 Tổng Doanh Thu       │  📦 Tổng Số Lượng          │
│  1.5 Tỷ VNĐ              │  500K sản phẩm             │
└─────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────┐
│  📅 Drill-Down Hierarchy                               │
│  [2023] → [Q1] → [Tháng 5]  [↶ Clear]                 │
└─────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────┐
│  🔍 Bộ Lọc Nâng Cao (Slice/Dice)                       │
│  Customer Type: [Du lịch ▼] | Product: [MH001 ▼]     │
│  Store: [─── ▼] | City: [─── ▼]  [Apply] [Clear]      │
└─────────────────────────────────────────────────────────┘

┌──────────────────────┬──────────────────────┐
│  📊 Biểu Đồ         │  📋 Bảng Dữ Liệu    │
│  (Bar/Line/Pie)     │  (Sortable)         │
│                      │  + Drill Through     │
│                      │  button              │
└──────────────────────┴──────────────────────┘
```

---

## 📚 Hướng Dẫn 7 Phép Toán OLAP

### **1️⃣ DRILL-DOWN (Khoan Sâu) — Year → Quarter → Month**

**Mục đích:** Đi từ dữ liệu tổng hợp (năm) xuống chi tiết (tháng)

#### **Thao Tác:**
1. Giao diện mở, mặc định hiển thị dữ liệu năm 2023
   ```
   Biểu đồ: 1 thanh | Bảng: 1 hàng (năm 2023, Tổng = 10 tỷ VNĐ)
   ```

2. Khu vực **"Drill-Down Hierarchy"**, chọn **[Q1]** từ dropdown
   ```
   Breadcrumb: 📅 2023 → Q1
   Biểu đồ: 4 thanh (Q1-Q4) | Bảng: 4 hàng (quý)
   ```

3. Chọn **[Tháng 5]** từ dropdown tháng
   ```
   Breadcrumb: 📅 2023 → Q1 → Tháng 5
   Biểu đồ: 3 thanh (T4-T5-T6) | Bảng: 3 hàng (tháng)
   ```

4. **Click breadcrumb để roll-up:** Click "Q1" → quay lại view quý
   ```
   Breadcrumb: 📅 2023 → Q1
   Dữ liệu: Reset lại 4 quý
   ```

#### **Dữ Liệu Từ Cuboids:**
```
Year → olap_s_year (từ 56 cuboids sales)
Quarter → olap_s_quarter
Month → olap_s_month
```

---

### **2️⃣ ROLL-UP (Cuộn Lên) — Tổng Hợp Ngược**

**Mục đích:** Từ chi tiết trở lại tổng hợp

#### **Thao Tác:**
Từ trạng thái drill-down tháng:
```
Breadcrumb: 📅 2023 → Q1 → Tháng 5

Click "📅 2023" trong breadcrumb:
Breadcrumb: 📅 2023
Dữ liệu: Quay lại 1 hàng, tổng cộng = 10 tỷ VNĐ
```

---

### **3️⃣ SLICE (Chiếu) — Cắt Theo 1 Chiều**

**Mục đích:** Cố định 1 dimensionvalue, xem các dimensionkhác

#### **Thao Tác:**

1. **Bộ Lọc Nâng Cao → Customer Type:** chọn **"Du lịch"**
   ```
   Khu vực Filter:
   Customer Type: [Du lịch ▼]  (chọn)
   Product: [─── ▼]            (không chọn)
   ```

2. Click **[Apply]**
   ```
   ⏳ Đang tải dữ liệu... (tí chút)
   Bảng cập nhật: Chỉ hiển thị khách du lịch
   
   Ví dụ:
   Tháng | Doanh Thu
   4     | 50M VNĐ
   5     | 75M VNĐ
   (Chỉ "Du lịch", không có "Bộ phận", "Nhà máy" khác)
   ```

3. Click **[Clear]** để xóa filter và quay lại view tất cả

---

### **4️⃣ DICE (Chọn) — Cắt Theo Nhiều Chiều**

**Mục đích:** Cố định nhiều dimensionsimultaneously

#### **Thao Tác:**

1. **Bộ Lọc Nâng Cao:** Chọn nhiều giá trị
   ```
   Customer Type: [Du lịch ▼]     ← chọn
   Product: [MH001 ▼]             ← chọn
   Store: [─── ▼]                 ← không chọn
   City: [─── ▼]                  ← không chọn
   ```

2. Click **[Apply]**
   ```
   Bảng cập nhật: Chỉ hiển thị:
   - Khách loại "Du lịch"
   - SẢN phẩm "MH001"
   - Tất cả các tháng
   
   Ví dụ:
   Tháng | Số lượng | Doanh thu
   4     | 100     | 20M VNĐ
   5     | 150     | 30M VNĐ
   ```

3. **Dice nâng cao hơn:** Chọn 4 filters
   ```
   Customer Type: [Du lịch]
   Product: [MH001]
   Store: [Hà Nội]
   City: [Hà Nội]
   → Click [Apply]
   
   Kết quả: Cực kỳ chi tiết (1-2 hàng dữ liệu)
   ```

**Dữ Liệu từ Cuboids:**
```
Tùy combo filter → Backend route tới cuboid phù hợp:
- Filter 1 chiều    → olap_s_month_custtype
- Filter 2 chiều    → olap_s_month_product_custtype
- Filter 3+ chiều   → query tổng hợp từ multiple cuboids
```

---

### **5️⃣ PIVOT (Xoay) — Hoán Đổi Hàng/Cột**

**Mục đích:** Chuyển từ "Hàng = Tháng, Cột = Loại khách" → "Hàng = Loại khách, Cột = Tháng"

#### **Thao Tác:**

1. Từ Dashboard, chọn **Chế độ Xem: 🔀 Pivot**
   ```
   Dropdown: [🔀 Pivot ▼]  (select)
   ```

2. Bảng tự động chuyển đổi:
   ```
   TRƯỚC (Drill-Down):
   Tháng | Doanh Thu (Du lịch) | Doanh Thu (Bộ phận) | ...
   T4    | 50M                  | 100M               | ...
   T5    | 75M                  | 120M               | ...
   
   SAU (Pivot):
   Loại Khách | T4  | T5  | T6  | ...
   Du lịch    | 50M | 75M | 80M | ...
   Bộ phận    | 100M| 120M| 130M| ...
   Nhà máy    | 200M| 250M| 300M| ...
   ```

3. Click **[Drill-Down]** để quay lại view bình thường

---

### **6️⃣ DRILL ACROSS (Khoan Ngang) — So Sánh 2 Cube**

**Mục đích:** Kiểm tra mối liên hệ giữa Sales (doanh thu) và Inventory (tồn kho)
- Sales: Bán được bao nhiêu?
- Inventory: Còn lại bao nhiêu?
- **Turnover Ratio = (Sales / Inventory) × 100%**

#### **Thao Tác:**

1. Khu vực **Cube & View Mode**, click nút **↔️ Sales vs Inventory**
   ```
   Nút: [↔️ Sales vs Inventory]
   ```

2. Dashboard chuyển sang **Cross-Analysis View**
   ```
   Chế độ Xem: [↔️ Drill Across ▼]  (tự động)
   
   Tiêu đề: 🔀 Sales vs Inventory by Product
   
   Biểu đồ: Top 20 sản phẩm (Bar chart)
   Cột: Sản phẩm | Doanh thu | Tồn kho | Turnover ratio
   
   Bảng: Tất cả sản phẩm (Sortable)
   MH001 | 500M VNĐ  | 1000 sp | 50% (bán được 50% tồn kho)
   MH002 | 1B VNĐ    | 500 sp  | 200% (Lạ! Bán > tồn kho ban đầu?)
   ```

3. **Phân tích:**
   - Turnover 50% = Sản phẩm bán chậm (tồn kho dư dả)
   - Turnover 200% = Sản phẩm bán nhanh (có thể đã bán hết + tái nhập)
   - Tối ưu: Turnover 80-100% (vừa đủ bán, không dư, không thiếu)

4. Click **[Sales]** trong Cube selector để quay lại drill-down bình thường

---

### **7️⃣ DRILL THROUGH (Khoan Xuyên) — Xem Chi Tiết Giao Dịch**

**Mục đích:** Từ tổng hợp ("Tháng 5 = 1 tỷ VNĐ") xuống xem từng hóa đơn bán hàng chi tiết

#### **Thao Tác:**

1. **Từ Bảng Drill-Down**, ở hàng bất kỳ, click nút **"Drill Through"**
   ```
   Bảng:
   Tháng | Doanh thu | [Drill Through]  ← Click
   T5    | 1.0B VNĐ  |     🔗
   ```

2. **Modal popup xuất hiện** với dữ liệu chi tiết
   ```
   ╔══════════════════════════════════════════════╗
   ║ Drill Through - Raw Transaction Data        ║
   ║ (Lấy từ bảng Fact_BanHang)                 ║
   ╠══════════════════════════════════════════════╣
   │ Ngày | Khách      | Sản phẩm | SL | Tiền    │
   ├──────┼────────────┼─────────┼────┼─────────┤
   │ 5/1  │ Nguyễn Văn A│ MH001  │ 10 │ 100M    │
   │ 5/2  │ Trần Thị B │ MH002  │ 5  │ 50M     │
   │ 5/3  │ Phạm Văn C │ MH001  │ 20 │ 200M    │
   │ ... (48 hàng khác, 50/page)                │
   ╚══════════════════════════════════════════════╝
   ```

3. **Phân trang:**
   ```
   Dưới modal:
   [← Trang Trước] | Trang 1 / 10 | Tổng: 500 records
   [Trang Sau →] | [10/page ▼]
   ```

4. Click **[Trang Sau]** để xem giao dịch tháng 5 (tiếp tục)
   ```
   Offset thay đổi: 0 → 50 → 100 → ...
   Modal cập nhật: Hiển thị hàng 51-100
   ```

5. Click **[✕]** để đóng modal

---

## 🎮 Các Tình Huống Thực Tế

### **Tình huống 1: Phân Tích Doanh Thu Khách Du Lịch**

```
Mục tiêu: Biết khách du lịch bán được bao nhiêu từng tháng?

Thao tác:
1. Drill-Down đến Tháng 5
   Breadcrumb: 📅 2023 → Q1 → Tháng 5

2. Filter: Customer Type = "Du lịch"
   Customer Type: [Du lịch ▼]
   Click [Apply]

3. Xem biểu đồ + bảng:
   - Biểu đồ: Bar chart hiển thị 1 cột (Du lịch)
   - Bảng: Doanh thu = 75M VNĐ

4. Muốn xem chi tiết khách nào mua?
   Click [Drill Through] → Modal hiển thị 50 hóa đơn
   → Click [Trang Sau] xem thêm hóa đơn khác
```

### **Tình huống 2: Tìm Sản Phẩm "Chậm Chân"**

```
Mục tiêu: Sản phẩm nào tồn kho nhiều nhưng bán ít?

Thao tác:
1. Chế độ Xem: [↔️ Drill Across ▼]
   Click [↔️ Sales vs Inventory]

2. Xem bảng Cross-Analysis:
   Sản phẩm | Sales | Inventory | Turnover
   MH010   | 100M  | 10000 sp  | 1% ← "Chậm chân"!
   MH020   | 500M  | 1000 sp   | 50%
   MH030   | 1B    | 500 sp    | 200%

3. Nhân viên bán hàng: Cần khuyến mãi sản phẩm MH010
```

### **Tình huống 3: So Sánh Hai Tháng**

```
Mục tiêu: Doanh thu tháng 5 vs tháng 4?

Thao tác:
1. Drill-Down đến Tháng 5, ghi nhớ số liệu
   Doanh thu T5 = 1.0B VNĐ

2. Quay lại Tháng 4:
   Click "Q1" breadcrumb → Chọn T4

3. So sánh:
   T4: 900M VNĐ
   T5: 1.0B VNĐ
   → Tăng 100M (11.1%)
```

### **Tình huống 4: Phân Tích Sâu 1 Sản Phẩm**

```
Mục tiêu: Sản phẩm MH001 bán cho ai, bao nhiêu?

Thao tác:
1. Filter: Product = "MH001"
   Product: [MH001 ▼]
   Click [Apply]

2. Xem biểu đồ: Doanh thu MH001 = 500M

3. Muốn xem chi tiết theo khách:
   Drill-Down: Năm → Quý → Tháng
   Tự động filter MH001

4. Drill Through: Click button xem từng hóa đơn MH001

5. Xem Pivot:
   Hàng = Loại khách, Cột = Tháng
   → Biết khách nào mua MH001 nhiều nhất
```

---

## 📊 Bảng Điều Khiển Tính Năng

| Tính Năng | Vị Trí | Cách Dùng |
|-----------|--------|----------|
| **Drill-Down** | "Drill-Down Hierarchy" | Chọn Year → Quarter → Month từ dropdowns |
| **Roll-Up** | Breadcrumb | Click từng level để collapse |
| **Slice** | "Bộ Lọc" | Chọn 1 filter, click Apply |
| **Dice** | "Bộ Lọc" | Chọn ≥2 filters, click Apply |
| **Pivot** | "Chế độ Xem" | Select "🔀 Pivot" dropdown |
| **Drill Across** | "Khối & View Mode" | Click "↔️ Sales vs Inventory" button |
| **Drill Through** | Nút trong bảng | Click "Drill Through" per row |

---

## 🔍 Hướng Dẫn Đọc Biểu Đồ

### **Bar Chart (Cột)**
```
↑ Y-axis (Giá trị)
│    ███  
│    ███  
│ ██ ███ ███
└─────────── X-axis (Loại/Thời gian)
  Du   Bộ   Nhà
  lịch phận máy
```
- Cột cao = Doanh thu cao
- Cột thấp = Doanh thu thấp

### **Line Chart (Đường)**
```
  /‾‾‾\
 /     \
/       \
────────── Thời gian (tháng)
Trend: Tháng nào lên, tháng nào xuống
```

### **Pie Chart (Bánh)**
```
      ┌─────┐
   ╱         ╲
  │  50%     │
  │ (Du lịch)│
   ╲         ╱
    └─ 50%──┘
    (Bộ phận)
```
- Cắt lớn = Chiếm % cao
- Cắt nhỏ = Chiếm % thấp

---

## 🛠️ Troubleshooting

### **Q: Dashboard trắng, không có dữ liệu?**
**A:** 
1. Kiểm tra backend chạy: `python main_v2.py` running?
2. Kiểm tra SQL Server có dữ liệu: `SELECT * FROM olap_s_year`
3. Mở DevTools (F12) → Console → có lỗi nào không?

### **Q: Button "Apply" không làm gì?**
**A:** 
1. Chọn ít nhất 1 filter trước (Customer Type, Product, v.v.)
2. Kiểm tra console có lỗi API

### **Q: Drill Through modal không có dữ liệu?**
**A:**
1. Kiểm tra Fact_BanHang có dữ liệu cho tháng đó
2. Kiểm tra filters có quá hạn chế không (chỉ 1 khách, 1 sản phẩm)

### **Q: Biểu đồ hiển thị lỗi?**
**A:**
1. Chắc chắn dữ liệu có ít nhất 2 hàng
2. Kiểm tra dữ liệu có cột dùng cho chart (sum_amount, total_quantity, v.v.)

---

## 📝 Tóm Tắt Công Việc Hoàn Thành

### **Từ 56 Cuboid Đến UI:**

```
✅ Bước 1: Xây dựng Backend (main_v2.py)
   - 30+ API endpoints
   - Kết nối 56 cuboid tables
   - Query theo Drill-Down, Slice, Dice, Drill Across, Drill Through
   
✅ Bước 2: Thiết kế Frontend React (9 components)
   - OLAPDashboard: Orchestrator chính
   - DimensionSelector: Drill-Down navigation
   - FilterPanel: Slice/Dice controls
   - DataTable: Dữ liệu + Drill Through button
   - ChartRenderer: Biểu đồ Recharts (Bar/Line/Pie)
   - CrossAnalysisPanel: Sales vs Inventory
   - DrillThroughModal: Raw data modal + pagination
   - PivotTable: Pivot/Transpose
   - SummaryCards: KPI metrics

✅ Bước 3: State Management (Zustand)
   - Lưu dimensions (year, quarter, month)
   - Lưu filters (customer_type, product_key, store_key)
   - Lưu view mode (drilldown, pivot, crossanalysis)
   - Lưu cuboid data, drill through data, pagination

✅ Bước 4: Tích Hợp Hoàn Toàn (7 OLAP Operations)
   - 1️⃣ Drill-Down: Year → Q → M breadcrumb
   - 2️⃣ Roll-Up: Click breadcrumb để collapse
   - 3️⃣ Slice: 1 filter
   - 4️⃣ Dice: 2+ filters
   - 5️⃣ Pivot: Transpose rows/cols
   - 6️⃣ Drill Across: Sales vs Inventory comparison
   - 7️⃣ Drill Through: Raw transaction viewer

✅ Bước 5: Polish & Documentation
   - Responsive UI (desktop + mobile)
   - Error handling
   - Loading states
   - Comprehensive README + this guide
```

---

## 🎓 Kết Luận

Dashboard OLAP này **hoàn toàn functional** và hỗ trợ tất cả 7 phép toán OLAP tiêu chuẩn:

```
Người dùng (Trình duyệt)
        ↓
Dashboard UI (React)
        ↓
Zustand Store (Global state)
        ↓
API Client (Axios)
        ↓
Backend (FastAPI 30+ endpoints)
        ↓
SQL Server (56 cuboid queries)
        ↓
Kết quả: Dữ liệu OLAP real-time
```

**Sẵn sàng triển khai thực tế!** 🚀

---

**Liên hệ hỗ trợ:** Xem lỗi? → Kiểm tra console F12 → Báo cáo với trace logs
