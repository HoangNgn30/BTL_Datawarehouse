# Đối chiếu báo cáo PDF cũ với thang điểm và bản cài đặt

Nguồn: `D:\KDL&KPDL\Báo cáo BTL Kho dữ liệu.pdf`, 65 trang. Số trang dưới đây là vị trí trang trong PDF. Đã trích xuất văn bản toàn bộ tài liệu và xem ảnh các trang sơ đồ 7, 10, 12, 13, 14. Đây là bản nhận xét; chưa chỉnh sửa PDF gốc.

## Điều chỉnh kết luận sau khi nhận PDF

Báo cáo cũ **đã có** chuyển đổi ngược hai nguồn thành EER, tích hợp EER, sơ đồ quan hệ IDB, thiết kế metadata/index và ánh xạ ETL. Nhận xét trước đó chỉ dựa trên BAO_CAO.md và mã đang có nên chưa phản ánh phần thiết kế trong PDF này.

Cần phân biệt ba mức: đã mô tả trong báo cáo; đã có mã cài đặt; đã có bằng chứng chạy. PDF có nội dung thiết kế không làm cho phần cài đặt tương ứng tự động hoàn thành. Pipeline hiện tại vẫn đọc nguồn bán hàng và staging Oracle trực tiếp để nạp DW, chưa đi qua một IDB tích hợp đầy đủ.

## 1. Nội dung có thể kế thừa

| Nội dung | Trang PDF | Cách sử dụng |
|---|---|---|
| Giới thiệu, mục tiêu, yêu cầu và đầu vào/đầu ra | 1–6 | Giữ khung, cập nhật công nghệ Oracle + SQL Server và các yêu cầu gốc |
| Chuyển đổi ngược, EER nguồn 1/nguồn 2, tích hợp | 6–12 | Giữ cách trình bày theo từng bước; sửa các lỗi sơ đồ/ngữ nghĩa |
| Sơ đồ quan hệ IDB | 13 | Dùng làm cơ sở cài IDB thực, sau khi sửa kiểu dữ liệu và khóa |
| Galaxy, fact/dimension, phân cấp | 13–21 | Giữ phương pháp; thay sơ đồ bằng mô hình hiện hành |
| Metadata và index | 21–25 | Dùng làm đặc tả để viết catalog/index thực; chưa coi là đã cài |
| Ánh xạ nguồn/IDB → DW | 25–33 | Giữ cấu trúc bảng ánh xạ, chỉnh tên cột, khóa, thời gian và fact |
| Hai cube, 24 + 32 cuboid, ROLAP | 33–49 | Giữ phần giải thích; sửa thứ tự phân cấp và danh sách bảng theo mã hiện hành |
| Giới thiệu ứng dụng và thao tác OLAP | 49–57 | Cập nhật ảnh giao diện A; tách 9 kịch bản demo khỏi 9 yêu cầu đề bài |
| Kiểm thử và kết luận | 57–65 | Thay kết luận 4 kịch bản bằng phạm vi/bằng chứng kiểm thử hiện hành |

## 2. Lỗi và phần cần cập nhật

