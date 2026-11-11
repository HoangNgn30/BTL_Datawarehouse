# Oracle + SQL Server: triển khai và trích xuất nguồn khách hàng

## Kiến trúc thực thi

- **Oracle FREEPDB1 / schema KDL_VPDD**: KhachHang, KhachHangDuLich, KhachHangBuuDien.
- **SQL Server IDB_BanHang**: văn phòng, cửa hàng, sản phẩm, đơn/dòng đơn, phân bổ, ledger và snapshot.
- **SQL Server STG_OracleVPDD**: landing snapshot của Oracle, có ExtractAudit ghi nguồn/phiên bản, UTC, số dòng, SHA256.
- **DW_Core**: ETL khách hàng từ STG_OracleVPDD, bán hàng và tồn từ SQL Server.
- **OLAP_QuanLyBanHang**: 56 cuboid, API và báo cáo.

Oracle là nguồn khách hàng có thẩm quyền khi chạy pipeline Oracle. CSDL IDB_VPDD trên SQL Server chỉ cung cấp bộ dữ liệu demo cho lần bootstrap đầu tiên và còn được giữ cho chế độ demo SQL-only. Không đọc IDB_VPDD làm nguồn khách hàng trong pipeline Oracle.

## Chạy lần đầu

Cần Docker Desktop đang hoạt động; Python cài các gói trong dw-dm/requirements.txt, SQL Server và sqlcmd. Nguồn demo IDB_BanHang phải đã có dữ liệu phân bổ/snapshot. Nếu chưa có, chạy pipeline SQL-only theo SETUP.md trước.

Từ thư mục dự án:

```powershell
.\oracle\start_oracle.ps1 -BootstrapDemo -Server '.\MSSQLSERVER01'
.\sql\run_oracle_pipeline.ps1 -Server '.\MSSQLSERVER01' -Trusted
```

Bootstrap chỉ tạo ba bảng Oracle khi chưa có bảng nguồn nào; không ghi đè khi bảng đã tồn tại. Đây là bước chuyển bộ dữ liệu mẫu ban đầu sang Oracle, không phải trích xuất giả. Các lần chạy sau không seed lại nguồn.

## Những lần chạy tiếp theo

```powershell
.\oracle\start_oracle.ps1
.\sql\run_oracle_pipeline.ps1 -Server '.\MSSQLSERVER01' -Trusted
```

Pipeline không xóa hai nguồn; full refresh staging và thay thế DW/cuboid. sqlcmd/Python trả lỗi thì dừng. Có thể dùng SQL authentication bằng -User/-Password thay -Trusted.

## Kết nối và mật khẩu

Oracle lắng nghe **127.0.0.1:1522**, service **FREEPDB1**, user **KDL_VPDD**. Script tạo hai mật khẩu ngẫu nhiên tại `oracle/secrets/`; Compose đưa chúng vào container dưới dạng secret file. Thư mục này đã được .gitignore bỏ qua. Không in mật khẩu vào log hoặc lưu vào Git.

Python sử dụng thin driver python-oracledb, không cần Oracle Instant Client. Có thể cấu hình Oracle riêng qua `.env.oracle`: ORACLE_DSN, ORACLE_USER và ORACLE_PASSWORD_FILE (đường dẫn tuyệt đối). Hoặc ORACLE_PASSWORD từ biến môi trường. Không cần tài khoản SYS cho extraction/ETL; tài khoản app sở hữu ba bảng nguồn.

## Kiểm tra riêng

```powershell
$env:DB_SERVER='.\MSSQLSERVER01'
$env:DB_TRUSTED='yes'
$env:DB_CUSTOMER_SOURCE='STG_OracleVPDD'
python scripts/oracle_sync.py verify
python scripts/test_oracle_pipeline.py
.\sql\run_oracle_pipeline.ps1 -Server '.\MSSQLSERVER01' -Trusted
```

`test_oracle_pipeline.py` dành riêng cho schema demo KDL_VPDD: tạm đổi tên khách 1 thành chuỗi tiếng Việt, kiểm tra đi tới DW, rồi gây lỗi thành phố không tồn tại và kiểm tra staging rollback. Khôi phục bản ghi trong finally. Sau test chạy lại pipeline để cuboid đồng bộ với DW. Không dùng test mutation này với nguồn sản xuất. Test dùng Windows Authentication vào SQL Server.

## Nhất quán và chất lượng dữ liệu

Ba bảng Oracle được đọc trong cùng READ ONLY transaction. Staging thay thế trong một transaction SQL Server; lỗi subtype/FK hoặc khóa thành phố/khách trong đơn bán hàng làm rollback toàn bộ dữ liệu và audit của lượt extract. Tên/địa chỉ dùng NVARCHAR2 trên Oracle, NVARCHAR trên SQL Server. Kiểm tra so sánh toàn bộ hàng/thuộc tính Oracle → staging → Dim_KhachHang, không chỉ đếm hàng.

Đối chiếu các cuboid/báo cáo chọn DB_CUSTOMER_SOURCE=STG_OracleVPDD; bước verify xác minh staging thực sự khớp Oracle. Việc khớp staging riêng lẻ không được coi là đã khớp Oracle nếu thiếu bước này.

## Dừng và khởi động lại

```powershell
docker compose -f oracle/compose.yaml stop
# Giữ nguyên volume và dữ liệu Oracle
docker compose -f oracle/compose.yaml start
```

Container giới hạn RAM 2GB, swap tổng 3GB; script khởi tạo đặt SGA target 768MB và PGA target 128MB cho demo. Khởi động đầu cần giải nén dữ liệu và có thể mất vài phút; máy ít RAM có thể chậm. Không dừng hay sửa container của các dự án khác. Không dùng `down -v` nếu muốn giữ nguồn Oracle.

Tài liệu kỹ thuật: [image Oracle Free](https://github.com/gvenzl/oci-oracle-free), [python-oracledb connection](https://python-oracledb.readthedocs.io/en/latest/user_guide/connection_handling.html).
