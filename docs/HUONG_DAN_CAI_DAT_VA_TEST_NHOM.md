# Hướng dẫn cài đặt và kiểm thử dành cho thành viên nhóm

Tài liệu này hướng dẫn dựng đầy đủ dự án trên **Windows**, từ nhánh `group_test`. Mỗi thành viên có SQL Server, Oracle và dữ liệu mô phỏng riêng trên máy; thao tác thử nghiệm không thay đổi dữ liệu trên máy các bạn khác.

**Đọc theo thứ tự:** chuẩn bị → clone → môi trường Python → cấu hình → dựng dữ liệu lần đầu → chạy Web → test và feedback. Khi đã cài xong, những lần sau chỉ cần mục 8.

> Dùng tài liệu này làm hướng dẫn cài đặt chính cho nhóm. Các file hướng dẫn cũ có thể còn cổng `8000`, tham số `-Password` hoặc đường dẫn từ máy người viết. Tài liệu này thống nhất cổng Web `8017`, Windows Authentication và instance SQL Server riêng.

## 1. Cần chuẩn bị gì?

| Thành phần | Cách chuẩn bị và kiểm tra |
| --- | --- |
| Git | Cài Git for Windows. Mở PowerShell mới, chạy `git --version`. |
| Python 3.13 bản 64-bit | Chọn thêm Python vào PATH khi cài. Chạy `python --version`. Đây là phiên bản đã dùng kiểm thử dự án. |
| SQL Server 2022 Developer | Cài **Database Engine Services**; SSMS không thay thế SQL Server Engine. Nên tạo named instance `MSSQLSERVER01`. |
| Microsoft ODBC Driver 17 for SQL Server | Cấu hình mặc định của dự án dùng Driver 17. Nếu chỉ có Driver 18, xem mục xử lý lỗi để đổi đúng tên driver. |
| sqlcmd | Công cụ dòng lệnh để chạy SQL; kiểm tra bằng `sqlcmd -?`. |
| Docker Desktop | Cấu hình chạy Linux containers, mở Docker và đợi engine sẵn sàng. Kiểm tra `docker version` và `docker compose version`. |

Nguồn tải chính thức:

- Git: https://git-scm.com/downloads/win
- Python: https://www.python.org/downloads/windows/
- SQL Server: https://www.microsoft.com/en-us/sql-server/sql-server-downloads
- sqlcmd: https://learn.microsoft.com/en-us/sql/tools/sqlcmd/sqlcmd-download-install
- ODBC Driver: https://learn.microsoft.com/en-us/sql/connect/odbc/download-odbc-driver-for-sql-server
- Docker Desktop: https://docs.docker.com/desktop/setup/install/windows-install/

Khi cài SQL Server, chọn **Windows Authentication** và **Add Current User** ở phần quản trị SQL Server. Tài khoản chạy pipeline phải có quyền tạo cơ sở dữ liệu trên instance dùng cho bài tập.

**Khuyến nghị thực tế:** máy có RAM 16 GB trở lên sẽ thuận tiện hơn khi chạy SQL Server và Oracle cùng lúc. Đây không phải mức tối thiểu đã đo; máy ít RAM cần đóng bớt ứng dụng và có thể phải đợi lâu hơn khi tạo khối/kiểm thử. Lần đầu tải Oracle cần Internet và có thể mất nhiều phút.

Không cần cài Node.js, npm, React hoặc Oracle Instant Client để chạy giao diện Web chính.

## 2. Clone đúng phiên bản

Mở PowerShell ở nơi muốn lưu mã nguồn. Ví dụ lưu trong thư mục người dùng Windows:

```powershell
cd $env:USERPROFILE
git clone --branch group_test --single-branch https://github.com/HoangNgn30/BTL_Datawarehouse.git
cd BTL_Datawarehouse
git branch --show-current
git log -1 --oneline
```

Tên nhánh phải là `group_test`. Ghi lại mã commit để gửi kèm feedback.

Nếu đã clone, không cần clone lại. Mở đúng thư mục dự án và kiểm tra `git status` trước khi cập nhật; xem mục 10.

