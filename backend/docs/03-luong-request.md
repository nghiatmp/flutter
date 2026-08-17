# Luồng Một Request Đi Qua Backend

Toàn bộ số liệu dưới đây là **kết quả chạy thật** (server chạy local, bắn `curl`, đọc log server).

Request mẫu: `POST /api/posts` — đi qua nhiều cửa nhất (auth + validate + ghi DB).

```http
POST /api/posts HTTP/1.1
Host: localhost:3000
Content-Type: application/json
Authorization: Bearer eyJzdWIiOiIzM2I1NmEwNy0xM2MxLTRlMTItYWNkOS0yOGYxMGU3NzYyY2IiLCJlbWFpbCI6...

{"title":"Bài viết test luồng","body":"Nội dung để trace request","imagePath":null}
```

---

## Sơ Đồ Tổng Quát

```txt
POST /api/posts
   │
   ├─ helmet()                   main.ts       → 12 security headers
   ├─ cors()                     main.ts       → ACAO: <origin>, Vary, Credentials
   ├─ Router match               main.ts       → /api prefix → PostsController.create
   │
   ├─ ThrottlerGuard             app.module    → X-RateLimit-* ........ quá hạn → 429 ✗
   ├─ AuthGuard                  posts.ctrl    → verify HMAC, nạp req.user  sai → 401 ✗
   │                                             ⚠️ hai cửa này chặn thì KHÔNG CÓ LOG
   ├─ LoggingInterceptor  (vào)  app.module    → start = Date.now()
   ├─ TransformInterceptor(vào)  app.module    → giữ ref response
   │
   ├─ ValidationPipe             main.ts       → whitelist/forbid/transform  sai → 400 ✗
   │
   ├─ PostsController.create     posts.ctrl    → rút req.user.id
   ├─ PostsService.create        posts.svc     → trim, uuid, dựng PostRecord
   ├─ DatabaseService.save       db.svc        → ghi đè toàn bộ db.json
   │
   ├─ TransformInterceptor(ra)                 → bọc {success, statusCode, data, timestamp}
   ├─ LoggingInterceptor  (ra)                 → "POST /api/posts 201 - 1ms"
   │
   └─ HTTP 201 Created + JSON

   ✗ bất kỳ nhánh nào ném exception ──→ HttpExceptionFilter
                                        → {success:false, statusCode, message, error, timestamp}
```

---

## Chặng 1 — Express Middleware (ngoài NestJS)

### 1.1 `helmet()`

Chạy **đầu tiên**, trước cả routing. Gắn header rồi `next()`. 12 header thật đo được:

```http
Content-Security-Policy: default-src 'self';base-uri 'self';...
Cross-Origin-Opener-Policy: same-origin
Cross-Origin-Resource-Policy: same-origin
Origin-Agent-Cluster: ?1
Referrer-Policy: no-referrer
Strict-Transport-Security: max-age=31536000; includeSubDomains
X-Content-Type-Options: nosniff
X-DNS-Prefetch-Control: off
X-Download-Options: noopen
X-Frame-Options: SAMEORIGIN
X-Permitted-Cross-Domain-Policies: none
X-XSS-Protection: 0
```

Không hề có `X-Powered-By: Express` — helmet đã gỡ.

### 1.2 `cors()`

`.env` để `CORS_ORIGIN=` rỗng → `origin: true`. Gửi kèm `Origin: http://localhost:8080` nhận về:

```http
Access-Control-Allow-Origin: http://localhost:8080    ← phản chiếu ĐÚNG origin đã gửi
Vary: Origin
Access-Control-Allow-Credentials: true
```

Bằng chứng: `origin: true` **không trả `*`** mà **echo lại** origin của client.
Nghĩa là hiện tại mọi website đều gọi được API kèm credentials.

### 1.3 Router matching

`setGlobalPrefix("api")` khiến bảng route lúc boot được đăng ký (log thật):

