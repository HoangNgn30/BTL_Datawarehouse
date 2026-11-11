# React dashboard

React là lớp mở dashboard chính của FastAPI qua iframe. Mọi truy vấn chạy cùng origin của FastAPI, tránh hợp đồng API không đồng bộ giữa các bản thử nghiệm.

1. Khởi động FastAPI theo `../../SETUP.md`.
2. Đặt `REACT_APP_API_URL=http://127.0.0.1:8000` trước khi `npm start` hoặc `npm run build`.
3. Các component thử nghiệm khác được giữ lại để tham khảo, không được App hiện hành sử dụng.

Có thể chạy trực tiếp `http://127.0.0.1:8000/` và `/bao-cao` mà không cần React.
