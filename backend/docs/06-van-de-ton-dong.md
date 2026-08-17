# Vấn Đề Tồn Đọng & Rủi Ro

Tổng hợp các điểm phát hiện được khi đọc code và chạy thử thật.
Với mục đích **học tập/demo local** thì tất cả đều chấp nhận được — danh sách này dành cho lúc
muốn đưa backend lên môi trường thật.

Xếp theo mức độ ưu tiên.

---

## 🔴 Nghiêm Trọng

### 1. Token không có hạn sử dụng

**Hiện trạng** — payload token khi decode:

```json
{
  "sub": "33b56a07-...",
  "email": "demo@studyflutter.com",
  "issuedAt": "2026-08-17T03:13:54.687Z"
}
```

Không có field `exp`. `CryptoService.verifyToken()` cũng không kiểm tra thời hạn.

**Hậu quả**: token lộ một lần là dùng được vĩnh viễn. Không có cách thu hồi
(trừ khi đổi `API_TOKEN_SECRET`, việc này vô hiệu hóa token của **tất cả** user).

**Hướng xử lý**:

```ts
// crypto.service.ts — thêm exp khi ký
signToken(payload, ttlMs = 7 * 24 * 60 * 60 * 1000) {
  const body = { ...payload, exp: Date.now() + ttlMs };
  ...
}

// verifyToken — kiểm tra trước khi trả về
if (typeof parsed.exp === "number" && Date.now() > parsed.exp) return null;
```

Cân nhắc thêm refresh token nếu muốn UX không bắt đăng nhập lại.

---

### 2. Ghi database không an toàn khi có đồng thời

**Hiện trạng** — `DatabaseService.save()`:

```ts
this.data = nextData;
await writeFile(this.dbPath, JSON.stringify(this.data, null, 2));   // ghi đè TOÀN BỘ file
```

Mọi service đều theo pattern: đọc `snapshot` → sửa bản sao → `save()`.

**Hậu quả** — hai request đồng thời:

```txt
Request A: đọc snapshot (10 posts)
Request B: đọc snapshot (10 posts)      ← cùng bản cũ
Request A: save(11 posts, có post A)
Request B: save(11 posts, có post B)    ← GHI ĐÈ, post A biến mất
```

Không có lock, không có transaction. Ngoài ra mỗi thao tác nhỏ đều serialize lại
**toàn bộ** file (cả users lẫn posts) → chậm dần theo kích thước dữ liệu.

**Hướng xử lý**: thay `DatabaseService` bằng SQLite (nhẹ, vẫn 1 file) hoặc PostgreSQL.
Interface hiện tại khá gọn nên thay không quá tốn công — đúng như `TECH_FLOW.md` đã gợi ý.

Nếu muốn giữ JSON tạm thời: thêm mutex đơn giản (hàng đợi Promise) quanh `save()`.

---

### 3. CORS mở toang khi thiếu cấu hình

**Hiện trạng**:

```ts
origin: corsOrigin ? corsOrigin.split(",")... : true,
credentials: true,
```

`CORS_ORIGIN` rỗng → `origin: true` → **phản chiếu origin của client**.
Kiểm chứng thật: gửi `Origin: http://localhost:8080` nhận về
`Access-Control-Allow-Origin: http://localhost:8080`.

Joi khai `CORS_ORIGIN` là `.optional()` — **không bắt buộc kể cả khi `NODE_ENV=production`**,
khác với `API_TOKEN_SECRET` đã được siết.

**Hậu quả**: deploy quên set biến → bất kỳ website nào cũng gọi được API kèm credentials.

**Hướng xử lý** — siết trong `env.validation.ts`:

```ts
CORS_ORIGIN: Joi.string().when("NODE_ENV", {
  is: "production",
  then: Joi.required(),        // bắt buộc khi production
  otherwise: Joi.string().allow("").optional(),
}),
```

---

### 4. `scryptSync` chặn event loop

**Hiện trạng** — `common/crypto.service.ts` dùng bản **Sync**:

```ts
const hash = scryptSync(password, salt, 64).toString("hex");   // hashPassword
const candidate = scryptSync(password, salt, 64);              // verifyPassword
```

**Đo thật** trên máy dev (8 core, Node v23.3.0):

```txt
scryptSync 1 lần            : 31.4 ms
setTimeout(0) thực tế nổ sau: 28.5 ms   ← lẽ ra ~0ms → event loop BỊ CHẶN
```