**Từ đây trở đi, chạy mọi lệnh tại thư mục gốc `BTL_Datawarehouse`**, nơi có các thư mục `dw-dm`, `sql`, `oracle`, `scripts`, `docs`. Không chạy bên trong thư mục `docs`.

## 3. Tạo môi trường Python

```powershell
python -m venv .venv
.\.venv\Scripts\Activate.ps1
python -m pip install -r .\dw-dm\requirements.txt
python -c "import sys; print(sys.executable)"
```

Dòng cuối phải trỏ vào `.venv\Scripts\python.exe` của dự án. Khi kích hoạt thành công, đầu dòng PowerShell thường có `(.venv)`.

Nếu Windows không tìm thấy Python nhưng có Python Launcher, dùng `py -3.13 -m venv .venv` thay lệnh đầu.

Nếu PowerShell chặn chạy `Activate.ps1`, chỉ điều chỉnh trong cửa sổ hiện tại rồi thử lại:

```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy RemoteSigned
.\.venv\Scripts\Activate.ps1
```

Không cần thay chính sách toàn máy. Các pipeline gọi lệnh `python`, nên phải kích hoạt đúng môi trường trước khi chạy chúng.

## 4. Cấu hình SQL Server

Chỉ sao chép file cấu hình **lần đầu**, khi chưa có `.env`:

```powershell
Copy-Item .\dw-dm\.env.example .\dw-dm\.env
notepad .\dw-dm\.env
```

Nội dung mặc định:

```dotenv
DB_SERVER=.\MSSQLSERVER01
DB_TRUSTED=yes
DB_DRIVER=ODBC Driver 17 for SQL Server
DB_OLAP=OLAP_QuanLyBanHang
DB_DW=DW_Core
DB_CUSTOMER_SOURCE=STG_OracleVPDD
CORS_ORIGINS=http://localhost:3000,http://127.0.0.1:3000
```

- Nếu cài named instance `MSSQLSERVER01`, giữ nguyên.
- Nếu cài `SQLEXPRESS`, đổi thành `.\SQLEXPRESS`.
- Nếu dùng default instance, có thể dùng `localhost`, nhưng cần xác minh đó đúng instance dành cho bài tập.
- Dùng tên instance giống nhau trong `.env` và mọi lệnh có tham số `-Server` / `-S`.
- Hướng dẫn này dùng Windows Authentication, không cần `sa`, `DB_USER` hoặc `DB_PASSWORD`.

Trong cửa sổ PowerShell hiện tại, đặt tên instance một lần. Nếu máy dùng tên khác, sửa dòng đầu:

```powershell
$DbServer = '.\MSSQLSERVER01'
$env:DB_SERVER = $DbServer
$env:DB_TRUSTED = 'yes'
$env:DB_CUSTOMER_SOURCE = 'STG_OracleVPDD'
sqlcmd -S $DbServer -E -C -b -Q "SELECT @@SERVERNAME AS ServerName;"
```

Lệnh phải in đúng tên server, không báo lỗi đăng nhập. Biến môi trường có ưu tiên cao hơn `.env`; nếu đã đặt nhầm `DB_SERVER` trong cửa sổ cũ, phải sửa lại hoặc mở PowerShell mới.

## 5. Tạo nguồn dữ liệu SQL — chỉ lần đầu

> Chọn instance riêng cho bài tập. Các tên DB của dự án là cố định. Không dùng chung với cơ sở dữ liệu thật có cùng tên và không tự thêm `-ResetDemo` để vượt thông báo bảo vệ dữ liệu.

Chạy lệnh thứ nhất và đợi kết thúc:

```powershell
sqlcmd -S $DbServer -E -C -b -f 65001 -v ResetDemo=0 -i .\sql\01_idb_source.sql
if ($LASTEXITCODE -ne 0) { throw 'Tao nguon SQL that bai. Dung tai day va doc loi.' }
```

Sau khi thành công, tạo phân bổ đơn hàng, biến động và snapshot tồn kho:

```powershell
sqlcmd -S $DbServer -E -C -b -f 65001 -i .\sql\01b_inventory_source.sql
if ($LASTEXITCODE -ne 0) { throw 'Tao du lieu ton kho that bai. Khong chay buoc tiep theo.' }
```

