# Luồng Khởi Động — `main.ts`

File nguồn: [`../src/main.ts`](../src/main.ts) — chỉ 35 dòng nhưng quyết định toàn bộ hành vi runtime.

Ý chính cần nắm: `main.ts` chạy **đúng một lần** để *cấu hình*, cấu hình đó chi phối **mọi request** về sau.

```txt
┌─ BOOT PHASE (1 lần) ─────────────────────┐
│  bootstrap()                             │
│  dựng DI container, đọc .env, seed DB,   │
│  gắn middleware/pipe/CORS                │
└──────────────────────────────────────────┘
                ↓ app.listen()
┌─ REQUEST PHASE (lặp mãi) ────────────────┐
│  helmet → cors → guard → pipe →          │
│  controller → interceptor → response     │
└──────────────────────────────────────────┘
```

---

## `void bootstrap()` — điểm bắt đầu

```ts
void bootstrap();
```

Dòng 7–35 chỉ là *định nghĩa hàm*. Dòng cuối mới là lệnh gọi.

`void` không thừa: `bootstrap()` là `async` nên trả `Promise`. Không `await` ở top-level sẽ bị
ESLint cảnh báo *floating promise*. `void` = **"tôi cố ý bỏ qua Promise này"**.

Hệ quả: boot lỗi → Promise reject không ai bắt → Node in `UnhandledPromiseRejection` và thoát.
Với server thì đúng — boot fail phải chết ngay.

---

## `NestFactory.create(AppModule)` — 90% công việc

Một dòng, bên trong xảy ra 5 bước **theo đúng thứ tự**:

### Bước 1 — Quét metadata

`reflect-metadata` đọc decorator `@Module({...})` của `AppModule`, đệ quy sang từng module trong `imports`.

### Bước 2 — Load & validate `.env`

`ConfigModule.forRoot({ validationSchema })` đọc `.env`, ném qua Joi.

> 🔴 **Cửa tử đầu tiên.** `NODE_ENV=production` mà thiếu `API_TOKEN_SECRET` → **crash tại đây**,
> chưa mở port. Thà chết lúc deploy còn hơn chạy với secret mặc định `"study-flutter-dev-secret"`.

Joi cũng **ép kiểu**: `PORT=3000` trong `.env` là string, sau validate thành number thật.

### Bước 3 — Dựng DI graph

Nest đọc constructor từng provider để biết ai cần ai, khởi tạo theo thứ tự phụ thuộc.
Ví dụ `AuthService` cần `DatabaseService` + `CryptoService` → hai thằng kia tạo trước.
Tất cả đều **singleton**.

### Bước 4 — Chạy `onModuleInit()`

| Thứ tự | Hook | Việc làm |
|---|---|---|
| 1 | `DatabaseService.onModuleInit()` | Đọc `data/db.json` vào RAM, seed 3 post demo nếu rỗng |
| 2 | `AuthService.onModuleInit()` | Seed user `demo@studyflutter.com` nếu chưa có |

**Vì sao đúng thứ tự?** Trong `app.module.ts`, `DatabaseModule` được import **trước** `AuthModule`.
Nest chạy hook theo thứ tự khởi tạo module.

> ⚠️ **Nếu đảo thứ tự import**, `AuthService` sẽ ghi user demo vào snapshot rỗng rồi bị `load()` ghi đè mất.

### Bước 5 — Tạo Express instance

Trả về object `app` kiểu `INestApplication`.

> Kết thúc bước này: mọi thứ sẵn sàng **nhưng chưa lắng nghe port nào**. Gọi API lúc này = `ECONNREFUSED`.

---

## `app.get(ConfigService)` — lấy đồ khỏi container

```ts
const config = app.get(ConfigService);
const logger = new Logger("Bootstrap");
```

Trong controller/service ta inject qua constructor. Nhưng `bootstrap()` là hàm thường **nằm ngoài DI**
→ phải "thò tay vào container" lấy ra bằng `app.get()`.

`new Logger("Bootstrap")` — chuỗi truyền vào là **context**, chính là phần trong ngoặc vuông khi in log:

```txt
[Nest] 40019  - 08/17/2026, 10:13:38 AM   LOG [Bootstrap] Study Flutter API is running...
                                               ↑ đây
```