**Hậu quả**: Node chạy code JS trên **một luồng duy nhất**. Mỗi lần có người login hoặc
đăng ký, **toàn bộ server đứng hình 31ms** — không phải chỉ request đó chậm, mà *tất cả*
request khác (kể cả `GET /api/posts`) phải xếp hàng chờ.

Trần lý thuyết: `1000ms ÷ 31.4ms ≈ 32 login/giây` là giới hạn tuyệt đối của cả server.

Đây vừa là **trần throughput**, vừa là **vector khuếch đại DoS**: kẻ tấn công chỉ cần
bắn request login (dù sai mật khẩu) là chiếm được CPU của toàn bộ API.
Rate limit 60 req/phút/IP không chặn được nếu dùng nhiều IP.

> 💡 `scrypt` chậm là **cố ý** — đó là điểm mạnh của thuật toán hash mật khẩu
> (làm brute-force tốn kém). Vấn đề không phải nó chậm, mà là dùng bản **Sync**.

**Hướng xử lý** — chuyển sang bản async để đẩy việc xuống thread pool của libuv:

```ts
import { scrypt, timingSafeEqual, randomBytes } from "node:crypto";
import { promisify } from "node:util";

const scryptAsync = promisify(scrypt) as (
  pw: string, salt: string, len: number,
) => Promise<Buffer>;

async hashPassword(password: string): Promise<string> {
  const salt = randomBytes(16).toString("hex");
  const hash = (await scryptAsync(password, salt, 64)).toString("hex");
  return `${salt}:${hash}`;
}

async verifyPassword(password: string, storedHash: string): Promise<boolean> {
  const [salt, hash] = storedHash.split(":");
  if (!salt || !hash) return false;
  const candidate = await scryptAsync(password, salt, 64);
  const original = Buffer.from(hash, "hex");
  return candidate.length === original.length && timingSafeEqual(candidate, original);
}
```

Sau đó thêm `await` ở các chỗ gọi trong `auth.service.ts`
(`seedDefaultUser`, `register`, `login`, `changePassword`).

**Hiệu quả đo được** — 8 lần hash:

```txt
tuần tự (Sync)  : 212.2 ms
song song (async):  68.1 ms   → nhanh gấp 3.1x
```

**Bonus**: thread pool mặc định chỉ **4 luồng** dù máy có 8 core.
Thêm vào `.env` để tận dụng hết:

```txt
UV_THREADPOOL_SIZE=8
```

---

## 🟡 Trung Bình

### 5. Request 401 không xuất hiện trong log

**Hiện trạng** — bắn 8 request, log server chỉ có 6 dòng. Hai request bị 401 biến mất.

**Nguyên nhân**: `AuthGuard` chạy **trước** `LoggingInterceptor` (thứ tự cố định của NestJS:
Guard → Interceptor → Pipe). Guard ném exception thì interceptor chưa kịp đăng ký `tap()`.

**Hậu quả**: không phát hiện được brute-force token qua log ứng dụng.

**Hướng xử lý**: thêm log trong `HttpExceptionFilter` cho status 401/403/429, hoặc
chuyển việc log request xuống middleware (chạy trước guard).

---

### 6. Field `message` không nhất quán kiểu dữ liệu

**Hiện trạng**:

| Nguồn lỗi | Kiểu `message` | Ví dụ |
|---|---|---|
| Service ném thủ công | `string` | `"Không tìm thấy bài viết"` |
| `ValidationPipe` | `string[]` | `["title must be a string", "property isAdmin should not exist"]` |
| `ThrottlerException` | `string` | `"ThrottlerException: Too Many Requests"` |

**Hậu quả**: Flutter phải xử lý cả hai kiểu, dễ crash nếu quên.

**Hướng xử lý** — chuẩn hóa ngay trong `HttpExceptionFilter`:

```ts
const raw = (payload as any).message;
const message = Array.isArray(raw) ? raw.join("\n") : raw;
```

Hoặc xử lý ở phía Flutter:

```dart
final msg = raw is List ? raw.join('\n') : raw.toString();
```

---

### 7. Spread ghi đè trong `buildBody()`

```ts
return { success: false, statusCode: status, ...payload, timestamp };
//                       ^^^^^^^^^^^^^^^^^^  ^^^^^^^^^^ payload ghi đè cái này
```

Hiện vô hại (hai giá trị luôn bằng nhau), nhưng nếu có exception tùy biến với payload
chứa `success: true` thì contract API bị phá.

