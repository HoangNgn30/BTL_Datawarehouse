# CONTEXT ĐẦY ĐỦ — BTL DATA WAREHOUSE QUẢN LÝ BÁN HÀNG

---

## 1. THÔNG TIN CHUNG

| Mục | Chi tiết |
|-----|----------|
| Tên dự án | BTL Kho Dữ Liệu & Khai Phá Dữ Liệu |
| Môn học | Kho Dữ Liệu và Khai Phá Dữ Liệu |
| Giảng viên | Nguyễn Quỳnh Chi |
| Stack | SQL Server + T-SQL thuần (không dùng SSAS nữa) |
| DB nguồn | `IDB_QuanLyBanHang` |
| DB kho | `DW_Core` |
| DB OLAP | `OLAP_QuanLyBanHang` (chưa tạo) |

---

## 2. QUYẾT ĐỊNH HƯỚNG ĐI

### Đã bỏ SSAS, chuyển sang code thuần T-SQL vì:
- GV yêu cầu hiểu bản chất, không dùng công cụ che đi logic
- SSAS tự động tạo và quản lý cuboid ẩn bên trong engine
- Code thuần = tự tay viết từng bảng cuboid bằng SQL → hiểu rõ bản chất

### Kiến trúc pipeline cuối cùng:
```
IDB_QuanLyBanHang
      ↓ ETL (T-SQL — ĐÃ XONG)
DW_Core (Star Schema)
      ↓ Tạo cuboid (T-SQL — CHƯA LÀM)
OLAP_QuanLyBanHang (56 bảng cuboid)
      ↓ API query
Web App (Backend Python + Frontend)
```

---

## 3. SCHEMA DW_CORE (ĐÃ HOÀN CHỈNH)

### Dimension Tables
| Bảng | PK | Các cột chính |
|------|----|---------------|
| `Dim_VPDD` | `vp_key` (MaThanhPho) | ten_tp, dia_chi_vp, bang |
| `Dim_CuaHang` | `ch_key` (MaCuaHang) | so_dt, vp_key |
| `Dim_MatHang` | `mh_key` (MaMH) | mo_ta, kich_co, trong_luong, gia |
| `Dim_KhachHang` | `kh_key` (MaKH) | ten, loai_kh |
| `Dim_ThoiGian` | `time_key` (YYYYMM BIGINT) | thang, quy, nam |

### Fact Tables
| Bảng | FK | Measures |
|------|----|----------|
| `Fact_BanHang` | time_key, kh_key, mh_key | so_luong, tong_tien |
| `Fact_Kho` | time_key, ch_key, mh_key | so_luong |

### Relationships
```
Fact_BanHang.time_key → Dim_ThoiGian.time_key
Fact_BanHang.kh_key   → Dim_KhachHang.kh_key
Fact_BanHang.mh_key   → Dim_MatHang.mh_key
Fact_Kho.time_key     → Dim_ThoiGian.time_key
Fact_Kho.ch_key       → Dim_CuaHang.ch_key
Fact_Kho.mh_key       → Dim_MatHang.mh_key
Dim_CuaHang.vp_key    → Dim_VPDD.vp_key
```

### ETL đặc biệt:
- `time_key` dùng format YYYYMM (BIGINT), ví dụ tháng 6/2022 = 202206
- `Dim_KhachHang` dùng Table Flattening từ KhachHang + KhachHangDuLich + KhachHangBuuDien
- File ETL: `etl_sqlserver_final_v2.sql` — đã chạy thành công

---

## 4. VẤN ĐỀ DATA KHO (QUAN TRỌNG)

### Hiện trạng:
Bảng `Fact_Kho` chỉ có **1 dòng cho mỗi cặp (ch_key, mh_key)** vì data gốc
`MatHangLuuTru` trong IDB chỉ lưu snapshot thời điểm cuối cùng, không có lịch sử.

Kiểm chứng bằng Python:
```
Tổng số cặp (CuaHang, MatHang): 22,219
Số lần ghi tối đa cho 1 cặp: 1
→ Mỗi cặp chỉ có đúng 1 dòng duy nhất
```

