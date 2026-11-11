# Kết quả kiểm thử — 11/11/2026

## Môi trường và phạm vi

SQL Server trên instance riêng `.\MSSQLSERVER01`, Windows Authentication, ODBC Driver 17, Python 3.13. Instance được kiểm tra trống trước khi tạo các CSDL demo. Không sửa `.env` cá nhân hoặc chạy reset trên các instance chứa dữ liệu có sẵn của người dùng.

Nguồn: 12 thành phố, 30 cửa hàng, 60 mặt hàng, 300 khách, 1.500 đơn và 3.000 dòng đơn. Kết quả: 3.010 dòng phân bổ (một số dòng đơn tách cửa hàng), 35.172 snapshot tháng từ 977 cặp cửa hàng–mặt hàng, 56 cuboid.

## Bằng chứng đã chạy

| Kiểm tra | Kết quả | Bằng chứng |
|---|---|---|
| Nguồn → phân bổ/ledger → ETL → vật hóa cuboid → đối chiếu | 62/62 đạt; đủ 56 bảng | output/validation/pipeline.log |
| Đối chiếu từng hàng 9 báo cáo với truy vấn nguồn | 9/9 đạt tại bộ tham số lưu trong script | output/validation/reports.log |
| Tất cả tổ hợp trục, bộ lọc, pivot đảo chiều, drill-through, API báo cáo, tồn cuối quý | 87 kiểm tra đạt | output/validation/api.log |
| Chặn khởi tạo đè nguồn khi thiếu -ResetDemo | Dừng với SQL error 51000, trước bước xóa nguồn | output/validation/reset_guard.log |
| SQL mẫu cho 9 yêu cầu chạy trực tiếp | sqlcmd exit 0 | output/validation/report_sql.log |
| Cú pháp Python | py_compile không lỗi | main, query builder, các entry point và script kiểm tra |
| JavaScript tĩnh | Hai script inline parse thành công | Node vm.Script trên index.html và bao_cao.html |
| React production build | Compiled successfully; JS gzip 45.63 kB | react-scripts build, Node bundled |
| Trình duyệt Chrome | Dashboard có số liệu, Sales theo quý trả 12 dòng; YC2 khách 1 trả đúng 5 đơn/ngày | Kiểm tra trực tiếp tại cổng 8017 |

Các lỗi hồi quy đã kiểm tra gồm slice năm→loại KH, khách lọc mặt hàng, năm lọc quý, tồn theo bang lọc mặt hàng, quý/tháng không tương thích, giới hạn drill-through âm và pivot mặt hàng/năm theo cả hai chiều. Tồn lọc quý 2/2022 nhưng hiển thị năm được so với snapshot tháng 06/2022.

Tiền được so sánh bằng Decimal trong kiểm tra cuboid. Các báo cáo được so sánh theo nội dung hàng, không phụ thuộc thứ tự trả về. Bộ kiểm tra báo cáo dùng tham số mẫu (khách 1, đơn 1, mặt hàng 1, thành phố 1, ngưỡng 100, loại CaHai); không tuyên bố vét cạn mọi tổ hợp tham số.

## Giới hạn và điểm còn cần hoàn thiện trước khi nộp

- Oracle đã triển khai thực tế bằng container KDL riêng; nguồn khách hàng được đọc qua thin driver vào staging rồi DW. Chi tiết bổ sung bên dưới.
- Dữ liệu là demo có giả định tồn đầu kỳ và chỉ có xuất kho. Chưa mô phỏng nhập/trả hàng, SCD2 hay tải tăng dần.
- Máy từng có áp lực RAM: SQL Server báo RESOURCE_SEMAPHORE và một lượt kết nối bị timeout. Chạy lại tuần tự đạt các kết quả ở bảng trên; đây không phải kết quả đo tải hay cam kết thời gian phản hồi.
- React hiện nhúng giao diện FastAPI qua iframe để dùng chung luồng API. Các component thử nghiệm cũ không nằm trong bản chạy.

Tài liệu thiết kế và sơ đồ nằm trong BAO_CAO.md. Lệnh chạy đầy đủ trong SETUP.md.


## Bổ sung Oracle và giao diện A

- Oracle thực tế: **23.26.3.0.0**, service FREEPDB1, schema KDL_VPDD; 300 khách, 200 bản ghi du lịch, 150 bưu điện.
- `output/validation/oracle-regressions.log`: **2/2** ca tích hợp đạt; sửa tên tiếng Việt ở Oracle đi tới DW, khóa thành phố sai bị từ chối và staging rollback; dữ liệu thử được khôi phục.
- `output/validation/oracle-pipeline.log`: pipeline hai hệ quản trị chạy hết, **62/62** đối chiếu, **9/9** báo cáo, **87** kiểm tra API đạt. Verify so sánh toàn bộ thuộc tính Oracle → staging → Dim_KhachHang.
- `output/validation/ui-dom.log`: các tương tác DOM đạt với API thật: chỉ số/bảng tổng quan, lọc doanh số, custom select, drill-through, mở/đóng menu, báo cáo 2 có 5 dòng và báo cáo 9 có 50 dòng. Chart.js được stub trong bài kiểm tra DOM; không kiểm chứng hình vẽ canvas hay kích thước bố cục bằng bài kiểm tra này.
- Wireframe A/B/C đã mở bằng probe ở 375/1440; người dùng chọn A. Bản UI thật có lượt probe nhanh ở 375/1440. Lượt này trùng lúc full refresh nên ảnh 1440 có lỗi tải API tạm thời; lỗi cỡ chữ 11px được sửa thành 12px. Các API đã đạt sau khi refresh hoàn tất.
- **Chưa hoàn tất kiểm thử trực quan cuối/sweep/so sánh pixel và thao tác bàn phím trong trình duyệt thật.** Công cụ Computer Use tự dừng vì không xác định chắc URL hiện tại trên Windows để kiểm tra chính sách. Không coi kiểm tra DOM là thay thế cho lượt này.

Thay đổi hiệu năng demo: ETL và vật hóa cuboid dùng MAXDOP 1, MAX_GRANT_PERCENT=0 để xin mức bộ nhớ tối thiểu trong default resource pool; Oracle SGA target 768MB và PGA target 128MB, trong giới hạn container 2GB. Đây là cấu hình cho bộ dữ liệu nhỏ, không phải cấu hình đo tải sản xuất.

- Khởi động lại Oracle qua start_oracle.ps1 đã đạt healthy, giữ volume và đối chiếu lại toàn bộ Oracle → staging → DW thành công: output/validation/oracle-restart.log.
