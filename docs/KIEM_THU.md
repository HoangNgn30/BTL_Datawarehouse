# Kết quả kiểm thử — 19/11/2026 (thiết kế fact 4 chiều)

## Môi trường và phạm vi

SQL Server trên instance riêng `.\MSSQLSERVER01`, Windows Authentication, ODBC Driver 17, Python 3.13 (pyodbc 5.2.0, oracledb 26.1). Chạy chế độ **SQL-only** (`sql/run_all.ps1 -ResetDemo`): nguồn demo được tạo lại hoàn toàn. Không sửa `.env` cá nhân.

Nguồn: 12 thành phố (8 bang), 50 cửa hàng, 100 mặt hàng, 5.000 khách, 55.000 đơn và 115.500 dòng đơn, giai đoạn 2021–2023.

Kết quả phân bổ: 115.519 lần cấp hàng (có dòng đơn tách cửa hàng), trong đó 1.318 lần cấp từ cửa hàng ở thành phố khác thành phố của khách. Sổ cái 121.874 bút toán, gồm 2.911 lần nhập bổ sung. Snapshot cuối tháng: 123.984 dòng từ 3.444 cặp cửa hàng–mặt hàng.

| Bảng | Số dòng | Khóa |
|---|---|---|
| Fact_BanHang | **115.381** | ngay_key + kh_key + mh_key + ch_key |
| Fact_Kho | **123.984** | time_key + ch_key + mh_key |
| Cuboid | 152 (120 bán hàng + 32 tồn kho) | |

## Bằng chứng đã chạy

| Kiểm tra | Kết quả |
|---|---|
| `validate_olap.py`: từng hàng của 152 cuboid so với truy vấn trực tiếp trên nguồn; sổ cái → snapshot; phân bổ → Fact_BanHang theo khóa 4 chiều; tổng fact = tổng dòng đơn; đủ lượng đặt; snapshot → Fact_Kho; tồn hiện tại; không âm; mỗi fact ≥ 100.000 dòng | **161/161** đạt |
| `validate_reports.py`: từng hàng của 9 báo cáo (thêm ca tham số thời gian cho YC2, YC4, YC7) so với truy vấn nguồn | **12/12** đạt |
| `test_api.py`: mọi tổ hợp trục của hai lưới (120 + 32), lọc, slice/dice/drill-down theo vị trí, roll-up ngày→tháng và cửa hàng→bang (tổng không đổi), pivot đảo chiều 4 cặp, drill-across theo bang, drill-through theo cửa hàng, báo cáo 1–9, tồn cuối quý khi hiển thị năm, các lỗi 400/422 | **209** kiểm tra đạt |
| `validate_idb.py`: nguồn → IDB, FK tin cậy, metadata đủ cột/ánh xạ, 152 cuboid và 14 mức phân cấp đã đăng ký, khóa Fact_BanHang đúng bằng 4 khóa ngoại, 10 index | **31/31** đạt |
| `test_api_contracts.py` (không cần DB) | 14/14 đạt |
| `test_ui_regressions.cjs` (không cần DB) | đạt |
| `test_ui_dom.cjs` với API thật tại cổng 8017 | đạt; báo cáo 2 có 11 dòng, báo cáo 9 có 833 dòng |
| `test_oracle_bootstrap.py` (adapter giả, không chạm nguồn thật) | 6/6 đạt |
| Trình duyệt: tab Doanh số chọn Năm × Thành phố → `olap_ds_nam_tp`, 36 dòng; chọn đủ 4 chiều → `olap_ds_ngay_mh_kh_ch`, hiển thị 2.000/115.381 dòng; drill-across theo bang 24 dòng; roll-up cửa hàng → thành phố | đúng |

Thời gian chạy toàn bộ pipeline trên máy kiểm thử khoảng 15 phút; phần lâu nhất là vật hóa 152 cuboid (~5 phút) và đối chiếu từng hàng.

Lưu ý khi chạy: nếu gọi `run_all.ps1` mà gộp stderr vào stdout (`*>&1`), cảnh báo deprecation của `starlette.testclient` sẽ bị PowerShell coi là lỗi và dừng script. Chạy bình thường không bị.

## Pipeline Oracle + SQL Server

Container `kdl-oracle` (Oracle 23.26.3.0.0) được khởi động bằng `oracle/start_oracle.ps1`; nguồn khách Oracle được nạp lại theo bộ demo mới bằng `python scripts/oracle_sync.py reset-demo` (5.000 khách, 3.334 du lịch, 2.499 bưu điện). Sau đó `sql/run_oracle_pipeline.ps1` chạy hết, mã thoát 0, khoảng 28 phút:

| Kiểm tra | Kết quả |
|---|---|
| Oracle → STG_OracleVPDD, so toàn bộ hàng/thuộc tính | 3/3 bảng khớp |
| Oracle → Dim_KhachHang, toàn bộ thuộc tính | 5.000 dòng khớp |
| `validate_olap.py` | 161/161 |
| `validate_reports.py` | 12/12 |
| `test_api.py` | 209 |
| `validate_idb.py` | 31/31 |

Lưu ý: nếu `reset-demo` báo `WinError 10061 ... actively refused`, container Oracle đang dừng dù Docker Desktop đã bật; chạy `oracle/start_oracle.ps1` trước.

## Giới hạn

- Dữ liệu là demo: tồn đầu kỳ, nhập bổ sung theo ngưỡng và xuất theo đơn. Chưa mô phỏng trả hàng, SCD2 hay tải tăng dần.
- Bài kiểm tra DOM stub Chart.js; không kiểm chứng hình vẽ canvas. Lượt xem trình duyệt chỉ kiểm các tương tác nêu trên, chưa rà toàn bộ giao diện ở kích thước mobile.

Tài liệu thiết kế trong BAO_CAO.md, đặc tả cuboid trong CUBOID_SPEC.md, lệnh chạy trong SETUP.md.