Cùng cơ chế với `new Logger("HTTP")` và `new Logger("ExceptionFilter")`.

---

## `app.use(helmet())`

Middleware Express thuần, chạy **sớm nhất**, trước cả Guard. Chỉ gắn header rồi `next()`.

| Header | Chống |
|---|---|
| `X-Content-Type-Options: nosniff` | Trình duyệt đoán sai MIME type |
| `X-Frame-Options: SAMEORIGIN` | Clickjacking |
| `Strict-Transport-Security` | Downgrade HTTPS → HTTP |
| `Content-Security-Policy` | XSS, load script từ domain lạ |
| *(gỡ)* `X-Powered-By` | Lộ tech stack cho kẻ scan |

Với API JSON phục vụ Flutter native thì ít tác dụng thực tế (không có trình duyệt render HTML),
nhưng là **defense in depth** — miễn phí thì bật.

---

## `app.enableShutdownHooks()`

Lắng nghe `SIGTERM` (Docker/K8s dừng container) và `SIGINT` (Ctrl+C).
Khi nhận tín hiệu, Nest gọi `onModuleDestroy()` → `beforeApplicationShutdown()` →
`onApplicationShutdown()` trên mọi provider **trước khi** process thoát.

Hiện chưa provider nào implement các hook đó nên chưa có tác dụng, nhưng sẽ rất quan trọng
khi thay `DatabaseService` bằng PostgreSQL — lúc đó cần đóng connection pool sạch sẽ.

---

## CORS

```ts
const corsOrigin = config.get<string>("CORS_ORIGIN");
app.enableCors({
  origin: corsOrigin ? corsOrigin.split(",").map((o) => o.trim()) : true,
  credentials: true,
});
```

`.trim()` để `"http://a.com, http://b.com"` không bị dính khoảng trắng.

| `.env` | `origin` | Ý nghĩa |
|---|---|---|
| `CORS_ORIGIN=https://app.com,https://admin.app.com` | mảng 2 phần tử | Whitelist |
| `CORS_ORIGIN=` *(rỗng)* | `true` | Cho phép **mọi** origin |

### `origin: true` không phải là `*`

Nó **phản chiếu (reflect)** origin của request vào response. Kiểm chứng thật —
gửi kèm `Origin: http://localhost:8080` nhận về:

```txt
Access-Control-Allow-Origin: http://localhost:8080
Vary: Origin
Access-Control-Allow-Credentials: true
```

Chi tiết này quan trọng: theo spec CORS, `*` **không được** dùng chung với `credentials: true`,
còn reflect thì hợp lệ.

> 🔴 Deploy production mà quên set `CORS_ORIGIN` → **bất kỳ website nào** cũng gọi được API kèm cookie.
> Joi khai `CORS_ORIGIN` là `.optional()`, không bắt buộc kể cả production (khác `API_TOKEN_SECRET`).

> 💡 App Flutter **native** không bị CORS chi phối — CORS là cơ chế của trình duyệt.
> Config này chỉ có tác dụng với Flutter Web hoặc khi test bằng browser.

---

## `setGlobalPrefix("api")`

Thêm `/api` vào đầu mọi route:

```txt
@Controller("auth")   → /api/auth/*
@Controller("posts")  → /api/posts/*
@Controller("health") → /api/health
```

Lợi ích: tách namespace API với static file, dễ cấu hình reverse proxy
(nginx route `/api` → Node, `/` → web build).

---

## `ValidationPipe` — phần quan trọng nhất

```ts
app.useGlobalPipes(
  new ValidationPipe({
    whitelist: true,
    forbidNonWhitelisted: true,
    transform: true,
  }),
);
```

Pipe chạy **sau Guard, trước Controller**. Kiểm tra và biến đổi `@Body()`, `@Param()`, `@Query()`.

### Cơ chế

Pipe nhìn **kiểu TypeScript của tham số** trong controller:

```ts
register(@Body() body: RegisterBody) { ... }
//                       ↑ Nest đọc được kiểu này lúc runtime
```

Nhờ `emitDecoratorMetadata: true` trong `tsconfig.json`, TypeScript nhúng thông tin kiểu vào code compiled.
Pipe lấy class `RegisterBody`, quét decorator `@IsEmail()`, `@MinLength(6)`... rồi validate.

