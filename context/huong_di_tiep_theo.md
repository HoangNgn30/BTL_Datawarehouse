# HƯỚNG ĐI TIẾP THEO — BTL DATA WAREHOUSE (NHÓM BẠN)

## BỨC TRANH TỔNG THỂ

Hiện tại nhóm bạn đã có:
- ✅ `IDB_QuanLyBanHang` — DB nguồn gốc (dữ liệu thô)
- ✅ `DW_Core` — Kho dữ liệu Star Schema (Dim + Fact đã ETL xong)
- ❌ Chưa có tầng OLAP (chưa có các bảng cuboid)
- ❌ Chưa có Web App

Mục tiêu cuối cùng là:
```
IDB → DW_Core → OLAP_QuanLyBanHang → Web App
  (xong)   (xong)     (cần làm)         (cần làm)
```

---

## BƯỚC 1 — VÁ LỖ HỔNG DATA KHO (Làm trước khi tạo cuboid)

### Vấn đề là gì?
Bảng `Fact_Kho` trong `DW_Core` hiện tại chỉ có **1 dòng cho mỗi cặp (cửa hàng, mặt hàng)**
vì data gốc chỉ lưu snapshot 1 lần cuối cùng, không có lịch sử theo tháng.

Ví dụ:
```
CuaHang=1, MatHang=322, Thang=202206, SoLuong=168   ← chỉ có dòng này
CuaHang=1, MatHang=322, Thang=202207, ???            ← không có
CuaHang=1, MatHang=322, Thang=202208, ???            ← không có
```

Nếu để vậy thì Inventory Cube gần như vô dụng vì không phân tích được theo thời gian.

### Làm gì?
Sinh thêm data giả lập cho các tháng còn thiếu, trực tiếp vào `DW_Core.Fact_Kho`.

Logic đơn giản:
- Lấy tất cả các cặp (cửa hàng, mặt hàng) hiện có
- Với mỗi cặp, sinh thêm dữ liệu cho các tháng từ 202001 đến 202412
- Số lượng mỗi tháng = dao động ngẫu nhiên quanh giá trị gốc (±20%)
- Dùng Python hoặc T-SQL để sinh và INSERT vào Fact_Kho

> **Tại sao phải làm bước này trước?**
> Vì sau khi tạo cuboid rồi, nếu muốn sửa data thì phải xóa và tạo lại
> toàn bộ cuboid — rất mất công. Làm data sạch trước, tạo cuboid sau là đúng thứ tự.

---

## BƯỚC 2 — TẠO DATABASE MỚI CHỨA CUBOID

### Tại sao cần DB mới?
Tách biệt rõ ràng:
- `DW_Core` = tầng lưu trữ (Star Schema, Dim + Fact)
- `OLAP_QuanLyBanHang` = tầng phân tích (các bảng cuboid đã tính sẵn)

Trong SSMS, chạy đúng 1 câu:
```sql
CREATE DATABASE OLAP_QuanLyBanHang;
```

---

## BƯỚC 3 — HIỂU CUBOID LÀ GÌ (Trước khi viết code)

### Cuboid là gì?
Mỗi cuboid là 1 bảng chứa dữ liệu đã được **GROUP BY sẵn** theo một tổ hợp chiều nhất định.

Ví dụ dễ hiểu nhất:

**Cuboid "doanh thu theo năm"** — GROUP BY năm:
```
| năm  | tổng_số_lượng | tổng_doanh_thu |
|------|---------------|----------------|
| 2022 | 15,000        | 450,000,000    |
| 2023 | 28,000        | 820,000,000    |
| 2024 | 41,000        | 1,200,000,000  |
```

**Cuboid "doanh thu theo năm × mặt hàng"** — GROUP BY năm + mặt hàng:
```
| năm  | mã_mh | tổng_số_lượng | tổng_doanh_thu |
|------|-------|---------------|----------------|
| 2022 | MH001 | 3,000         | 90,000,000     |
| 2022 | MH002 | 5,000         | 150,000,000    |
| 2023 | MH001 | 6,000         | 180,000,000    |
...
```