### Hậu quả:
Không phân tích được tồn kho theo thời gian → Inventory Cube gần như vô nghĩa.

### Quyết định:
Sinh thêm data mock theo tháng vào `Fact_Kho` **trước khi tạo cuboid**.
Logic: lấy giá trị gốc, dao động ±20% ngẫu nhiên cho các tháng từ 202001 đến 202412.

---

## 5. CẤU TRÚC CUBE VÀ PHÂN CẤP

### DMQL định nghĩa:
```
define cube sales [time, customer, product]:
    total_quantity = sum(so_luong),
    sum_amount = sum(tong_tien)

define dimension time as (time_key, thang, quy, nam)
define dimension customer as (kh_key, loai_kh)
define dimension product as (mh_key, mo_ta, kich_co, trong_luong, gia)

define cube inventory [time, product, store]:
    total_quantity_on_hand = sum(so_luong)

define dimension time as time in cube sales
define dimension product as product in cube sales
define dimension store as (ch_key, so_dt, location(vp_key, ten_tp, bang))
```

### Sales Cube — phân cấp các chiều:
| Chiều | Phân cấp | Số mức |
|-------|----------|--------|
| Time | all → year → quarter → month | 4 |
| Product | all → product_key | 2 |
| Customer | all → customer_type → customer_key | 3 |

**Tổng Sales Cuboids = 4 × 2 × 3 = 24**

> Lưu ý: Nhóm bạn đã bỏ hierarchy địa lý của Customer (state → city → customer_key).
> Nhóm tham khảo (Nhóm 3) giữ cả 2 hierarchy nên Customer có 6 mức → 48 cuboids Sales.
> Nhóm bạn chỉ giữ 1 hierarchy (loại KH) → 3 mức → 24 cuboids.

### Inventory Cube — phân cấp các chiều:
| Chiều | Phân cấp | Số mức |
|-------|----------|--------|
| Time | all → year → quarter → month | 4 |
| Product | all → product_key | 2 |
| Store | all → state → city → store_key | 4 |

**Tổng Inventory Cuboids = 4 × 2 × 4 = 32**

**TỔNG CỘNG: 56 CUBOIDS**

---

## 6. DANH SÁCH 56 CUBOID

### Quy tắc đặt tên:
- `olap_s_` = Sales Cube
- `olap_i_` = Inventory Cube
- Hậu tố = tổ hợp chiều được GROUP BY

### SALES CUBE (24 bảng)

#### 0-D (1 bảng)
| STT | Tên bảng | Mô tả |
|-----|----------|-------|
| 1 | `olap_s_all` | Tổng toàn bộ, không phân theo chiều nào |

#### 1-D (6 bảng)
| STT | Tên bảng | Group by |
|-----|----------|----------|
| 2 | `olap_s_year` | năm |
| 3 | `olap_s_quarter` | năm, quý |
| 4 | `olap_s_month` | năm, quý, tháng |
| 5 | `olap_s_product` | mh_key |
| 6 | `olap_s_custtype` | loai_kh |
| 7 | `olap_s_customer` | kh_key, loai_kh |

#### 2-D (12 bảng)
| STT | Tên bảng | Group by |
|-----|----------|----------|
| 8 | `olap_s_year_product` | năm + mh_key |
| 9 | `olap_s_quarter_product` | năm, quý + mh_key |
| 10 | `olap_s_month_product` | năm, quý, tháng + mh_key |
| 11 | `olap_s_year_custtype` | năm + loai_kh |
| 12 | `olap_s_quarter_custtype` | năm, quý + loai_kh |
| 13 | `olap_s_month_custtype` | năm, quý, tháng + loai_kh |
| 14 | `olap_s_year_customer` | năm + kh_key |
| 15 | `olap_s_quarter_customer` | năm, quý + kh_key |
| 16 | `olap_s_month_customer` | năm, quý, tháng + kh_key |
| 17 | `olap_s_product_custtype` | mh_key + loai_kh |
| 18 | `olap_s_product_customer` | mh_key + kh_key |
| 19 | `olap_s_custtype_customer` | loai_kh + kh_key |

