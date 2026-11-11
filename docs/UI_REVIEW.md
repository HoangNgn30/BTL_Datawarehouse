# Bàn giao giao diện A

Người dùng đã duyệt brief và chọn **A — Cân bằng số liệu và biểu đồ**. Dựng đủ tổng quan, doanh số, tồn kho, thao tác OLAP và 9 báo cáo. Không thêm tài khoản, thông báo hoặc tính năng ngoài bài tập.

- **Bố cục:** sidebar chung, số liệu đầu trang, biểu đồ trung tâm, bảng kết quả phía dưới. Màn báo cáo chọn một yêu cầu rồi hiển thị tham số/kết quả, thay cho 9 form dài nối tiếp.
- **Dáng:** flat, nền sáng, card không bóng; giữ màu chàm của dự án và font hệ thống. Control cao 40px desktop, 44px mobile; popup/modal có bóng riêng.
- **Chỗ đổi thương hiệu:** đầu `dw-dm/static/app.css`, token `--primary`, `--soft`, `--app-font`. Giao diện không có dark mode; ô nhập để trơn.
- **Dữ liệu:** bản chạy lấy API từ DW/cuboid. Số theo bang minh họa trong wireframe không đưa vào ứng dụng; biểu đồ thật hiển thị đủ bang của dữ liệu demo. Toàn bộ dữ liệu nghiệp vụ vẫn là bộ dữ liệu demo của bài tập.

## Đối chiếu phương án đã chọn

| Khối | Phương án A | Bản chạy |
|---|---|---|
| Khung chung | Sidebar 5 mục, header gọn | Giữ 5 mục và nhãn tiếng Việt, có menu mobile |
| Tổng quan | 4 chỉ số, 2 biểu đồ, bảng 3 năm | Giữ cấu trúc; Chart.js vẽ từ API thật |
| Doanh số/tồn kho | Điều kiện phía trên, biểu đồ rồi bảng | Giữ thêm cấp độ hiển thị, lọc quý/tháng và thông tin cuboid sẵn có để không mất chức năng |
| 9 báo cáo | Danh sách bên trái, điều kiện và kết quả bên phải | Giữ bố cục; mobile thành dải chọn báo cáo và kết quả bên dưới |
| Bảng mobile | Nhãn và giá trị đọc được không mất cột | Chuyển hàng bảng thành danh sách trường–giá trị |

Ảnh probe đầu bản chạy nằm trong output/ui/overview, nhưng được chụp lúc pipeline đang full refresh nên chưa dùng làm bằng chứng giao diện có dữ liệu hoàn chỉnh. Wireframe tạm tại thư mục TEMP/evon-design-kdl, đã gửi link và được chọn A.

## Kiểm tra và giới hạn

Cú pháp JS và kiểm tra DOM với API thật đã đạt. Kiểm tra DOM có stub canvas; không phải kiểm tra giao diện trực quan. Không thêm thư viện UI: tái sử dụng HTML/CSS, Chart.js hiện có; Lucide và Chart.js được vendoring để không phụ thuộc CDN khi mở app.

Công cụ Computer Use đã tự dừng vì không xác định chắc URL hiện tại trên Windows. Vì thế chưa hoàn tất cổng cuối của skill ui-ux (`references/design-process.md`, U4: “Chạy probe --sweep --wireframe … tới khi danh sách P trống”). Cần kiểm tra lại hình vẽ, popup, bàn phím và các bề rộng trung gian trong lượt trình duyệt tiếp theo.

Tự soi năm câu cuối: các card số liệu cùng khuôn; link/nút có hình thức phân biệt; một lớp card chính, không lồng card trong card trên tổng quan; chưa kết luận khoảng trống ở 1920; việc chính theo A đặt ở chỉ số/biểu đồ. Ba màn phân tích và trạng thái dữ liệu dài vẫn cần xác nhận trực quan cuối.

Muốn chỉnh thêm có thể dùng các mô tả: “thoáng hơn”, “bảng gọn hơn”, “tiêu đề đậm hơn”, “biểu đồ rộng hơn”.
