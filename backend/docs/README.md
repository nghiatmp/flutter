# Tài Liệu Kiến Thức Backend NestJS

Bộ tài liệu ghi lại cách backend hoạt động, viết ra để tham khảo lại khi quên.
Toàn bộ số liệu, log và response mẫu trong đây đều là **kết quả chạy thật**, không phải ví dụ bịa.

## Mục Lục

| File | Nội dung | Đọc khi nào |
|---|---|---|
| [01-tinh-nang-backend.md](01-tinh-nang-backend.md) | Danh sách đầy đủ tính năng, endpoint, cơ chế bảo mật | Cần tra nhanh "BE có gì" |
| [02-bootstrap-main-ts.md](02-bootstrap-main-ts.md) | `main.ts` chạy gì, theo thứ tự nào | Sửa cấu hình khởi động, CORS, ValidationPipe |
| [03-luong-request.md](03-luong-request.md) | Một request đi qua những chặng nào | Debug request, hiểu vì sao lỗi ở đâu |
| [04-exception-filter.md](04-exception-filter.md) | Cách API chuẩn hóa mọi lỗi | Sửa format lỗi, thêm loại lỗi mới |
| [05-module-va-di.md](05-module-va-di.md) | Module, Dependency Injection, `imports`/`exports` | Thêm module mới, gặp lỗi "can't resolve dependencies" |
| [06-van-de-ton-dong.md](06-van-de-ton-dong.md) | Rủi ro đã phát hiện + hướng xử lý | Trước khi deploy thật |
| [07-nodejs-va-nestjs.md](07-nodejs-va-nestjs.md) | Event loop, thread pool, decorator, DI hoạt động thế nào | Muốn hiểu *vì sao* chứ không chỉ *làm gì* |

## Tài Liệu Có Sẵn Từ Trước

- [../PROJECT_STRUCTURE.md](../PROJECT_STRUCTURE.md) — sơ đồ thư mục
- [../TECH_FLOW.md](../TECH_FLOW.md) — luồng auth/post tóm tắt

## Cách Chạy Backend

```bash
cd backend
npm install
npm run start:dev      # watch mode
```

Server: `http://localhost:3000/api`

Tài khoản demo được seed tự động:

```txt
email:    demo@studyflutter.com
password: 123456
```

## Bản Đồ Nhanh: Vấn Đề → File Cần Sửa

| Triệu chứng | Xem file nguồn |
|---|---|
| Gọi API trả 404 dù đã viết controller | `posts.module.ts` — quên khai `controllers` |
| Boot lỗi "can't resolve dependencies" | `*.module.ts` — thiếu `imports` / `exports` |
| Body gửi lên bị 400 "property X should not exist" | `main.ts` — `forbidNonWhitelisted` |
| Response bị bọc thêm `success`/`data` | `transform-response.interceptor.ts` |
| Lỗi trả về sai format | `http-exception.filter.ts` |
| 401 không thấy trong log | Guard chạy trước Interceptor — xem file 03 |
| Server đứng hình khi nhiều người login | `scryptSync` chặn event loop — xem file 07 |
| "Nest can't resolve dependencies" | Thiếu `imports`/`exports` — xem file 05 |
| Đổi tài khoản demo | `auth.service.ts` (nhớ đổi cả `AppConstants` bên Flutter) |
