# Cấu Trúc Project Backend NestJS

Backend cung cấp API auth và post cho Flutter app.

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
    └── posts/
```

Ý nghĩa chính:

- `src/main.ts`: khởi động NestJS, bật CORS, đặt prefix `/api`.
- `src/app.module.ts`: import `DatabaseModule`, `AuthModule`, `PostsModule`.
- `src/auth/`: đăng ký, đăng nhập, `/auth/me`, token guard.
- `src/common/`: crypto service và authenticated request type.
- `src/database/`: đọc/ghi dữ liệu demo vào `data/db.json`.
- `src/posts/`: danh sách, chi tiết, tạo, sửa, xóa post.

## auth/

```txt
src/auth/
├── auth.controller.ts
├── auth.guard.ts
├── auth.module.ts
├── auth.service.ts
└── auth.types.ts
```

Endpoint:

```txt
POST /api/auth/register
POST /api/auth/login
GET  /api/auth/me
```

## posts/

```txt
src/posts/
├── posts.controller.ts
├── posts.module.ts
├── posts.service.ts
└── posts.types.ts
```

Endpoint:

```txt
GET    /api/posts
GET    /api/posts/:id
POST   /api/posts
PATCH  /api/posts/:id
DELETE /api/posts/:id
```

Post hỗ trợ:

```txt
id
userId
title
body
imagePath
createdAt
updatedAt
```

