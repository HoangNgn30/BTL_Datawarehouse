# Chạy và kiểm tra bài tập lớn Kho dữ liệu

Bản chạy chính: `dw-dm/main.py` + `dw-dm/static/`. Các entry point cũ trong `scripts/` chuyển tiếp sang cùng ứng dụng. Không copy `main_v2.py` đè lên mã khác. React hiện nhúng giao diện chính qua iframe; các component thử nghiệm cũ không thuộc luồng chạy.

## 1. Điều kiện

SQL Server, `sqlcmd`, ODBC Driver 17 for SQL Server, Python với `pyodbc python-dotenv fastapi uvicorn httpx`. SQL Server cần quyền tạo CSDL. Nguồn demo và DW dùng full refresh.

## 2. Tạo dữ liệu demo và kho

Từ thư mục `D:\KDL&KPDL\BTL_Datawarehouse`:

```powershell
.\sql\run_all.ps1 -Server '.\MSSQLSERVER01' -Trusted
```

Instance này đã được dùng kiểm thử. Nếu nguồn demo đã tồn tại, lệnh dừng để bảo vệ dữ liệu. Chỉ khi chủ động muốn xóa và tạo lại **hai CSDL demo IDB_VPDD, IDB_BanHang**, thêm `-ResetDemo`. Pipeline cũng thay thế nội dung `DW_Core` và `OLAP_QuanLyBanHang`; chọn instance riêng cho bài tập. Với SQL authentication dùng `-User` và `-Password` thay cho `-Trusted`; không ghi mật khẩu vào Git.

Các bước: nguồn → phân bổ đơn/ledger/snapshot → ETL galaxy → 56 cuboid → đối chiếu nguồn. Lỗi ở bất kỳ bước nào khiến script trả lỗi và dừng.

## 3. Mở ứng dụng

```powershell
$env:DB_SERVER='.\MSSQLSERVER01'
$env:DB_TRUSTED='yes'
python -m uvicorn main:app --app-dir dw-dm --host 127.0.0.1 --port 8000
```

Mở `http://127.0.0.1:8000/`, `http://127.0.0.1:8000/bao-cao`, hoặc `/docs` để xem API. Đường dẫn static và `.env` được xác định theo thư mục mã, không phụ thuộc thư mục gọi lệnh. Biến môi trường có ưu tiên hơn `.env` có sẵn; file `.env` cá nhân không bị sửa.

React tùy chọn: trong `ui/react-app`, đặt `REACT_APP_API_URL=http://127.0.0.1:8000`, chạy `npm start`. Đây là lớp mở cùng dashboard; không còn backend API tiếng Anh riêng. Dùng trực tiếp FastAPI khi demo để giảm số tiến trình.

## 4. Chạy kiểm tra

Giữ `DB_SERVER` và `DB_TRUSTED` như trên:

```powershell
python scripts/validate_olap.py
python scripts/validate_reports.py
python scripts/test_api.py
```

Kiểm tra dữ liệu so sánh số nguyên/Decimal chính xác, không chuyển tiền sang float. Kiểm tra API cần DB thật đã nạp dữ liệu. Chi tiết kết quả trong `KIEM_THU.md`.

## 5. Pipeline Oracle + SQL Server

Oracle đã được triển khai thực tế bằng Docker, schema KDL_VPDD tại 127.0.0.1:1522/FREEPDB1. Ba bảng khách hàng nằm trên Oracle; bán hàng và tồn kho nằm trên SQL Server. Chạy `oracle/start_oracle.ps1` rồi `sql/run_oracle_pipeline.ps1 -Server '.\MSSQLSERVER01' -Trusted`. Xem ORACLE.md cho bootstrap lần đầu, cấu hình kết nối, kiểm tra và dừng container.

Pipeline Oracle đọc snapshot nhất quán vào STG_OracleVPDD trước khi nạp DW. Các kiểm tra chọn DB_CUSTOMER_SOURCE=STG_OracleVPDD và xác minh dữ liệu thực khớp Oracle. Pipeline SQL-only vẫn dùng IDB_VPDD, độc lập với chế độ này.

## 6. Giao diện phương án A

Giao diện chính và trang 9 báo cáo dùng chung `dw-dm/static/app.css` và `shell.js`; mã gọi API ở `olap.js`, `reports.js`. Chart.js và Lucide được lưu cục bộ trong static/vendor, không cần CDN khi mở app. React tiếp tục mở cùng giao diện nên tự nhận thiết kế mới.

Màu nhấn/font ở đầu app.css. Dashboard giữ cấu trúc A đã chọn; màn Sales/Inventory giữ thêm cấp độ hiển thị và bộ lọc quý/tháng có sẵn để không mất chức năng. Bảng trên mobile chuyển thành các dòng nhãn–giá trị. Bộ chọn tìm được trong danh sách dài, hỗ trợ bàn phím. Chưa có dark mode.

Full refresh có khoảng chuyển đổi khi thay DW/cuboid; không trình chiếu hay gọi API giữa lúc pipeline đang chạy. Chờ script kiểm tra thành công rồi tải lại trang.