Khi Web App hỏi "doanh thu theo năm là bao nhiêu?" → chỉ cần
`SELECT * FROM olap_sales_by_year` — **cực nhanh**, không cần tính toán gì nữa.

### Tại sao không query thẳng từ Fact_BanHang?
Hoàn toàn được, nhưng chậm hơn nhiều vì Fact có hàng triệu dòng.
Cuboid đã tính sẵn nên chỉ còn vài trăm dòng → query gần như tức thì.

---

## BƯỚC 4 — ĐẾM SỐ CUBOID CỦA NHÓM BẠN

### Sales Cube — 3 chiều:
| Chiều    | Các mức                          | Số mức |
|----------|----------------------------------|--------|
| Time     | all → year → quarter → month     | 4      |
| Product  | all → product_key                | 2      |
| Customer | all → customer_type → customer_key | 3    |

**Công thức:** 4 × 2 × 3 = **24 cuboids**

### Inventory Cube — 3 chiều:
| Chiều   | Các mức                        | Số mức |
|---------|--------------------------------|--------|
| Time    | all → year → quarter → month   | 4      |
| Product | all → product_key              | 2      |
| Store   | all → state → city → store_key | 4      |

**Công thức:** 4 × 2 × 4 = **32 cuboids**

**Tổng: 56 cuboids = 56 bảng trong OLAP_QuanLyBanHang**

---

## BƯỚC 5 — VIẾT SCRIPT TẠO 56 BẢNG CUBOID

### Quy tắc đặt tên bảng:
- `olap_s_` = Sales Cube
- `olap_i_` = Inventory Cube
- Hậu tố mô tả tổ hợp chiều, ví dụ:
  - `olap_s_all` = apex (không chiều nào)
  - `olap_s_year` = chỉ theo năm
  - `olap_s_year_product` = theo năm × mặt hàng
  - `olap_s_month_product_custtype` = theo tháng × mặt hàng × loại KH

### Cách viết mỗi bảng cuboid trong T-SQL:
```sql
-- Ví dụ: cuboid "doanh thu theo năm × mặt hàng"
SELECT
    t.nam          AS year,
    mh.mh_key      AS product_key,
    mh.mo_ta       AS description,
    SUM(f.so_luong) AS total_quantity,
    SUM(f.tong_tien) AS sum_amount
INTO OLAP_QuanLyBanHang.dbo.olap_s_year_product
FROM DW_Core.dbo.Fact_BanHang f
JOIN DW_Core.dbo.Dim_ThoiGian t  ON f.time_key = t.time_key
JOIN DW_Core.dbo.Dim_MatHang  mh ON f.mh_key   = mh.mh_key
GROUP BY t.nam, mh.mh_key, mh.mo_ta;
```

Cứ như vậy cho 56 tổ hợp. Mỗi bảng là 1 câu SELECT...INTO với GROUP BY khác nhau.

### Đặc biệt với Inventory Cube:
Không dùng SUM đơn giản. Vì Fact_Kho là snapshot, phải lấy
**bản ghi mới nhất trong khoảng thời gian đó** trước rồi mới SUM.

Ví dụ cuboid "tồn kho theo năm":
```sql
-- Bước 1: Với mỗi (cửa hàng, mặt hàng), lấy time_key lớn nhất trong năm đó
-- Bước 2: JOIN lại để lấy số lượng tương ứng
-- Bước 3: SUM lại theo năm
SELECT
    t.nam AS year,
    SUM(f.so_luong) AS total_quantity_on_hand
INTO OLAP_QuanLyBanHang.dbo.olap_i_year
FROM DW_Core.dbo.Fact_Kho f
JOIN DW_Core.dbo.Dim_ThoiGian t ON f.time_key = t.time_key
WHERE f.time_key = (
    SELECT MAX(f2.time_key)
    FROM DW_Core.dbo.Fact_Kho f2
    WHERE f2.ch_key = f.ch_key
      AND f2.mh_key = f.mh_key
      AND f2.time_key / 100 = t.nam  -- cùng năm
)
GROUP BY t.nam;
```