Bước này tạo dữ liệu mô phỏng cho `IDB_BanHang` và `IDB_VPDD`. `IDB_VPDD` cung cấp dữ liệu mẫu để khởi tạo nguồn khách hàng Oracle ở bước tiếp theo.

Nếu được báo nguồn đã tồn tại, dừng lại kiểm tra mình đang cài lần đầu hay mở lại bản đã cài. Script tồn kho cũng không phải script chạy lặp tùy ý: chạy lại khi bảng đã có sẽ báo lỗi.

## 6. Khởi tạo Oracle và dựng toàn bộ kho — lần đầu

Mở Docker Desktop trước. Sau khi `docker version` hiển thị cả Client và Server, chạy:

```powershell
.\oracle\start_oracle.ps1 -BootstrapDemo -Server $DbServer
```

Script sẽ:

1. Sinh mật khẩu riêng trên máy tại `oracle/secrets/`.
2. Khởi động container `kdl-oracle` từ `oracle/compose.yaml`.
3. Đợi Oracle healthy.
4. Tạo và nạp ba bảng khách hàng trong schema `KDL_VPDD`.

Kiểm tra khi cần:

```powershell
docker inspect kdl-oracle --format '{{.State.Health.Status}}'
```

Kết quả cần là `healthy`. Oracle dùng `127.0.0.1:1522/FREEPDB1`; SQL Server vẫn là instance đã cấu hình. Không cần tự tạo hoặc chia sẻ mật khẩu giữa các máy.

Sau khi bootstrap thành công, chạy:

```powershell
.\sql\run_oracle_pipeline.ps1 -Server $DbServer -Trusted
```

Luồng chạy:

```text
Oracle + nguồn bán hàng SQL Server
             ↓
       STG_OracleVPDD
             ↓
        IDB_TichHop
             ↓
          DW_Core
             ↓
    OLAP_QuanLyBanHang
             ↓
       Kiểm thử dữ liệu/API
```

Pipeline tạo IDB tích hợp, 3 fact trong DW, 56 cuboid, metadata và index; sau đó đối chiếu dữ liệu và kiểm tra API. Các kiểm tra API trong pipeline tự chạy bằng TestClient, chưa cần khởi động Web riêng.

Chỉ chuyển sang bước mở Web khi pipeline kết thúc thành công. Mốc kiểm tra của bản đã thử nghiệm là `62/62` OLAP, `9/9` truy vấn nghiệp vụ, `89` API/UI và `28/28` IDB/metadata/index. Nếu phiên bản mới bổ sung test, số lượng có thể thay đổi; điều kiện là không có test thất bại hoặc traceback.

**Không chạy cả `run_all.ps1` rồi làm lại mục 5.** Mục 5–6 đã là một quy trình hoàn chỉnh. `run_all.ps1` là lối dựng demo SQL-only khác; không cần dùng khi làm theo luồng Oracle ở tài liệu này.

## 7. Mở Web lần đầu

Tại thư mục gốc, trong PowerShell đã kích hoạt `.venv`:

```powershell
python -m uvicorn main:app --app-dir dw-dm --host 127.0.0.1 --port 8017
```

Đợi dòng thông báo server chạy tại `http://127.0.0.1:8017` rồi mở:

- Tổng quan và OLAP: http://127.0.0.1:8017/
- Báo cáo nghiệp vụ: http://127.0.0.1:8017/bao-cao
- Danh sách API: http://127.0.0.1:8017/docs

Giữ cửa sổ này mở trong lúc test. Không gõ tiếp các lệnh kiểm tra trong cửa sổ đang chạy Web; mở cửa sổ PowerShell khác nếu cần. Dừng Web bằng `Ctrl + C`.

Không cần `npm start`. Giao diện chính đã được FastAPI phục vụ trực tiếp; biểu đồ và icon nằm trong thư mục static của dự án.

## 8. Những lần mở lại sau khi đã cài xong

1. Bật SQL Server instance của dự án và Docker Desktop.
2. Mở PowerShell tại thư mục gốc.
3. Chạy:

```powershell
.\.venv\Scripts\Activate.ps1
.\oracle\start_oracle.ps1
python -m uvicorn main:app --app-dir dw-dm --host 127.0.0.1 --port 8017
```