> ⚠️ **BẪY KINH ĐIỂN**: DTO phải là **`class`**, không được là `type`/`interface`.
> `interface` bị xóa sạch khi compile → runtime không còn gì để pipe đọc →
> **validate bị bỏ qua âm thầm**, không báo lỗi.

### Ba option

**`whitelist: true`** — tự động **xóa** field không có decorator validation trong DTO.
Chống **mass assignment** (kẻ tấn công nhét field lạ để leo thang đặc quyền).

**`forbidNonWhitelisted: true`** — nâng cấp từ "xóa im lặng" thành **ném lỗi 400**.
Nghiêm khắc hơn nhưng tốt cho môi trường học: khi Flutter gửi sai tên field
(`full_name` thay vì `fullName`), bạn biết ngay thay vì bị nuốt lỗi.

**`transform: true`** — hai việc:

1. Biến plain object thành **instance thật** của DTO class (qua `class-transformer`).
2. **Ép kiểu ngầm** cho param/query. URL luôn là string nên `@Param("id") id: number`
   sẽ convert `"42"` → `42`. *(Project này `id` là string UUID nên chưa dùng tới.)*

### Ví dụ lỗi thật

Gửi body vừa thiếu vừa thừa:

```json
{"body":"chỉ có body","userId":"hack-thanh-admin","isAdmin":true}
```

Nhận về:

```json
{
  "success": false,
  "statusCode": 400,
  "message": [
    "property userId should not exist",
    "property isAdmin should not exist",
    "title must be longer than or equal to 1 characters",
    "title must be a string"
  ],
  "error": "Bad Request",
  "timestamp": "2026-08-17T03:14:27.917Z"
}
```

Ba điều rút ra:

1. **Gom hết lỗi một lượt**, không dừng ở lỗi đầu → client sửa một lần là xong.
2. `forbidNonWhitelisted` chặn được `userId`/`isAdmin` — đúng mục đích chống mass assignment.
3. `message` là **ARRAY** — khác lỗi thủ công trong service (string).

### Chi tiết về cách đăng ký

`useGlobalPipes(new ValidationPipe(...))` tạo instance **bên ngoài DI container**
→ pipe này **không inject được dependency**.

Nếu sau này cần pipe tùy biến dùng `ConfigService`, phải đăng ký kiểu
`{ provide: APP_PIPE, useClass: ... }` trong `app.module.ts` — giống cách đã làm với
`APP_GUARD` / `APP_FILTER` / `APP_INTERCEPTOR`.
Ở đây `ValidationPipe` không cần gì nên viết vậy là ổn.

---

## `app.listen(port)`

```ts
const port = config.get<number>("PORT") ?? 3000;
await app.listen(port);
logger.log(`Study Flutter API is running at http://localhost:${port}/api`);
```

`?? 3000` thực ra **thừa** — Joi đã có `.default(3000)`. Giữ lại coi như phòng thủ.

`await app.listen(port)` là **ranh giới**: trước dòng này server câm lặng, sau dòng này bắt đầu
nhận TCP connection. `await` đảm bảo log chỉ in **sau khi** bind port thành công —
port bị chiếm (`EADDRINUSE`) thì Promise reject, log không bao giờ chạy.

---

## Đối Chiếu: Cấu Hình Ở Đây → Chặng Nào Lúc Runtime

| Dòng trong `main.ts` | Chạy ở chặng nào mỗi request |
|---|---|
| `app.use(helmet())` | 1. Middleware (sớm nhất) |
| `app.enableCors()` | 2. Middleware |
| `app.setGlobalPrefix("api")` | 3. Router matching |
| *(app.module: `APP_GUARD`)* | 4. Guards |
| *(app.module: `APP_INTERCEPTOR`)* | 5. Interceptors (lượt đi) |
| `app.useGlobalPipes(ValidationPipe)` | 6. Pipes |
| — | 7. Controller → Service |
| *(app.module: `APP_INTERCEPTOR`)* | 8. Interceptors (lượt về, ngược thứ tự) |
| *(app.module: `APP_FILTER`)* | ✗ Bất kỳ chặng nào ném lỗi |

Chi tiết từng chặng: [03-luong-request.md](03-luong-request.md).