---

## BƯỚC 6 — XÂY DỰNG WEB APP

### Stack gợi ý:
- **Backend:** Python + FastAPI (hoặc Flask nếu quen hơn)
- **Frontend:** HTML + Chart.js (đơn giản) hoặc React (nếu biết)
- **Kết nối DB:** `pyodbc` để kết nối SQL Server từ Python

### Logic hoạt động:

**1. User chọn filter trên UI** (ví dụ: xem doanh thu theo quý, lọc năm 2024)

**2. Frontend gửi request lên Backend:**
```json
{
  "cube": "sales",
  "rows": ["year", "quarter"],
  "filters": { "year": 2024 }
}
```

**3. Backend nhận request, chọn bảng cuboid phù hợp:**
- Nhìn vào `rows` → cần `year` và `quarter` → chọn bảng `olap_s_quarter`
- Thêm điều kiện WHERE year = 2024

**4. Backend chạy SQL:**
```sql
SELECT year, quarter, SUM(sum_amount) AS sum_amount
FROM OLAP_QuanLyBanHang.dbo.olap_s_quarter
WHERE year = 2024
GROUP BY year, quarter
ORDER BY year, quarter;
```

**5. Trả kết quả về Frontend → vẽ biểu đồ**

### Các tính năng OLAP cần implement:
| Tính năng   | Ý nghĩa thực tế trên UI                              |
|-------------|------------------------------------------------------|
| Roll Up     | Click nút "Gộp lại" → chuyển từ tháng lên quý/năm   |
| Drill Down  | Click vào cột trên biểu đồ → xem chi tiết hơn        |
| Slice       | Chọn 1 giá trị filter (ví dụ: chỉ xem năm 2023)      |
| Dice        | Chọn nhiều filter cùng lúc (năm 2023 + loại KH)      |
| Pivot       | Đổi hàng/cột trong bảng kết quả                      |
| Drill Across| So sánh doanh số bán vs tồn kho cùng 1 biểu đồ       |
| Drill Through | Click vào 1 ô tổng hợp → xem giao dịch gốc chi tiết |

---

## BƯỚC 7 — VIẾT BÁO CÁO

Sau khi có đủ data và code chạy được, chụp ảnh minh chứng:
- Ảnh Star Schema trong SSMS (diagram của DW_Core)
- Ảnh danh sách 56 bảng trong OLAP_QuanLyBanHang
- Ảnh Web App chạy từng tính năng OLAP
- Ảnh SQL query và kết quả tương ứng với mỗi cuboid

---

## TÓM TẮT THỨ TỰ LÀM

```
1. Sinh data kho theo tháng → INSERT vào DW_Core.Fact_Kho
           ↓
2. Tạo DATABASE OLAP_QuanLyBanHang trong SSMS
           ↓
3. Viết 56 câu SQL tạo bảng cuboid (SELECT INTO)
   - 24 bảng cho Sales Cube
   - 32 bảng cho Inventory Cube
           ↓
4. Xây dựng Web App
   - Backend: nhận request → chọn đúng bảng cuboid → trả data
   - Frontend: hiển thị biểu đồ + cho phép filter/drill
           ↓
5. Viết báo cáo + chụp ảnh minh chứng
```

---

## GHI CHÚ QUAN TRỌNG

> **Điểm khác nhóm kia:** Nhóm kia dùng PostgreSQL nên cú pháp
> `CREATE TABLE AS SELECT` còn nhóm bạn dùng SQL Server thì phải dùng
> `SELECT ... INTO`. Ngoài ra họ có Apache Airflow để tự động hóa ETL,
> nhóm bạn chạy thủ công bằng SSMS là đủ cho BTL.

> **Điểm mạnh của nhóm bạn:** Đã có DW_Core sẵn và Star Schema đúng chuẩn.
> Chỉ cần tập trung vào bước 3 (56 cuboid) và bước 4 (Web App) là hoàn thành.
