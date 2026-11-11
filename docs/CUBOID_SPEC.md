# Đặc tả cuboid và API hiện hành

Tên bảng, measure dùng tiếng Việt viết tắt. API thử nghiệm `/api/sales/*`, `/api/inventory/*` và bảng `olap_s_*`, `olap_i_*` đã nghỉ dùng. Xem `/docs` của FastAPI cho hợp đồng đầy đủ.

Sales: `GET /api/doanh-so/v2?time_axis=quy&mh_axis=mh&kh_axis=kh`.
Inventory: `GET /api/ton-kho/v2?time_axis=nam&mh_axis=mh&loc_axis=tinh`.

| Trục | Các cấp hợp lệ |
|---|---|
| time_axis | none, nam, quy, thang |
| mh_axis | none, mh |
| kh_axis (sales) | none, loai_kh, kh |
| loc_axis (inventory) | none, tinh, tp, ch |

Ghép các cấp khác `none` theo thứ tự time/product/customer hoặc time/product/location. Tất cả `none` dùng hậu tố `all`. Sales có 4×2×3=24, inventory 4×2×4=32. Ví dụ `olap_ds_quy_mh_kh`, `olap_tk_thang_mh_ch`.

Kết quả `{cuboid, dim_cols, lattice, data}`. `lattice` đếm số trục hiển thị, không đếm số cột khóa phân cấp. Sales trả `tong_so_luong`, `tong_doanh_thu`; inventory trả `tong_ton_kho`. Khóa quý luôn kèm năm, tháng kèm quý/năm; thành phố kèm bang.

Bộ lọc chung: `loc_nam`, `loc_quy`, `loc_thang`, `loc_mh`. Sales thêm `loc_kh`, `loc_loai_kh`. Inventory thêm `loc_ch`, `loc_tp` (tên thành phố), `loc_bang`. Bộ lọc có thể chi tiết hơn trục hiển thị; backend chọn dữ liệu đủ chi tiết rồi nhóm lại. Trục không hợp lệ hoặc tháng không thuộc quý trả HTTP 400.

Tồn kho là semi-additive: không SUM các snapshot tháng. Khi có bộ lọc, giữ cửa hàng/mặt hàng tới bước chọn snapshot cuối trong từng kỳ, rồi mới nhóm theo các trục hiển thị. API có thể báo cuboid nguồn chi tiết thay vì tên nhóm kết quả; `dim_cols` mô tả đúng cột hiển thị.

Mã sinh 56 bảng: `dw-dm/create_56_cuboids_vi.sql`. Kiểm tra độc lập tất cả bảng: `scripts/validate_olap.py`. Giao diện và cả ba entry point legacy đều sử dụng `dw-dm/main.py`.
