# Cấu Trúc Project Backend NestJS

File này mô tả cách backend được chia thư mục và vai trò của từng phần.

## Tổng Quan

```txt
backend/
├── package.json
├── nest-cli.json
├── tsconfig.json
├── data/
└── src/
    ├── main.ts
    ├── app.module.ts
    ├── auth/
    ├── common/
    ├── database/
    ├── tasks/
    └── posts/
```

Ý nghĩa chính:

- `package.json`: script chạy, build và danh sách dependency.
- `src/main.ts`: điểm khởi động NestJS, bật CORS và đặt prefix `/api`.
- `src/app.module.ts`: module gốc, import các module nghiệp vụ.
- `src/auth/`: đăng ký, đăng nhập, lấy account hiện tại và guard bảo vệ API.
- `src/common/`: phần dùng chung như crypto service và request type.
- `src/database/`: đọc/ghi dữ liệu demo vào file JSON local.
- `src/tasks/`: CRUD task theo user đang đăng nhập.
- `src/posts/`: API bài viết public và CRUD bài viết theo user.
- `data/`: dữ liệu local sinh ra khi server chạy.

## auth/

```txt
src/auth/
├── auth.controller.ts
├── auth.guard.ts
├── auth.module.ts
├── auth.service.ts
└── auth.types.ts
```

Vai trò:

- `auth.controller.ts`: khai báo endpoint `/auth/register`, `/auth/login`, `/auth/me`.
- `auth.service.ts`: xử lý validate, hash password, kiểm tra login và tạo token.
- `auth.guard.ts`: đọc Bearer token và gắn user hiện tại vào request.
- `auth.types.ts`: định nghĩa type cho request/response auth.

## database/

```txt
src/database/
├── database.module.ts
├── database.service.ts
└── database.types.ts
```

Vai trò:

- `database.service.ts`: load/save dữ liệu từ `data/db.json`.
- `database.types.ts`: định nghĩa `UserRecord`, `TaskRecord`, `PostRecord`.
- `database.module.ts`: export `DatabaseService` để các module khác dùng chung.

## tasks/

```txt
src/tasks/
├── tasks.controller.ts
├── tasks.module.ts
├── tasks.service.ts
└── tasks.types.ts
```

Vai trò:

- `tasks.controller.ts`: khai báo API task.
- `tasks.service.ts`: xử lý danh sách, chi tiết, tạo, sửa, xóa task.
- Mọi task đều gắn với `userId`, nên user chỉ thấy task của chính mình.

## posts/

```txt
src/posts/
├── posts.controller.ts
├── posts.module.ts
├── posts.service.ts
└── posts.types.ts
```

Vai trò:

- `posts.controller.ts`: khai báo API post.
- `posts.service.ts`: xử lý danh sách, chi tiết, tạo, sửa, xóa bài viết.
- `GET /posts` và `GET /posts/:id` là public.
- Tạo, sửa, xóa post cần đăng nhập.

