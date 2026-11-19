# Đặc tả cuboid và API hiện hành

Định nghĩa duy nhất của hai khối nằm ở `dw-dm/cube_schema.py`. Script `scripts/gen_cuboids.py` sinh `dw-dm/create_cuboids_vi.sql` từ định nghĩa này; API (`cube_queries.py`) và bộ kiểm tra (`validate_olap.py`) dùng chung định nghĩa đó. Không sửa tay file SQL đã sinh.

## Chiều, phân cấp và số khối

Số khối của một cube bằng tích (số mức + 1 mức ALL) của từng chiều.

| Chiều | Phân cấp (chi tiết → tổng hợp) | Mức trong cube bán hàng | Mức trong cube tồn kho |
|---|---|---|---|
| Thời gian | ngày → tháng → quý → năm → ALL | 5 | 4 (snapshot theo tháng, không có ngày) |
| Mặt hàng | mặt hàng → ALL | 2 | 2 |
| Khách hàng | khách hàng → loại khách → ALL | 3 | — |
| Vị trí | cửa hàng → thành phố → bang → ALL | 4 | 4 |

- Cube bán hàng: 5 × 2 × 3 × 4 = **120** cuboid `olap_ds_*`.
- Cube tồn kho: 4 × 2 × 4 = **32** cuboid `olap_tk_*`.
- Tổng: **152** cuboid trong `OLAP_QuanLyBanHang`.

Tên bảng ghép các mức khác ALL theo thứ tự thời gian / mặt hàng / khách hàng / vị trí, ví dụ `olap_ds_quy_mh_tp`, `olap_ds_ngay_mh_kh_ch`, `olap_tk_thang_mh_ch`. Tất cả ALL dùng hậu tố `all`. Cột của mỗi mức giữ cả khóa của các mức cao hơn: quý kèm năm; ngày kèm tháng/quý/năm; thành phố kèm bang; cửa hàng kèm thành phố và bang.

## API khối dữ liệu

Bán hàng: `GET /api/doanh-so/v2?time_axis=quy&mh_axis=mh&kh_axis=loai_kh&loc_axis=tp`.
Tồn kho: `GET /api/ton-kho/v2?time_axis=nam&mh_axis=mh&loc_axis=tinh`.

| Trục | Các cấp hợp lệ |
|---|---|
| time_axis | none, nam, quy, thang, ngay (ngay chỉ có ở bán hàng) |
| mh_axis | none, mh |
| kh_axis (bán hàng) | none, loai_kh, kh |
| loc_axis | none, tinh, tp, ch |

Kết quả `{cuboid, dim_cols, lattice, data, tong_so_dong, bi_cat_bot}`. `lattice` đếm số trục hiển thị. Measure bán hàng: `tong_so_luong`, `tong_doanh_thu`; tồn kho: `tong_ton_kho`.

Các cuboid chi tiết có thể tới hơn 100.000 nhóm. API mặc định trả 2.000 dòng đầu theo thứ tự các cột chiều (`limit` tối đa 200.000) và báo `tong_so_dong` để giao diện ghi "Hiển thị x / y dòng". Biểu đồ chỉ vẽ 60 nhóm đầu.

Bộ lọc chung: `loc_nam`, `loc_quy`, `loc_thang`, `loc_mh`, `loc_bang`, `loc_tp` (tên thành phố), `loc_ch`. Bán hàng thêm `loc_kh`, `loc_loai_kh`. Bộ lọc có thể chi tiết hơn trục hiển thị; backend chọn cuboid nhỏ nhất chứa đủ cột cần lọc rồi nhóm lại. Trục không hợp lệ, tháng không thuộc quý hoặc trục ngày trên cube tồn kho trả HTTP 400.

## Tồn kho là semi-additive

Không cộng các snapshot tháng. Cuboid tồn theo năm/quý lấy snapshot tháng cuối trong kỳ của từng cửa hàng–mặt hàng rồi mới cộng qua cửa hàng/mặt hàng. Khi có bộ lọc, API làm cùng phép đó trên `olap_tk_thang_mh_ch`.

## Thao tác OLAP

| Thao tác | API | Ghi chú |
|---|---|---|
| Roll-up | `/api/olap/roll-up?cube=ds&tu=ch&len=tinh` | trong cùng phân cấp thời gian hoặc vị trí |
| Drill-down | `/api/olap/drill-down?cube=ds&xuong=ch&loc_bang=Texas` | giữ điều kiện của cấp trên |
| Slice | `/api/olap/slice?cube=ds&chieu=bang&gia_tri=Texas` | năm, loại khách, mặt hàng, bang |
| Dice | `/api/olap/dice?cube=ds&nhom=tp&loc_nam=2022&loc_loai_kh=DuLich` | nhiều điều kiện |
| Pivot | `/api/olap/pivot?cube=ds&hang=bang&cot=nam` | hai chiều bất kỳ trong năm, loại khách, mặt hàng, bang |
| Drill-across | `/api/olap/drill-across?nhom=nam&vi_tri=tinh` | ghép doanh số và tồn kho trên chiều dùng chung thời gian, vị trí |
| Drill-through | `/api/olap/drill-through?ch_key=1&nam=2022` | xuống từng lần cấp hàng của dòng đơn trong IDB |

Kiểm tra độc lập toàn bộ bảng: `scripts/validate_olap.py`.