```txt
[RoutesResolver]  PostsController {/api/posts}:
[RouterExplorer]  Mapped {/api/posts, POST} route
```

Express match `POST /api/posts` → tìm thấy `PostsController.create`.
Từ đây mới bước vào thế giới NestJS.

---

## Chặng 2 — Guards

> ⚠️ **Điều quan trọng nhất cần nhớ**: Guard chạy **trước** Interceptor và **trước** Pipe.

### 2.1 `ThrottlerGuard` (global)

Đếm request theo IP trong cửa sổ 60 giây, ghi 3 header:

```http
X-RateLimit-Limit: 60
X-RateLimit-Remaining: 59
X-RateLimit-Reset: 60
```

Vượt ngưỡng → `ThrottlerException` (429), request chết tại đây.

### 2.2 `AuthGuard` (route-level, qua `@UseGuards`)

Ba bước:

**a) Bóc token**

```ts
if (!authorization?.startsWith("Bearer ")) return null;
return authorization.slice("Bearer ".length).trim();
```

**b) Verify chữ ký** — `crypto.verifyToken()`

Token có cấu trúc **2 phần** `payload.signature` (JWT chuẩn có 3 — token này không có header segment).
Giải mã phần đầu ra được:

```json
{
  "sub": "33b56a07-13c1-4e12-acd9-28f10e7762cb",
  "email": "demo@studyflutter.com",
  "issuedAt": "2026-08-17T03:13:54.687Z"
}
```

Cơ chế: **ký lại** payload bằng HMAC-SHA256 + `API_TOKEN_SECRET`, so với chữ ký gửi lên.
Khớp → parse payload; không khớp → `null`.

> 🔴 Payload **không có field `exp`** → token sống vĩnh viễn.

**c) Nạp user vào request**

```ts
const user = payload?.sub ? this.authService.findPublicUserById(payload.sub) : null;
if (!user) throw new UnauthorizedException("Bạn cần đăng nhập");
request.user = user;   // ← từ giờ controller đọc được request.user
```

Guard **truy vấn DB lại** chứ không tin dữ liệu trong token → user bị xóa thì token cũ vô hiệu ngay.

---

## Chặng 3 — Interceptors (lượt đi)

Đăng ký trong `app.module.ts` theo thứ tự → `LoggingInterceptor` nằm **ngoài cùng**:

```txt
LoggingInterceptor  ⟶  TransformResponseInterceptor  ⟶  handler
```

- `LoggingInterceptor` bấm giờ `const start = Date.now()` rồi nhường tiếp.
- `TransformResponseInterceptor` lấy tham chiếu `response` rồi chờ — việc thật nằm ở lượt về.

### 🔑 Hệ quả then chốt của thứ tự Guard → Interceptor

Bắn **8 request** nhưng log server chỉ có **6 dòng**:

```txt
POST   /api/auth/login              201 - 39ms
POST   /api/auth/login              201 - 42ms
POST   /api/posts                   201 - 1ms
POST   /api/posts                   400 - 0ms
PATCH  /api/posts/demo-post-1       403 - 1ms
GET    /api/posts/khong-co-that     404 - 0ms
```

**Hai request bị 401 biến mất hoàn toàn.** Vì `AuthGuard` ném exception **trước khi**
`LoggingInterceptor` kịp chạy → `tap()` không bao giờ được đăng ký → không có gì để log.

> 🔴 **Lỗ hổng quan sát**: không thể phát hiện ai đang brute-force token qua log của app.
> Muốn log cả 401 phải chuyển việc log xuống middleware (chạy trước guard),
> hoặc log thêm trong `HttpExceptionFilter`.

---

## Chặng 4 — `ValidationPipe`

Đến đây body mới được kiểm tra. Pipe đọc kiểu `CreatePostBody` từ chữ ký controller,
so với decorator trong `posts.types.ts`.

