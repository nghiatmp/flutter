# Exception Filter — Chuẩn Hóa Lỗi

File nguồn: [`../src/common/filters/http-exception.filter.ts`](../src/common/filters/http-exception.filter.ts)

Đây là **lưới an toàn cuối cùng** của API — mọi exception ném ra từ bất kỳ đâu đều rơi vào đây.

---

## Đăng Ký

Trong `app.module.ts`:

```ts
{ provide: APP_FILTER, useClass: HttpExceptionFilter }
```

Token `APP_FILTER` = đăng ký global filter **thông qua DI container**.

Khác với `app.useGlobalFilters(new HttpExceptionFilter())` ở `main.ts`, cách này cho phép filter
**inject dependency** (ConfigService, logger tùy biến...) nếu sau này cần. Đây là cách chuẩn của NestJS.

---

## `@Catch()` Rỗng — Điểm Quan Trọng Nhất

```ts
@Catch()          // ← không có tham số
```

| Cách viết | Bắt được gì |
|---|---|
| `@Catch(HttpException)` | Chỉ `HttpException` và lớp con |
| `@Catch(BadRequestException, NotFoundException)` | Chỉ 2 loại đó |
| **`@Catch()`** ← file này | **Bắt TẤT CẢ**, kể cả `TypeError`, `undefined is not a function`, lỗi đọc file |

> Tên class là `HttpExceptionFilter` nhưng thực chất nó là **catch-all filter**.
> Không exception nào lọt ra ngoài để Express trả trang lỗi HTML mặc định.

---

## `ArgumentsHost` — Lấy req/res Bằng Cách Nào

```ts
const ctx = host.switchToHttp();
const response = ctx.getResponse<Response>();
const request  = ctx.getRequest<Request>();
```

`ArgumentsHost` là lớp trừu tượng bọc context của request. NestJS chạy được trên
HTTP, WebSocket, gRPC, microservice — nên không đưa thẳng `req`/`res`.
Phải gọi `switchToHttp()` (hoặc `switchToWs()`, `switchToRpc()`) để "chuyển kênh".

Generic `<Response>` / `<Request>` là type Express, cho autocomplete `.status()`, `.json()`, `.method`, `.url`.

---

## Phân Nhánh: Lỗi Có Chủ Đích vs Ngoài Ý Muốn

```ts
const isHttpException = exception instanceof HttpException;
const status = isHttpException
  ? exception.getStatus()              // 400, 401, 403, 404, 409, 429...
  : HttpStatus.INTERNAL_SERVER_ERROR;  // 500
```

- **Có chủ đích**: `throw new BadRequestException("Tiêu đề là bắt buộc")` → status lấy từ exception.
- **Ngoài ý muốn**: bug code, `JSON.parse` fail, đọc file lỗi → ép về 500.

---

## Logging — Chỉ Log Lỗi Thật

```ts
if (!isHttpException) {
  this.logger.error(
    `${request.method} ${request.url} -> Unhandled exception`,
    exception instanceof Error ? exception.stack : String(exception),
  );
}
```

Thiết kế **cố ý**: user nhập sai mật khẩu (401) hay thiếu title (400) là chuyện bình thường,
log ra chỉ làm nhiễu. Chỉ lỗi **lập trình viên cần sửa** (500) mới log kèm full stack trace.

`exception instanceof Error ? .stack : String(...)` xử lý trường hợp ai đó `throw "chuỗi"`
hoặc `throw { code: 1 }` — không phải Error nên không có `.stack`.

---

## `buildBody()` — Ba Nhánh Tạo Response

### Nhánh A — lỗi 500 (`exception === null`)

```json
{
  "success": false,
  "statusCode": 500,
  "message": "Đã xảy ra lỗi, vui lòng thử lại sau",
  "timestamp": "2026-08-17T..."
}
```

**Không lộ stack trace / message gốc ra client** — điểm bảo mật tốt, vì message gốc có thể chứa
đường dẫn file server, câu query, tên biến nội bộ.

### Nhánh B — `getResponse()` trả về string

Xảy ra khi exception tạo bằng `new HttpException('...', 403)` thuần.
Ví dụ thực tế: `ThrottlerException` (429) trả về string `"ThrottlerException: Too Many Requests"`.

### Nhánh C — `getResponse()` trả về object

```ts
return { success: false, statusCode: status, ...payload, timestamp };
```