| Ưu tiên | Trang | Vấn đề | Hướng sửa |
|---|---|---|---|
| Cao | 7, 12 | Overlapping được giải thích bằng việc khách mua ở hai thành phố; sơ đồ trang 12 ghi cả hai subtype là Khách hàng bưu điện, dù nhánh trái có HDV du lịch | Nhánh trái là Khách hàng du lịch. Khách có thể thuộc cả hai loại, độc lập với việc sống ở một thành phố. Ghi rõ overlapping và mức tham gia chuyên biệt hóa |
| Cao | 12–13 | EER tích hợp chưa thể hiện đầy đủ quan hệ thành phố nơi khách sống với văn phòng/thành phố; sơ đồ quan hệ trang 13 lại có liên kết này | Đồng bộ EER và mô hình quan hệ; một khách thuộc một thành phố, một thành phố có nhiều khách |
| Cao | 13 | HuongDanVien, DiaChiBuuDien và một số ThoiGian được vẽ kiểu integer; Giá dùng double | Tên/địa chỉ dùng NVARCHAR hoặc NVARCHAR2; thời gian DATE/TIMESTAMP/DATETIME2 phù hợp; tiền dùng DECIMAL/NUMBER với precision/scale rõ ràng |
| Cao | 14–18 | Fact bán hàng chỉ thể hiện khóa tháng–khách–mặt hàng, không giữ mã đơn/ngày chi tiết; bản cũ có 2 fact, 5 dimension | Đồng bộ với grain dòng đơn ma_don + mh_key; bổ sung Dim_Ngay và Fact_PhanBo của mã hiện tại, giải thích tại sao không gắn duy nhất một cửa hàng vào dòng bán hàng |
| Cao | 22–25 | Báo cáo mô tả catalog metadata, ETL_Log và nhiều index như thể đã được triển khai | Tạo DDL, dữ liệu catalog, index và bằng chứng thực thi tương ứng. ExtractAudit hiện có chỉ là một phần operational metadata |
| Cao | 24, 31 | Nói dimension dùng surrogate key nhưng sau đó nói giữ trực tiếp khóa nghiệp vụ; clustered index bán hàng được mô tả khác PK hiện tại | Chọn đúng cách đã cài và mô tả nhất quán. Giữ business key là một lựa chọn, không tự gọi đó là surrogate key. Phân biệt PK, clustered index và index phục vụ truy vấn |
| Cao | 29–30 | Ghi Faker/CSV, 20.000 khách và 150.000 đơn, khác bộ demo đang chạy 300 khách và 1.500 đơn | Nếu dùng bộ lớn thì cần script/CSV và log nạp đúng bộ đó. Nếu dùng demo hiện tại thì cập nhật toàn bộ bảng quy mô, công cụ sinh và ảnh kết quả |
| Cao | 32 | Công thức quý ghi tháng/3; một số tên nguồn như Ten, NgayDat, ThoiGianNhap khác mã đang chạy | Dùng DATEPART(QUARTER, ngay) hoặc (MONTH(ngay)-1)/3+1 với chia nguyên. Lập bảng tên nguồn/đích thống nhất |
| Cao | 33 | Hàng ánh xạ mh_key của Fact_Kho ghi đi qua Dim_CuaHang, nhưng quy tắc lại JOIN Dim_MatHang | Sửa đích tra cứu thành Dim_MatHang. Đồng bộ tồn kho từ TonKhoThang thay cho giả định nguồn có đủ lịch sử |
| Cao | 34, 36 | Chuỗi phân cấp nam → quy → thang → all và bang → thanhpho → ch_key → all đặt all sai đầu/cuối so với chiều trình bày | Với drill-down: all → năm → quý → tháng; all → bang → thành phố → cửa hàng; all → loại khách → khách. Roll-up đi ngược lại |
| Cao | 53 | Bảng 9 yêu cầu là 9 kịch bản OLAP (doanh thu, pivot, drill-across...), không phải 9 yêu cầu nghiệp vụ của đề | Có hai bảng riêng: 9 yêu cầu gốc gắn API/báo cáo tương ứng; các kịch bản minh họa thao tác OLAP |
| Cao | 58–64 | Đối chiếu cuboid với DW chỉ kiểm tra bước DW → OLAP; 4 kịch bản không chứng minh mọi bước nguồn → IDB → DW → OLAP đúng | Dùng đối chiếu nguồn trực tiếp và log 62 kiểm tra, 9 báo cáo, 87 kiểm tra API; bổ sung kiểm tra IDB khi cài xong tầng này. Nêu rõ phạm vi từng phép kiểm |
| Vừa | 10–11 | Tự gán ThoiGian thành ngày thành lập VP/CH hoặc ngày nhập hàng mà đề chưa định nghĩa | Chỉ gán ý nghĩa khi có đặc tả nguồn. Nếu chưa rõ, giữ tên trung tính và ghi giả định thay vì tự tạo ngữ nghĩa nghiệp vụ |
| Vừa | 9 | Bảng phân loại ghi SR1 nhưng đoạn giải thích chuyển sang SR2; mô tả Đặt hàng nói quan hệ khách–mặt hàng trong khi hình là đơn–mặt hàng | Sửa thuật ngữ theo định nghĩa trong lecture; giữ đúng hai thực thể tham gia và thuộc tính của liên kết |
| Vừa | 2, 13, 31 | Xen kẽ Star Schema và Galaxy; có lỗi “giải ngân hà” | Thống nhất: galaxy/fact constellation gồm các fact dùng chung dimension, có nhánh snowflake địa lý |
| Vừa | Toàn bộ | Chưa thấy phân công thành viên; nhiều hình chưa đánh số, có dòng “Chụp ảnh” còn sót | Bổ sung tên/mã SV/công việc/sản phẩm phụ trách từ thông tin thật; đánh số hình/bảng, cập nhật mục lục và bỏ lời nhắc biên soạn |

## 3. Đối chiếu lại 10 mục chấm điểm

1. **Tích hợp qua ER (0,5):** đã có trong PDF trang 6–12, nhưng cần sửa hình và ngữ nghĩa.
2. **Thiết kế dữ liệu tích hợp (1):** đã có sơ đồ quan hệ trang 13; chưa đủ bằng chứng triển khai IDB trong mã hiện tại.
3. **Sinh nguồn (1):** đã mô tả trang 29–30; phải thống nhất bộ dữ liệu được nộp với script/log.
4. **Thiết kế DW (1):** đã có galaxy; cần cập nhật grain, ngày, thành phố khách và phân bổ đơn theo bản cài đặt.
5. **Ánh xạ IDB → DW (1):** đã có bảng ánh xạ; cần sửa lỗi và cho ETL thực sự đọc IDB tích hợp.
6. **Phân cấp (0,5):** đã có; sửa thứ tự all và mô tả roll-up/drill-down.
7. **Metadata/index (1):** đã có thiết kế; cần DDL, catalog và bằng chứng index thật.
8. **Thiết kế cube (1):** có 24 + 32; rà tên cuboid theo script đã sửa.
9. **Tính sẵn + Web (2):** đã có nội dung và cài đặt hiện hành; thay ảnh cũ, bổ sung 9 yêu cầu gốc.
10. **Tài liệu (1):** dùng PDF cũ làm khung đầy đủ hơn; bổ sung phân công và chuẩn bị slide. Không tìm thấy file PPT/PPTX trong dự án ở lượt kiểm tra này.

Không suy ra điểm số chắc chắn từ việc có đề mục; cần nội dung đúng và bằng chứng chạy phù hợp.

## 4. Cách hợp nhất hai bản báo cáo

Dùng PDF cũ làm khung trình bày, BAO_CAO.md làm nguồn cập nhật triển khai, KIEM_THU.md và log làm bằng chứng. Không chép nguyên phần cài đặt cũ sang báo cáo mới: quy mô dữ liệu, công nghệ Oracle, số fact/dimension, khóa và giao diện đã thay đổi.

Thứ tự nên xử lý: sửa và chốt ER/IER/IDB → cài IDB và ETL → cài metadata/index → đồng bộ báo cáo và hình → thêm phân công → dựng slide bảo vệ.