#### 3-D (5 bảng — base cuboids chi tiết nhất)
| STT | Tên bảng | Group by |
|-----|----------|----------|
| 20 | `olap_s_year_product_custtype` | năm + mh_key + loai_kh |
| 21 | `olap_s_quarter_product_custtype` | năm, quý + mh_key + loai_kh |
| 22 | `olap_s_month_product_custtype` | năm, quý, tháng + mh_key + loai_kh |
| 23 | `olap_s_year_product_customer` | năm + mh_key + kh_key |
| 24 | `olap_s_month_product_customer` | năm, quý, tháng + mh_key + kh_key |

### INVENTORY CUBE (32 bảng)

#### 0-D (1 bảng)
| STT | Tên bảng | Mô tả |
|-----|----------|-------|
| 25 | `olap_i_all` | Tổng tồn kho toàn hệ thống, lấy snapshot mới nhất |

#### 1-D (7 bảng)
| STT | Tên bảng | Group by |
|-----|----------|----------|
| 26 | `olap_i_year` | năm |
| 27 | `olap_i_quarter` | năm, quý |
| 28 | `olap_i_month` | năm, quý, tháng |
| 29 | `olap_i_product` | mh_key |
| 30 | `olap_i_state` | bang |
| 31 | `olap_i_city` | bang, ten_tp |
| 32 | `olap_i_store` | ch_key |

#### 2-D (15 bảng)
| STT | Tên bảng | Group by |
|-----|----------|----------|
| 33 | `olap_i_year_product` | năm + mh_key |
| 34 | `olap_i_quarter_product` | năm, quý + mh_key |
| 35 | `olap_i_month_product` | năm, quý, tháng + mh_key |
| 36 | `olap_i_year_state` | năm + bang |
| 37 | `olap_i_quarter_state` | năm, quý + bang |
| 38 | `olap_i_month_state` | năm, quý, tháng + bang |
| 39 | `olap_i_year_city` | năm + bang, ten_tp |
| 40 | `olap_i_quarter_city` | năm, quý + bang, ten_tp |
| 41 | `olap_i_month_city` | năm, quý, tháng + bang, ten_tp |
| 42 | `olap_i_year_store` | năm + ch_key |
| 43 | `olap_i_quarter_store` | năm, quý + ch_key |
| 44 | `olap_i_month_store` | năm, quý, tháng + ch_key |
| 45 | `olap_i_product_state` | mh_key + bang |
| 46 | `olap_i_product_city` | mh_key + bang, ten_tp |
| 47 | `olap_i_product_store` | mh_key + ch_key |

#### 3-D (9 bảng — base cuboids chi tiết nhất)
| STT | Tên bảng | Group by |
|-----|----------|----------|
| 48 | `olap_i_year_product_state` | năm + mh_key + bang |
| 49 | `olap_i_quarter_product_state` | năm, quý + mh_key + bang |
| 50 | `olap_i_month_product_state` | năm, quý, tháng + mh_key + bang |
| 51 | `olap_i_year_product_city` | năm + mh_key + bang, ten_tp |
| 52 | `olap_i_quarter_product_city` | năm, quý + mh_key + bang, ten_tp |
| 53 | `olap_i_month_product_city` | năm, quý, tháng + mh_key + bang, ten_tp |
| 54 | `olap_i_year_product_store` | năm + mh_key + ch_key |
| 55 | `olap_i_quarter_product_store` | năm, quý + mh_key + ch_key |
| 56 | `olap_i_month_product_store` | năm, quý, tháng + mh_key + ch_key |

---

## 7. LƯU Ý KỸ THUẬT QUAN TRỌNG

### Inventory Cube — xử lý snapshot:
Fact_Kho là Periodic Snapshot, không phải transaction log.
Khi GROUP BY theo time → **phải lấy bản ghi mới nhất trong khoảng đó** trước khi SUM.
Khi bỏ hoàn toàn chiều time → lấy bản ghi mới nhất toàn thời gian cho mỗi (ch, mh).