Body hợp lệ → biến JSON thô thành **instance của `CreatePostBody`** (nhờ `transform: true`), cho đi tiếp.

Chi tiết cơ chế + ví dụ lỗi: [02-bootstrap-main-ts.md](02-bootstrap-main-ts.md#validationpipe--phần-quan-trọng-nhất).

---

## Chặng 5 — Controller → Service

### 5.1 Controller — cực mỏng

```ts
create(@Req() request: AuthenticatedRequest, @Body() body: CreatePostBody) {
  return this.postsService.create(request.user.id, body);
}
```

Chỉ rút `request.user.id` (do `AuthGuard` gắn ở chặng 2) và chuyển tiếp.
**Không có logic nghiệp vụ** — đây là kiểu viết đúng chuẩn NestJS.

`AuthenticatedRequest` chỉ là `Request & { user: PublicUser }` để TypeScript biết `request.user` tồn tại.

### 5.2 Service

```ts
const title = body.title?.trim();
const content = body.body?.trim();
if (!title)   throw new BadRequestException("Tiêu đề là bắt buộc");
if (!content) throw new BadRequestException("Nội dung là bắt buộc");
```

Đây là **lớp validate thứ hai**, trùng lặp một phần với `ValidationPipe`.
Nhưng nó bắt được ca mà pipe bỏ sót: `{"title": "   "}` — pipe thấy `@MinLength(1)` pass (3 ký tự),
service `.trim()` xong thành rỗng → chặn. **Sự trùng lặp này có lý do chính đáng.**

```ts
const post: PostRecord = {
  id: randomUUID(),
  userId,                          // ← từ TOKEN, không từ body
  title, body: content,
  imagePath: body.imagePath ?? null,
  createdAt: now, updatedAt: now,
};
```

`userId` lấy từ token → client không thể mạo danh người khác.

### 5.3 Ghi DB

```ts
const data = this.database.snapshot;              // đọc RAM
await this.database.save({
  ...data,
  posts: [post, ...data.posts],                   // post mới lên đầu
});
```

`save()` thực hiện:

```ts
this.data = nextData;                                              // cập nhật RAM
await mkdir(dirname(this.dbPath), { recursive: true });
await writeFile(this.dbPath, JSON.stringify(this.data, null, 2));  // GHI ĐÈ CẢ FILE
```

> 🔴 **Điểm nghẽn và rủi ro lớn nhất của luồng.** Mỗi lần tạo 1 post, toàn bộ `db.json`
> (cả users lẫn posts) bị serialize và ghi lại từ đầu. Hai request đồng thời: cả hai cùng đọc
> `snapshot` cũ, cùng thêm post vào bản sao riêng, rồi lần lượt ghi đè →
> **post của request ghi trước bị mất**. Không có lock, không có transaction.

---

## Chặng 6 — Interceptors (lượt về, thứ tự NGƯỢC)

```txt
handler  ⟶  TransformResponseInterceptor  ⟶  LoggingInterceptor  ⟶  client
```

### 6.1 `TransformResponseInterceptor`

Nhận `PostRecord` trần từ service, bọc vào phong bì:

```ts
map((data) => ({
  success: true,
  statusCode: response.statusCode,
  data,
  timestamp: new Date().toISOString(),
}))
```

Response thật:

```json
{
  "success": true,
  "statusCode": 201,
  "data": {
    "id": "d56ead91-4926-446d-9d04-d228f4bd5104",
    "userId": "33b56a07-13c1-4e12-acd9-28f10e7762cb",
    "title": "Bài viết test luồng",
    "body": "Nội dung để trace request",
    "imagePath": null,
    "createdAt": "2026-08-17T03:14:13.717Z",
    "updatedAt": "2026-08-17T03:14:13.717Z"
  },
  "timestamp": "2026-08-17T03:14:13.717Z"
}
```

HTTP status line là `HTTP/1.1 201 Created` — khớp với `statusCode` trong body.
(`201` là mặc định của NestJS cho `@Post()`, **không phải `200`**.)

### 6.2 `LoggingInterceptor`

Nằm ngoài cùng nên chạy **cuối cùng**, đo trọn vẹn thời gian cả chuỗi bên trong:

```txt
POST /api/posts 201 - 1ms
```

---

## Bảng Đối Chiếu 6 Nhánh Lỗi (kết quả thật)

| # | Tình huống | Chặn ở | HTTP | `message` | Có log? |
|---|---|---|---|---|---|
| A | Hợp lệ | — | 201 | — | ✅ |
| B | Không gửi token | AuthGuard | 401 | `"Bạn cần đăng nhập"` | ❌ |
| C | Token bị sửa 1 ký tự | AuthGuard | 401 | `"Bạn cần đăng nhập"` | ❌ |
| D | Thiếu `title` + thừa field | ValidationPipe | 400 | **mảng 4 phần tử** | ✅ |
| E | Sửa post người khác | PostsService | 403 | `"Bạn không có quyền sửa bài viết này"` | ✅ |
| F | Post không tồn tại | PostsService | 404 | `"Không tìm thấy bài viết"` | ✅ |

Cả 6 response đều có chung 4 field `success` / `statusCode` / `message` / `timestamp`
→ client Flutter chỉ cần **một hàm parse duy nhất**.

---

## Ba Điều Rút Ra Từ Việc Chạy Thật

1. **Guard chạy trước Interceptor** không chỉ là lý thuyết — nó khiến mọi request 401
   vô hình trong log. Cần audit truy cập trái phép thì phải bổ sung log ở tầng khác.

2. **`message` không nhất quán kiểu dữ liệu**: `string` với lỗi từ service,
   `string[]` với lỗi từ `ValidationPipe`. Flutter nên chuẩn hóa:

   ```dart
   final msg = raw is List ? raw.join('\n') : raw.toString();
   ```

3. **Ghi DB là điểm yếu nhất**: `writeFile` toàn bộ file mỗi thao tác, không lock.
   Với app học tập thì ổn, nhưng hai người cùng đăng bài là mất dữ liệu.
   Đây là chỗ đầu tiên cần thay khi muốn dùng thật.

---

## Cách Tự Kiểm Chứng Lại

```bash
# Terminal 1
cd backend && npm run start

# Terminal 2 — lấy token
TOKEN=$(curl -s -X POST http://localhost:3000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"demo@studyflutter.com","password":"123456"}' \
  | python3 -c "import sys,json;print(json.load(sys.stdin)['data']['accessToken'])")

# Xem đầy đủ header
curl -i -X POST http://localhost:3000/api/posts \
  -H "Content-Type: application/json" -H "Authorization: Bearer $TOKEN" \
  -d '{"title":"Test","body":"Nội dung"}'

# Giải mã payload token
echo "$TOKEN" | cut -d. -f1 | python3 -c \
  "import sys,base64,json;s=sys.stdin.read().strip();s+='='*(-len(s)%4);\
   print(json.dumps(json.loads(base64.urlsafe_b64decode(s)),indent=2,ensure_ascii=False))"

# Thử các nhánh lỗi
curl -X POST http://localhost:3000/api/posts -H "Content-Type: application/json" \
  -d '{"title":"x","body":"y"}'                                    # 401
curl -X PATCH http://localhost:3000/api/posts/demo-post-1 \
  -H "Content-Type: application/json" -H "Authorization: Bearer $TOKEN" \
  -d '{"title":"chiếm bài"}'                                       # 403
curl http://localhost:3000/api/posts/khong-co-that                 # 404
```

> ⚠️ Các lệnh trên **ghi vào `backend/data/db.json`**. Nhớ backup trước nếu không muốn bẩn dữ liệu:
> `cp data/db.json /tmp/db.bak` rồi khôi phục sau.