**Hướng xử lý**: đặt `...payload` lên **đầu**:

```ts
return { ...payload, success: false, statusCode: status, timestamp };
```

---

## 🟢 Nhỏ / Dọn Dẹp

### 8. Tên class không khớp hành vi

`HttpExceptionFilter` dùng `@Catch()` rỗng → bắt **tất cả** exception, không riêng `HttpException`.
Đọc code dễ hiểu nhầm.

→ Đổi tên thành `AllExceptionsFilter` (tên quy ước trong docs NestJS).

### 9. Field `error` tiếng Anh lộ ra client

Response có cả `message` tiếng Việt lẫn `error: "Unauthorized"` tiếng Anh của Nest — trùng lặp.

→ Strip `error` trong `buildBody()` nếu không dùng đến.

### 10. `?? 3000` thừa

```ts
const port = config.get<number>("PORT") ?? 3000;
```

Joi đã có `.default(3000)` nên không bao giờ `undefined`. Vô hại, giữ hay bỏ đều được.

### 11. Validate trùng lặp giữa Pipe và Service

`ValidationPipe` check `@MinLength(1)`, service lại check `!title` sau khi `.trim()`.

**Đây KHÔNG phải lỗi** — service bắt được ca pipe bỏ sót: `{"title": "   "}`
(pipe thấy 3 ký tự nên pass, service trim xong thành rỗng nên chặn).
Ghi lại ở đây để sau này đừng vội xóa vì tưởng thừa.

Nếu muốn gọn hơn: dùng `@Transform(({value}) => value?.trim())` trong DTO
rồi bỏ check ở service.

---

## Bảng Ưu Tiên

| # | Vấn đề | Mức | Sửa ở đâu |
|---|---|---|---|
| 1 | Token không hết hạn | 🔴 | `common/crypto.service.ts` |
| 2 | DB race condition | 🔴 | `database/database.service.ts` |
| 3 | CORS mở toang | 🔴 | `config/env.validation.ts` |
| 4 | `scryptSync` chặn event loop | 🔴 | `common/crypto.service.ts` + `auth.service.ts` |
| 5 | 401 không log | 🟡 | `common/filters/` hoặc middleware mới |
| 6 | `message` không nhất quán | 🟡 | `common/filters/http-exception.filter.ts` |
| 7 | Spread ghi đè | 🟡 | `common/filters/http-exception.filter.ts` |
| 8 | Tên class | 🟢 | `common/filters/` |
| 9 | Field `error` thừa | 🟢 | `common/filters/` |
| 10 | `?? 3000` thừa | 🟢 | `main.ts` |
| 11 | Validate trùng (không phải lỗi) | — | — |

> 💡 Vấn đề **1** và **4** cùng nằm ở `crypto.service.ts` — sửa một lượt sẽ tiện hơn.
> Cơ chế Node.js đằng sau vấn đề 4: xem [07-nodejs-va-nestjs.md](07-nodejs-va-nestjs.md#16--scryptsync-đang-chặn-event-loop).

---

## Những Điểm Code Đã Làm ĐÚNG

Ghi lại để không "sửa nhầm" khi refactor:

- ✅ `userId` lấy từ token, không lấy từ body → không mạo danh được.
- ✅ `PublicUser = Omit<UserRecord, "passwordHash">` → hash không bao giờ lọt ra response.
- ✅ `AuthGuard` truy vấn DB lại thay vì tin payload token → user bị xóa thì token vô hiệu ngay.
- ✅ Lỗi 500 không lộ stack trace ra client.
- ✅ Chỉ log lỗi 500, không log 4xx → log sạch, dễ đọc.
- ✅ `forbidNonWhitelisted` chặn mass assignment (đã kiểm chứng: `userId`, `isAdmin` bị từ chối).
- ✅ `timingSafeEqual` khi so password → chống timing attack.
- ✅ Dùng `scrypt` (không phải MD5/SHA1) làm thuật toán hash mật khẩu — chọn đúng,
  chỉ cần đổi sang bản async (vấn đề 4).
- ✅ `API_TOKEN_SECRET` bắt buộc khi production → fail fast lúc boot.
- ✅ `UpdateProfileBody` cố ý không có field `email` → không đổi email qua endpoint thường.
- ✅ Đổi mật khẩu bắt buộc nhập mật khẩu hiện tại.
- ✅ `DatabaseModule` khởi tạo trước `AuthModule` → seed user không bị ghi đè.