Cách xử lý trong T-SQL:
```sql
-- Lấy snapshot mới nhất trong từng tháng
WHERE f.time_key = (
    SELECT MAX(f2.time_key)
    FROM Fact_Kho f2
    WHERE f2.ch_key = f.ch_key
      AND f2.mh_key = f.mh_key
      AND f2.time_key / 100 = t.nam      -- cùng năm
      AND f2.time_key % 100 = t.thang   -- cùng tháng
)
```

### SQL Server syntax (khác PostgreSQL):
```sql
-- Tạo bảng từ SELECT (SQL Server)
SELECT col1, col2, SUM(col3) AS measure
INTO OLAP_QuanLyBanHang.dbo.ten_bang
FROM ...
GROUP BY col1, col2;

-- Không dùng CREATE TABLE AS SELECT (cú pháp PostgreSQL)
```

### Cross-database query trong SQL Server:
```sql
-- Truy vấn từ DW_Core sang OLAP trong cùng instance
FROM DW_Core.dbo.Fact_BanHang f
JOIN DW_Core.dbo.Dim_ThoiGian t ON f.time_key = t.time_key
```

---

## 8. TIẾN ĐỘ HIỆN TẠI

| Giai đoạn | Nội dung | Trạng thái |
|-----------|----------|------------|
| 1 | Cài đặt môi trường | ✅ Xong |
| 2 | ETL SQL Server (IDB → DW_Core) | ✅ Xong |
| 3 | SSAS Cube | ❌ Bỏ, chuyển sang code thuần |
| 4 | Sinh data kho theo tháng | ⬜ Chưa làm |
| 5 | Tạo DB OLAP + 56 bảng cuboid | ⬜ Chưa làm |
| 6 | Web App + API | ⬜ Chưa làm |
| 7 | Báo cáo + minh chứng | ⬜ Chưa làm |

---

## 9. VIỆC CẦN LÀM THEO THỨ TỰ

```
Bước 1: Sinh data mock → INSERT vào DW_Core.Fact_Kho (các tháng còn thiếu)
Bước 2: CREATE DATABASE OLAP_QuanLyBanHang
Bước 3: Viết 56 câu SELECT...INTO để tạo 56 bảng cuboid
Bước 4: Xây Web App (Python backend + HTML/JS frontend)
         - Backend: nhận request → chọn bảng cuboid → trả JSON
         - Frontend: filter UI + biểu đồ + 7 phép toán OLAP
Bước 5: Viết báo cáo + chụp ảnh minh chứng
```

---

## 10. NHÓM THAM KHẢO (Nhóm 3 — PTIT)

Nhóm 3 làm cùng đề tài nhưng dùng PostgreSQL + Apache Airflow.
Điểm khác biệt quan trọng:

| So sánh | Nhóm bạn | Nhóm 3 |
|---------|----------|--------|
| DB | SQL Server | PostgreSQL |
| ETL automation | Thủ công SSMS | Apache Airflow (DAG) |
| Customer hierarchy | 1 hierarchy (loai_kh) | 2 hierarchy (loai_kh + địa lý) |
| Sales cuboids | 24 | 48 |
| Inventory cuboids | 32 | 32 |
| Tổng cuboids | 56 | 80 |
| Schema OLAP | `OLAP_QuanLyBanHang` | schema `olap` trong PostgreSQL |
| Tên bảng | `olap_s_*`, `olap_i_*` | `olap_sales_*`, `olap_inv_*` |
| Web stack | Chưa quyết định | React + FastAPI |

Nhóm 3 có thuật toán **Cuboid Routing** tự động chọn bảng cuboid tối ưu
dựa trên dimensions được request — đây là tính năng nên implement ở backend.

---

## 11. CÁC FILE ĐÃ TẠO

| File | Mô tả |
|------|-------|
| `etl_sqlserver_final_v2.sql` | ETL T-SQL hoàn chỉnh IDB → DW_Core |
| `context_dw_ssas.md` | Context ban đầu (khi còn dùng SSAS) |
| `context_huong_di_moi.md` | Context sau khi chuyển sang code thuần |
| `huong_di_tiep_theo.md` | Hướng dẫn chi tiết từng bước bằng ngôn ngữ tự nhiên |
| `context_full_project.md` | File này — context tổng hợp đầy đủ |
