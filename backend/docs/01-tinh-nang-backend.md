# Tính Năng Backend

Stack: **NestJS 10 + TypeScript 5.7 + Express**, dữ liệu lưu file JSON local.

## Sơ Đồ Module

```txt
AppModule
├── ConfigModule      (global)  đọc + validate .env bằng Joi
├── ThrottlerModule             rate limit toàn cục
├── DatabaseModule    (@Global) đọc/ghi data/db.json
├── AuthModule                  đăng ký, đăng nhập, profile, đổi mật khẩu
├── PostsModule                 CRUD bài viết
└── HealthModule                health check
```

---

## 1. Authentication

Thư mục: `src/auth/`

| Method | Endpoint | Auth | Chức năng |
|---|---|---|---|
| POST | `/api/auth/register` | — | Đăng ký, trả `user` + `accessToken` |
| POST | `/api/auth/login` | — | Đăng nhập bằng email + password |
| GET | `/api/auth/me` | Bearer | Lấy thông tin tài khoản hiện tại |
| PATCH | `/api/auth/me` | Bearer | Cập nhật profile |
| POST | `/api/auth/change-password` | Bearer | Đổi mật khẩu |

### Trường dữ liệu user

```txt
id            uuid
fullName      bắt buộc
email         bắt buộc, unique, tự động lowercase + trim
passwordHash  KHÔNG BAO GIỜ trả ra response
gender        tùy chọn
hobbies       mảng string
birthDate     string
city          string
acceptedTerms bắt buộc = true khi đăng ký
createdAt / updatedAt
```

### Điểm cần nhớ

- **Không cho đổi email** qua `PATCH /api/auth/me` — `UpdateProfileBody` cố ý không khai field `email`
  (xem comment tại `auth.types.ts`). Muốn đổi email phải viết luồng riêng có xác minh.
- **Đổi mật khẩu bắt buộc nhập mật khẩu hiện tại** — chống chiếm tài khoản khi token bị lộ.
- `PublicUser = Omit<UserRecord, "passwordHash">` — kiểu TypeScript đảm bảo hash không lọt ra ngoài.
- Email được chuẩn hóa bằng `normalizeEmail()`: `.trim().toLowerCase()` cả lúc đăng ký lẫn đăng nhập.

### Tài khoản demo tự seed

`AuthService.onModuleInit()` chạy lúc boot, tạo sẵn nếu chưa có:

```txt
demo@studyflutter.com / 123456
```

> ⚠️ Đổi ở `auth.service.ts` thì phải đổi luôn `AppConstants.demoUserEmail/Password` bên Flutter.

---

## 2. Posts CRUD

Thư mục: `src/posts/`

| Method | Endpoint | Auth | Chức năng |
|---|---|---|---|
| GET | `/api/posts` | — | Danh sách, sort `createdAt` giảm dần |
| GET | `/api/posts/:id` | — | Chi tiết, 404 nếu không có |
| POST | `/api/posts` | Bearer | Tạo mới |
| PATCH | `/api/posts/:id` | Bearer | Sửa (partial) |
| DELETE | `/api/posts/:id` | Bearer | Xóa |

### Trường dữ liệu post

```txt
id         uuid
userId     LẤY TỪ TOKEN, không lấy từ body
title      bắt buộc
body       bắt buộc
imagePath  string | null
createdAt / updatedAt
```

### Phân quyền

`PostsService.findOwnedPost()` kiểm tra `post.userId === userId` trước khi sửa/xóa.
Không khớp → **403 Forbidden**, message `"Bạn không có quyền sửa bài viết này"`.

Đọc (`GET`) thì **không cần đăng nhập** — ai cũng xem được.

### Seed post demo

`DatabaseService.load()` tự tạo 3 post mẫu (`demo-post-1/2/3`, `userId: "system"`) nếu DB rỗng,
để màn Posts bên Flutter có nội dung ngay khi mở app.

---

## 3. Bảo Mật

### Hash mật khẩu — `common/crypto.service.ts`

```txt
scrypt(password, salt, 64)  với salt = randomBytes(16)
lưu dạng "salt:hash"
so sánh bằng timingSafeEqual()  → chống timing attack
```

### Access token — tự cài đặt, KHÔNG dùng thư viện JWT

Cấu trúc **2 phần** (JWT chuẩn có 3):

```txt
base64url(JSON payload) . HMAC-SHA256(payload, API_TOKEN_SECRET)
```

Payload thật khi decode:

```json
{
  "sub": "33b56a07-13c1-4e12-acd9-28f10e7762cb",
  "email": "demo@studyflutter.com",
  "issuedAt": "2026-08-17T03:13:54.687Z"
}
```

> 🔴 **Không có field `exp`** — token sống vĩnh viễn, không thu hồi được. Xem [06-van-de-ton-dong.md](06-van-de-ton-dong.md).

`AuthGuard` verify bằng cách **ký lại** payload rồi so chữ ký, sau đó **truy vấn DB** lấy user
(không tin dữ liệu trong token) → user bị xóa thì token cũ vô hiệu ngay.

### Helmet — 12 security header

Đã kiểm chứng bằng `curl -i`:

```txt
Content-Security-Policy, Cross-Origin-Opener-Policy, Cross-Origin-Resource-Policy,
Origin-Agent-Cluster, Referrer-Policy, Strict-Transport-Security,
X-Content-Type-Options, X-DNS-Prefetch-Control, X-Download-Options,
X-Frame-Options, X-Permitted-Cross-Domain-Policies, X-XSS-Protection
```

Đồng thời **gỡ** `X-Powered-By: Express` để không lộ tech stack.

### CORS

Đọc `CORS_ORIGIN` từ `.env`, tách bằng dấu phẩy.
Để rỗng → `origin: true` = **phản chiếu origin của client** (không phải `*`).

### Rate limit

`ThrottlerGuard` đăng ký global. Mặc định 60 request / 60 giây / IP.
Trả kèm header `X-RateLimit-Limit`, `X-RateLimit-Remaining`, `X-RateLimit-Reset`.
Vượt ngưỡng → **429**.

---

## 4. Lớp Cross-Cutting

Thư mục: `src/common/`

| Thành phần | File | Việc làm |
|---|---|---|
| `TransformResponseInterceptor` | `interceptors/` | Bọc mọi response thành công |
| `LoggingInterceptor` | `interceptors/` | Log `METHOD URL STATUS - Xms` |
| `HttpExceptionFilter` | `filters/` | Chuẩn hóa mọi lỗi |
| `CryptoService` | `common/` | Hash password, ký/verify token |
| `AuthenticatedRequest` | `common/` | Type `Request & { user: PublicUser }` |

### Format response thống nhất

Thành công:

```json
{
  "success": true,
  "statusCode": 201,
  "data": { "...": "dữ liệu thật" },
  "timestamp": "2026-08-17T03:14:13.717Z"
}
```

Thất bại:

```json
{
  "success": false,
  "statusCode": 403,
  "message": "Bạn không có quyền sửa bài viết này",
  "error": "Forbidden",
  "timestamp": "2026-08-17T03:14:27.935Z"
}
```

> ⚠️ `message` có thể là **string** (lỗi từ service) hoặc **array** (lỗi từ ValidationPipe).
> Flutter phải xử lý cả hai kiểu.

---

## 5. Database

Thư mục: `src/database/`

- File JSON tại `backend/data/db.json` (đã gitignore).
- Load **một lần** vào RAM lúc boot, mọi thao tác đọc lấy từ RAM (`snapshot`).
- Mỗi lần `save()` → **ghi đè toàn bộ file**.
- Module gắn `@Global()` nên inject được ở mọi nơi mà không cần `imports`.

> 🔴 Không có lock/transaction. Hai request đồng thời có thể ghi đè mất dữ liệu của nhau.
> Xem [06-van-de-ton-dong.md](06-van-de-ton-dong.md).

---

## 6. Config & Vận Hành

### Biến môi trường (`env.validation.ts` — Joi)

| Biến | Mặc định | Ghi chú |
|---|---|---|
| `NODE_ENV` | `development` | `development` / `production` / `test` |
| `PORT` | `3000` | Joi tự ép string → number |
| `API_TOKEN_SECRET` | — | min 16 ký tự, **bắt buộc khi production** |
| `CORS_ORIGIN` | rỗng | comma-separated, rỗng = cho phép mọi origin |
| `THROTTLE_TTL_MS` | `60000` | cửa sổ rate limit |
| `THROTTLE_LIMIT` | `60` | số request tối đa trong cửa sổ |

Thiếu `API_TOKEN_SECRET` khi `NODE_ENV=production` → **app crash lúc boot**, chưa mở port.
Đây là hành vi cố ý (fail fast).

### Health check

```txt
GET /api/health
→ { "status": "ok", "uptime": 123.45, "timestamp": "..." }
```

### Khác

- Global prefix `/api` — mọi route đều có tiền tố này.
- `enableShutdownHooks()` — bắt SIGTERM/SIGINT để graceful shutdown.