Web đọc kho đã lưu trong SQL Server nên **không cần tạo lại dữ liệu hoặc chạy pipeline mỗi lần mở**. Oracle cần hoạt động khi kiểm thử đồng bộ hoặc nạp lại dữ liệu; chỉ xem DW đã nạp thì Web không truy vấn trực tiếp Oracle.

Khi muốn đồng bộ nguồn và dựng lại DW/cuboid, dừng Web hoặc thống nhất cả nhóm không dùng trong lúc nạp rồi chạy:

```powershell
$DbServer = '.\MSSQLSERVER01'  # Đổi nếu máy dùng instance khác
.\sql\run_oracle_pipeline.ps1 -Server $DbServer -Trusted
```

Không thêm `-BootstrapDemo` khi Oracle đã có bảng. Không xóa `oracle/secrets/` sau khi đã tạo volume Oracle, vì file mật khẩu mới có thể không khớp mật khẩu trong DB cũ.

## 9. Nhóm cần test gì?

Không tự sửa dữ liệu để làm test đạt. Trước tiên dùng bộ dữ liệu mô phỏng chuẩn và ghi lại chính xác trường hợp lỗi.

| Phần | Thao tác gợi ý | Kết quả cần quan sát |
| --- | --- | --- |
| Tổng quan | Mở trang, xem KPI, biểu đồ và bảng; bấm dòng doanh số theo năm | Có dữ liệu; giao dịch gốc mở đúng năm đã chọn |
| Doanh số | Đổi năm/quý/tháng, mặt hàng, khách hàng; áp dụng và đặt lại | Bảng và biểu đồ đổi theo điều kiện; không giữ nhầm bộ lọc sau đặt lại |
| Tồn kho | Đổi cấp thời gian, bang/thành phố/cửa hàng; lọc một năm hoặc quý | Kết quả phản ánh tồn cuối kỳ, không cộng tồn qua nhiều tháng |
| Roll-up / Drill-down | Tổng hợp tháng lên quý/năm; khoan từ năm xuống quý/tháng | Cấp thời gian thay đổi đúng; roll-up không cho cuộn sai hướng |
| Slice / Dice | Chọn khối và điều kiện phù hợp | Chỉ trả dữ liệu thỏa điều kiện; không cho chọn tổ hợp chưa hỗ trợ |
| Pivot | Xoay năm với loại khách hàng hoặc mặt hàng | Hàng/cột đổi đúng; mã số theo thứ tự số, không phải 1, 10, 2 |
| Đối chiếu và chi tiết | Drill-across theo thời gian, drill-through theo bộ lọc | Có kết quả tương ứng; bảng chi tiết giữ đúng điều kiện |
| 9 truy vấn nghiệp vụ | Chạy lần lượt 1–9, đổi tham số; thử trường hợp không có kết quả | Không lỗi SQL; đúng cột, đúng điều kiện; trạng thái rỗng rõ ràng |
| Giao diện | Thử màn hình nhỏ, menu, danh sách chọn dài, đóng modal bằng Escape | Chữ đọc được, điều khiển dùng được, không che nút quan trọng |

Phạm vi hiện tại: Pivot phục vụ doanh số với các cặp chiều nêu trên; Drill-across dùng chiều thời gian. Không coi việc chưa có Pivot tồn kho hoặc tổ hợp bất kỳ là lỗi ngoài phạm vi.

Nếu cần kiểm tra riêng, mở PowerShell khác tại thư mục gốc và kích hoạt `.venv`, sau đó chạy từng lệnh:

```powershell
python scripts/test_api_contracts.py
python scripts/oracle_sync.py verify
python scripts/validate_idb.py
python scripts/validate_olap.py
python scripts/validate_reports.py
python scripts/test_api.py
```

Các kiểm tra DB cần dữ liệu đã được nạp. `scripts/test.py` chỉ liệt kê driver, không phải bộ kiểm thử dự án. `test_oracle_pipeline.py` là kiểm thử có tạm thay đổi dữ liệu demo rồi khôi phục; không cần chạy trong đợt kiểm thử giao diện thông thường.

## 10. Cập nhật khi nhóm trưởng đẩy bản mới