Nhánh chạy **thường xuyên nhất**. Các exception dựng sẵn của Nest
(`BadRequestException`, `UnauthorizedException`...) luôn build payload dạng object
`{ statusCode, message, error }`.

---

## Output Thực Tế (đã kiểm chứng bằng curl)

| Tình huống | Nguồn ném | Response body |
|---|---|---|
| Sai mật khẩu | `auth.service.ts` | `{success:false, statusCode:401, message:"Email hoặc mật khẩu không đúng", error:"Unauthorized", timestamp}` |
| Chưa đăng nhập | `auth.guard.ts` | `{success:false, statusCode:401, message:"Bạn cần đăng nhập", error:"Unauthorized", timestamp}` |
| Sửa post người khác | `posts.service.ts` | `{success:false, statusCode:403, message:"Bạn không có quyền sửa bài viết này", error:"Forbidden", timestamp}` |
| Post không tồn tại | `posts.service.ts` | `{success:false, statusCode:404, message:"Không tìm thấy bài viết", error:"Not Found", timestamp}` |
| Email trùng | `auth.service.ts` | `{success:false, statusCode:409, message:"Email đã được đăng ký", ...}` |
| **ValidationPipe chặn** | Nest core | `message` là **MẢNG**: `["property userId should not exist", "title must be a string", ...]` |
| Vượt rate limit | ThrottlerGuard | `{success:false, statusCode:429, message:"ThrottlerException: Too Many Requests", timestamp}` |
| Bug code | bất kỳ đâu | `{success:false, statusCode:500, message:"Đã xảy ra lỗi, vui lòng thử lại sau", timestamp}` |

> ⚠️ **`message` có thể là `string` HOẶC `string[]`** tùy nguồn lỗi. Phía Flutter phải xử lý cả hai:
>
> ```dart
> final msg = raw is List ? raw.join('\n') : raw.toString();
> ```

---

## Quan Hệ Với `TransformResponseInterceptor`

Chỗ dễ nhầm nhất. Hai file này **song song, không lồng nhau**:

```txt
Request
  ↓
Guard (Throttler → Auth)  ─── throw ──┐
  ↓                                    │
ValidationPipe            ─── throw ──┤
  ↓                                    │
Controller → Service      ─── throw ──┤
  ↓ (thành công)                       │
TransformResponseInterceptor           │
  ↓                                    ↓
{success: true, data: ...}     HttpExceptionFilter
                                       ↓
                               {success: false, message: ...}
```

Khi có exception, **interceptor bị bỏ qua hoàn toàn** — response không đi qua `map()`
nên **không có field `data`**. Vì vậy filter phải **tự tay** thêm `success`, `statusCode`, `timestamp`
để hai loại response trông đồng nhất.

Đó là lý do cả hai file đều có `success` + `statusCode` + `timestamp`:
**giữ contract API nhất quán** — Flutter chỉ cần check `response['success']`.

> `LoggingInterceptor` thì **vẫn chạy** khi lỗi, vì dùng `tap({ next, error })` — nhánh `error` vẫn log được.
> **Ngoại lệ**: lỗi từ Guard (401/429) thì interceptor chưa kịp chạy → không có log.
> Xem [03-luong-request.md](03-luong-request.md#-hệ-quả-then-chốt-của-thứ-tự-guard--interceptor).

---

## Điểm Có Thể Cải Thiện

1. **Spread ghi đè**: `{ success: false, statusCode: status, ...payload, timestamp }` —
   `...payload` đứng sau nên `payload.statusCode` ghi đè giá trị vừa set.
   Hiện vô hại vì luôn bằng nhau, nhưng nếu payload tùy biến có `success: true` thì phá vỡ contract.
   An toàn hơn: đặt `...payload` lên đầu.

2. **Field `error` bị lộ ra client**: `"error": "Unauthorized"` là text tiếng Anh của Nest,
   trùng lặp với `message` tiếng Việt. Có thể strip cho gọn.

3. **Tên class không khớp hành vi**: `@Catch()` bắt tất cả nhưng tên là `HttpExceptionFilter`
   → đọc code dễ tưởng chỉ bắt `HttpException`.
   Đổi thành `AllExceptionsFilter` (tên quy ước trong docs NestJS) sẽ rõ nghĩa hơn.

4. **Không log 401/429**: cân nhắc log thêm ở đây để phát hiện brute-force.
