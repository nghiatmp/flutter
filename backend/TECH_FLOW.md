# Luồng Hoạt Động Kỹ Thuật Của Backend

## Công Nghệ Chính

```txt
nestjs
typescript
node crypto
local json database
```

## Chạy Backend

```txt
cd backend
npm install
npm run start:dev
```

Server mặc định:

```txt
http://localhost:3000/api
```

## Auth Flow

Đăng ký:

```txt
POST /api/auth/register
  -> validate dữ liệu
  -> hash password
  -> lưu user vào data/db.json
  -> trả user + accessToken
```

Đăng nhập:

```txt
POST /api/auth/login
  -> tìm user theo email
  -> verify password
  -> trả user + accessToken
```

Lấy account hiện tại:

```txt
GET /api/auth/me
Authorization: Bearer <accessToken>
```

## Post Flow

Lấy danh sách:

```txt
GET /api/posts
```

Tạo post:

```txt
POST /api/posts
Authorization: Bearer <accessToken>
```

Body:

```json
{
  "title": "Bài viết",
  "body": "Nội dung",
  "imagePath": "/path/to/image.jpg"
}
```

Nếu DB chưa có post, backend tự seed vài bài demo khi khởi động.

## Dữ Liệu Local

Backend lưu dữ liệu demo vào:

```txt
backend/data/db.json
```

File này phù hợp cho học tập/demo local. Khi cần backend thật hơn, có thể thay `DatabaseService` bằng PostgreSQL, MySQL, SQLite hoặc MongoDB.