Tại thư mục gốc, kiểm tra nhánh và trạng thái trước:

```powershell
git branch --show-current
git status --short
```

Nếu không có thay đổi mã nguồn cần giữ, cập nhật:

```powershell
git pull --ff-only
python -m pip install -r .\dw-dm\requirements.txt
git log -1 --oneline
```

- Chỉ đổi giao diện/backend: khởi động lại Web, tải lại bằng `Ctrl + F5`.
- Đổi ETL/cuboid/metadata: chạy lại pipeline Oracle sau khi nhóm trưởng xác nhận cách cập nhật.
- Đổi bảng nguồn hoặc yêu cầu tạo lại dữ liệu: làm theo hướng dẫn riêng của bản cập nhật; không chạy lại mục 5 trên DB đang có.
- Không chép `.env.example` đè lên `.env` mỗi lần pull; giữ cấu hình đúng máy mình.
- Nếu Git báo xung đột hoặc thay đổi cục bộ, gửi `git status` cho nhóm trưởng. Không dùng `git reset --hard` để bỏ qua khi chưa biết dữ liệu nào sẽ mất.

## 11. Xử lý lỗi thường gặp

| Triệu chứng | Cách kiểm tra/xử lý |
| --- | --- |
| `python` mở Microsoft Store hoặc không tìm thấy | Kiểm tra Python/PATH; thử `py -3.13 --version`; mở terminal mới sau khi cài. |
| `ModuleNotFoundError` | Kích hoạt `.venv`, kiểm tra `python -c "import sys; print(sys.executable)"`, cài lại requirements bằng `python -m pip`. |
| Không tìm thấy `sqlcmd` | Cài sqlcmd, mở PowerShell mới, chạy `sqlcmd -?`. |
| `IM002`, không tìm thấy ODBC driver | Chạy `python -c "import pyodbc; print(pyodbc.drivers())"`. Cài Driver 17, hoặc sửa `DB_DRIVER` trong `.env` đúng tên Driver 18 thực sự đã cài. |
| `Login failed`, timeout khi kết nối SQL | Chạy lại lệnh kiểm tra ở mục 4. Xem instance có đang chạy không; tên server phải thống nhất; tài khoản Windows cần quyền tương ứng. Không tự đổi sang tài khoản sa. |
| Docker báo không kết nối được daemon | Bật Docker Desktop, đợi engine hoạt động; kiểm tra `docker version`. Nếu Docker yêu cầu hoàn tất WSL/khởi động lại Windows, xử lý xong trước khi chạy Oracle. |
| Oracle `starting` hoặc startup timeout | Chạy `docker logs --tail 100 kdl-oracle`, kiểm tra RAM/đĩa. Lần đầu tải và khởi tạo có thể lâu; không xóa volume để thử lại. |
| Oracle báo tên container/cổng 1522 đã được dùng | Kiểm tra `docker ps -a` và tiến trình đang dùng cổng. Gửi thông tin cho nhóm trưởng trước khi đổi cấu hình hoặc xóa container. |
| Bootstrap báo bảng Oracle đã tồn tại | Nếu đã cài xong trước đó, bỏ `-BootstrapDemo`, chỉ khởi động Oracle rồi chạy pipeline. Nếu cài dở, gửi log để xác định trạng thái trước khi tiếp tục. |
| Nguồn SQL đã tồn tại / bảng đã tồn tại | Không chạy lại bước tạo nguồn trên bản đã cài. Xác định đúng instance và bước đã hoàn thành; không tự bật ResetDemo. |
| `Invalid object name ...TonKhoThang`, thiếu `IDB_TichHop` hoặc `Fact_PhanBo` | Có thể chưa dựng đủ bước hoặc đang kết nối nhầm instance. Kiểm tra mục 4, sau đó xác định bước 5–6 nào chưa thành công. Không chỉ tạo cuboid trên schema cũ. |
| Có Web nhưng lỗi tải dữ liệu | Kiểm tra `.env`, instance SQL, log terminal Web và kết quả pipeline; sau khi sửa `.env` phải khởi động lại Web. |
| `WinError 10048` / cổng 8017 đang dùng | Có thể Web đã chạy. Thử mở URL trước; chỉ dừng tiến trình Web của chính dự án. Không dừng ngẫu nhiên tiến trình khác. |
| Query/pipeline chạy rất chậm | SQL có thể chờ cấp RAM (`RESOURCE_SEMAPHORE`). Đóng bớt ứng dụng nặng, không chạy nhiều pipeline/test cùng lúc. Gửi thời gian chờ và log nếu không tiến triển. |
| Kết quả kiểm thử không khớp | Ghi commit, instance, `DB_CUSTOMER_SOURCE` và phần log lỗi đầu tiên. Xác định có ai vừa sửa dữ liệu hoặc nạp kho không. Không sửa giá trị kỳ vọng để làm test xanh. |
| `git pull --ff-only` không thành công | Gửi `git status -sb` và thông báo lỗi; không tự force/reset khi chưa xác định thay đổi cục bộ. |

