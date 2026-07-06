# Luồng Hoạt Động Kỹ Thuật Của Backend

File này mô tả backend NestJS chạy như thế nào, dữ liệu đi qua các lớp nào và các API đang có.

## Công Nghệ Chính

```txt
nestjs
typescript
node crypto
local json database
```

Vai trò:

- `nestjs`: framework backend chính.
- `typescript`: type checking cho source backend.
- `node crypto`: hash password và ký token demo.
- `local json database`: lưu dữ liệu học tập vào `data/db.json`.

## Chạy Backend

```txt
cd backend
npm install
npm run start:dev
```

Server mặc định chạy tại:

```txt
http://localhost:3000/api
```

## Sơ Đồ Tổng Quát

```txt
HTTP request
  |
  v
Controller
  |
  v
Service
  |
  v
DatabaseService
  |
  v
data/db.json
```

Với API cần đăng nhập:

```txt
HTTP request
  |
  v
AuthGuard đọc Authorization: Bearer <token>
  |
  v
AuthService tìm user
  |
  v
Controller xử lý request với request.user
```

## Auth Flow

### Đăng Ký

```txt
POST /api/auth/register
  -> AuthController.register()
  -> AuthService.register()
  -> validate email/password/profile
  -> hash password
  -> lưu user vào data/db.json
  -> trả user + accessToken
```

Body:

```json
{
  "fullName": "Demo User",
  "email": "demo@example.com",
  "password": "123456",
  "gender": "Nam",
  "hobbies": ["Đọc sách"],
  "birthDate": "2000-01-01",
  "city": "Hà Nội",
  "acceptedTerms": true
}
```

### Đăng Nhập

```txt
POST /api/auth/login
  -> AuthController.login()
  -> AuthService.login()
  -> tìm user theo email
  -> verify password
  -> trả user + accessToken
```

Body:

```json
{
  "email": "demo@example.com",
  "password": "123456"
}
```

### Lấy Account Hiện Tại

```txt
GET /api/auth/me
Authorization: Bearer <accessToken>
```

Flow:

```txt
AuthGuard verify token
  -> lấy userId từ token
  -> tìm user
  -> trả public user
```

## Task Flow

Các API task đều yêu cầu đăng nhập:

```txt
GET    /api/tasks
GET    /api/tasks/:id
POST   /api/tasks
PATCH  /api/tasks/:id
DELETE /api/tasks/:id
```

Body tạo task:

```json
{
  "title": "Học Flutter",
  "description": "Kết nối NestJS API",
  "imagePath": null
}
```

Luồng tạo task:

```txt
POST /api/tasks
  -> AuthGuard lấy user hiện tại
  -> TasksController.create()
  -> TasksService.create(userId, body)
  -> lưu task có userId vào data/db.json
```

## Post Flow

API public:

```txt
GET /api/posts
GET /api/posts/:id
```

API cần đăng nhập:

```txt
POST   /api/posts
PATCH  /api/posts/:id
DELETE /api/posts/:id
```

Body tạo post:

```json
{
  "title": "Bài viết demo",
  "body": "Nội dung bài viết"
}
```

Khi sửa hoặc xóa post, backend kiểm tra `post.userId` phải trùng user đang đăng nhập.

## Dữ Liệu Local

Backend lưu dữ liệu vào:

```txt
backend/data/db.json
```

File này chỉ dành cho demo/học tập. Khi cần backend thật hơn, có thể thay `DatabaseService` bằng database như PostgreSQL, MySQL, SQLite hoặc MongoDB.