Muốn lưu log một lượt cài/nạp trong PowerShell, lưu ra thư mục tạm ngoài repo:

```powershell
$TestLog = Join-Path $env:TEMP ("kdl-test-" + (Get-Date -Format 'yyyyMMdd-HHmmss') + '.txt')
Start-Transcript -Path $TestLog
# Chạy lệnh cần kiểm tra, ví dụ pipeline ở mục 6
Stop-Transcript
Write-Output $TestLog
```

Đọc lại log trước khi gửi; không gửi file `.env`, file mật khẩu, token hoặc nội dung `oracle/secrets/`.

## 12. Mẫu feedback gửi lại nhóm trưởng

Mỗi lỗi gửi một mục riêng, kèm ảnh hoặc đoạn log liên quan. Copy mẫu sau:

```text
Người kiểm thử:
Ngày/giờ:
Commit (git log -1 --oneline):
Windows / RAM / trình duyệt:
SQL Server instance:
Đã dựng pipeline Oracle thành công: Có / Không

Loại phản hồi: Lỗi cài đặt / Lỗi dữ liệu / Lỗi thao tác / Giao diện / Góp ý
Mức ảnh hưởng: Chặn chạy / Sai kết quả / Khó sử dụng / Nhỏ
Màn hình hoặc lệnh gặp lỗi:
Điều kiện đầu vào/bộ lọc:

Các bước tái hiện:
1.
2.
3.

Kết quả thực tế:
Kết quả mong muốn và lý do:
Lặp lại được không: Luôn luôn / Thỉnh thoảng / Một lần
Ảnh hoặc log đính kèm:
Đã thử cách xử lý nào:
```

Ví dụ tốt: “Commit X, trang Tồn kho, chọn năm 2022 và quý 2, bấm Áp dụng; bảng báo lỗi Y; tái hiện 3/3 lần; ảnh và log đính kèm.” Tránh chỉ gửi “không chạy” hoặc “số liệu sai” mà không có bộ lọc.

Nếu mọi thứ hoạt động, cũng gửi xác nhận: **commit đã test, cài từ đầu thành công hay chỉ cập nhật, các màn đã thử và phần chưa thử**. Không cần chạy thành công trên một máy rồi khẳng định mọi máy đều đạt.

## 13. Checklist trước khi báo đã cài/test xong

- [ ] Đúng nhánh `group_test`, có ghi mã commit.
- [ ] Python đang dùng `.venv` của dự án.
- [ ] Kết nối SQL đúng instance bằng Windows Authentication.
- [ ] Oracle healthy và bootstrap chỉ chạy một lần.
- [ ] Pipeline hoàn tất, không có test thất bại.
- [ ] Mở được Web tại cổng 8017, có dữ liệu ở Tổng quan.
- [ ] Đã thử Doanh số, Tồn kho, OLAP và 9 truy vấn nghiệp vụ theo phân công.
- [ ] Có feedback rõ ràng hoặc xác nhận các phần đã đạt.
- [ ] Không đưa mật khẩu hay file cấu hình cá nhân lên GitHub.

**Không chạy `docker compose down -v`, không xóa DB, không dùng ResetDemo chỉ để khắc phục một lỗi chưa xác định.** Nếu cần làm lại môi trường demo, thống nhất với nhóm trưởng trước để biết phần dữ liệu nào sẽ bị mất.
