# Node.js & NestJS — Cơ Chế Bên Dưới

Tài liệu này giải thích *vì sao* backend chạy được như vậy, không phải *nó làm gì*
(phần đó xem [01-tinh-nang-backend.md](01-tinh-nang-backend.md)).

Mọi số liệu đo trên máy dev: **8 CPU core, Node v23.3.0**.
Script để tự đo lại nằm ở cuối file.

---

# PHẦN 1 — NODE.JS

## 1.1 Node = V8 + libuv

```txt
┌─────────────────────────────────────────────┐
│  JavaScript code (main.ts, service...)      │
├─────────────────────────────────────────────┤
│  Node.js API  (fs, http, crypto, path...)   │
├──────────────────────┬──────────────────────┤
│   V8 (Google)        │   libuv (C)          │
│   chạy JS            │   event loop         │
│   JIT compile        │   thread pool        │
│   garbage collector  │   async I/O của OS   │
└──────────────────────┴──────────────────────┘
```

**V8** chỉ biết chạy JavaScript — không biết đọc file hay mở socket.
**libuv** là thư viện C lo phần đó, và nó chứa **event loop**.

## 1.2 Một luồng, nhưng không chậm

| Mô hình | Cách xử lý 1000 request đồng thời |
|---|---|
| Apache/PHP, Java servlet cổ điển | 1000 thread, mỗi thread ~1MB stack, OS context-switch liên tục |
| **Node.js** | 1 thread, đăng ký callback rồi đi làm việc khác |

Trong code project:

```ts
await writeFile(this.dbPath, JSON.stringify(this.data, null, 2));
```

Ở khoảnh khắc đợi ổ đĩa ghi xong, thread JS **rảnh hoàn toàn** — nó xử lý được
`GET /api/posts` của user khác. Đó là lý do Node phục vụ hàng chục nghìn kết nối
với vài chục MB RAM.

> Điều kiện để mô hình này hoạt động: **không được chặn event loop**.
> Xem mục 1.6 — code hiện tại đang vi phạm.

## 1.3 Sáu pha của event loop

```txt
   ┌──────────────────────────┐
┌─>│  timers                  │  setTimeout, setInterval đến hạn
│  ├──────────────────────────┤
│  │  pending callbacks       │  callback TCP error bị hoãn
│  ├──────────────────────────┤
│  │  idle, prepare           │  nội bộ libuv
│  ├──────────────────────────┤
│  │  poll                    │  ★ I/O callback — ở lâu nhất
│  ├──────────────────────────┤
│  │  check                   │  setImmediate
│  ├──────────────────────────┤
│  │  close callbacks         │  socket.on('close')
└──┴──────────────────────────┘
     ↕ giữa MỖI pha: vét sạch microtask queue
```

Kết quả đo thật:

```txt
0a. nextTick   : trước tất cả
0b. Promise    : sau nextTick, vẫn trước mọi pha
1. timers      : setTimeout(0)
3. check       : setImmediate
2. poll        : fs.readFile callback
4. nextTick    : chen ngay sau I/O callback
5. check       : setImmediate trong I/O  ← LUÔN trước setTimeout
6. timers      : setTimeout trong I/O
```

Hai chi tiết đáng nhớ:

- **Trong I/O callback, `setImmediate` luôn chạy trước `setTimeout(0)`** (dòng 5 trước 6).
  Điều này *được đảm bảo*. Ở main module thì thứ tự không xác định.
- **`nextTick` chen ngang giữa mọi pha** (dòng 4 nằm giữa poll và check).

## 1.4 Microtask: `nextTick` và `Promise`

Không phải một pha — là **hàng đợi được vét sạch giữa mỗi pha**:

```txt
process.nextTick  →  ưu tiên CAO NHẤT, vét trước
Promise.then      →  vét sau nextTick
```

> ⚠️ `process.nextTick` gọi đệ quy vô hạn sẽ **treo cứng event loop** — hàng đợi microtask
> phải vét *hết* trước khi sang pha tiếp theo, mà nó không bao giờ hết.

## 1.5 Thread pool — nơi việc nặng chạy

"Node là single-threaded" chỉ đúng với **code JS của bạn**. libuv có **thread pool 4 luồng**
cho những việc OS không hỗ trợ async:

```txt
fs.*                    đọc/ghi file
crypto.scrypt, pbkdf2   hash mật khẩu
zlib                    nén
dns.lookup              phân giải tên miền
```

Đo thật với `scrypt` (đúng hàm project đang dùng):

```txt
8x scryptSync (tuần tự)   : 212.2 ms
8x scrypt    (song song)  :  68.1 ms
→ nhanh gấp 3.1x nhờ thread pool
UV_THREADPOOL_SIZE = 4 (mặc định)
CPU cores = 8
```

Gấp **3.1x** chứ không phải 8x — vì pool chỉ có **4 luồng** dù máy có 8 core.
Tăng bằng biến môi trường `UV_THREADPOOL_SIZE=8`.

## 1.6 ⚠️ `scryptSync` đang chặn event loop

`common/crypto.service.ts` dùng bản **Sync**:

```ts
const hash = scryptSync(password, salt, 64).toString("hex");      // hashPassword
const candidate = scryptSync(password, salt, 64);                 // verifyPassword
```

Đo được:

```txt
scryptSync 1 lần            : 31.4 ms
setTimeout(0) thực tế nổ sau: 28.5 ms   ← lẽ ra ~0ms → event loop BỊ CHẶN
```

**Nghĩa là**: mỗi lần có người login/đăng ký, **toàn bộ server đứng hình 31ms**.
Không phải chỉ request đó chậm — *tất cả* request khác (kể cả `GET /api/posts`) phải xếp hàng.

Trần lý thuyết: `1000ms ÷ 31.4ms ≈ **32 login/giây**` là giới hạn tuyệt đối của cả server.

> 💡 `scrypt` chậm là **cố ý** — đó là điểm mạnh của thuật toán hash mật khẩu
> (làm brute-force tốn kém). Vấn đề không phải nó chậm, mà là dùng bản **Sync**.

Cách sửa: xem [06-van-de-ton-dong.md](06-van-de-ton-dong.md#4-scryptsync-chặn-event-loop).

---

# PHẦN 2 — NESTJS

## 2.1 NestJS KHÔNG thay thế Express

Hiểu lầm phổ biến nhất. NestJS là **lớp kiến trúc bọc lên trên** Express (hoặc Fastify):

```txt
   Flutter app
        ↓
┌───────────────────────────────┐
│  NestJS                       │  ← DI, module, guard, pipe, filter
│  ┌─────────────────────────┐  │
│  │  Express                │  │  ← routing, middleware, req/res
│  │  ┌───────────────────┐  │  │
│  │  │  Node http module │  │  │  ← TCP, HTTP parsing
│  │  └───────────────────┘  │  │
│  └─────────────────────────┘  │
└───────────────────────────────┘
```

Bằng chứng ngay trong project:

- `app.use(helmet())` ở `main.ts` là **middleware Express thuần**.
- `AuthenticatedRequest` extends `Request` **của Express**.

Đổi `@nestjs/platform-express` sang `@nestjs/platform-fastify` là chạy được với Fastify
mà code nghiệp vụ **không đổi một dòng**.

## 2.2 Decorator thực chất là gì?

Code TypeScript:

```ts
@Post()
@UseGuards(AuthGuard)
create(@Req() request: AuthenticatedRequest, @Body() body: CreatePostBody) {}
```

Sau compile (trích `dist/posts/posts.controller.js` thật):

```js
__decorate([
    (0, common_1.Post)(),
    (0, common_1.UseGuards)(auth_guard_1.AuthGuard),
    __param(0, (0, common_1.Req)()),
    __param(1, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, posts_types_1.CreatePostBody]),
    __metadata("design:returntype", void 0)
], PostsController.prototype, "create", null);
```

**Decorator chỉ là hàm thường**, được gọi lúc load module, nhận class/method làm tham số,
rồi **ghi metadata** lên đó. Không có phép màu nào.

## 2.3 `reflect-metadata` — kho chứa metadata

Dump kho metadata thật của project:

```txt
═══ Metadata mà @Module() lưu trên PostsModule ═══
  imports      = [ 'AuthModule' ]
  controllers  = [ 'PostsController' ]
  providers    = [ 'PostsService' ]
  exports      = []

═══ Metadata mà @Controller('posts') lưu ═══
  path         = posts

═══ Metadata trên method create() ═══
  path         = /
  method       = POST
  __guards__   = [ 'AuthGuard' ]

═══ Toàn bộ metadata key trên PostsController ═══
  [ 'design:paramtypes', '__controller__', 'path',
    'host', 'scope:options', '__version__' ]
```

Lúc `NestFactory.create()` chạy, nó **đọc đúng những dữ liệu này** rồi tự dựng bảng route,
danh sách guard, đồ thị phụ thuộc.

Toàn bộ `posts.module.ts` tồn tại chỉ để tạo ra 4 dòng metadata đầu tiên ở trên.

## 2.4 Trái tim của DI: `design:paramtypes`

```txt
AuthGuard cần      : [ 'AuthService', 'CryptoService' ]
PostsController cần: [ 'PostsService' ]
```

Bạn **chưa bao giờ khai báo** những dependency này ở đâu. Bạn chỉ viết:

```ts
constructor(
  private readonly authService: AuthService,
  private readonly crypto: CryptoService,
) {}
```

TypeScript với cờ `emitDecoratorMetadata: true` **tự động nhúng kiểu tham số constructor**
vào metadata `design:paramtypes`. NestJS đọc nó và biết phải tiêm gì.

> 🔑 **Đây là lý do NestJS chỉ hoạt động với TypeScript.**
> JavaScript thuần không có thông tin kiểu lúc runtime → không có `design:paramtypes`
> → DI tự động không hoạt động.
>
> Và là lý do DTO phải là **`class`** chứ không phải `interface` —
> `interface` bị xóa khi compile, không để lại metadata nào.

## 2.5 Kiểm tra lúc BOOT, không phải lúc chạy

Thí nghiệm: xóa `imports: [AuthModule]` khỏi `posts.module.ts` → app chết ngay lúc khởi động:

```txt
Nest can't resolve dependencies of the AuthGuard (?, CryptoService).
Please make sure that the argument AuthService at index [0] is
available in the PostsModule context.
```

So sánh với Express thuần: quên `require` một module, code vẫn chạy bình thường
cho tới khi có user gọi đúng endpoint đó lúc 2 giờ sáng
→ `TypeError: undefined is not a function` trên production.

NestJS **dựng toàn bộ đồ thị phụ thuộc trước khi mở port**.

## 2.6 AOP — tách bạch mối quan tâm chéo

| Enhancer | Câu hỏi nó trả lời | Trong project |
|---|---|---|
| **Guard** | *Có được vào không?* | `ThrottlerGuard`, `AuthGuard` |
| **Interceptor** | *Bọc thêm gì quanh handler?* | `LoggingInterceptor`, `TransformResponseInterceptor` |
| **Pipe** | *Dữ liệu vào có hợp lệ không?* | `ValidationPipe` |
| **Filter** | *Lỗi thì trả gì?* | `HttpExceptionFilter` |

Nhờ vậy `PostsController.create()` chỉ có **đúng 1 dòng nghiệp vụ**:

```ts
return this.postsService.create(request.user.id, body);
```

Không auth, không validate, không try/catch, không log, không format response.

Cùng chức năng đó viết bằng Express thuần:

```js
app.post('/api/posts', rateLimiter, async (req, res) => {
  try {
    const token = req.headers.authorization?.replace('Bearer ', '');
    if (!token) return res.status(401).json({ success: false, message: '...' });
    const payload = verifyToken(token);
    if (!payload) return res.status(401).json({ success: false, message: '...' });
    const user = findUser(payload.sub);
    if (!user) return res.status(401).json({ success: false, message: '...' });

    if (!req.body.title || typeof req.body.title !== 'string')
      return res.status(400).json({ success: false, message: '...' });
    if (!req.body.body || typeof req.body.body !== 'string')
      return res.status(400).json({ success: false, message: '...' });
    for (const k of Object.keys(req.body))
      if (!['title','body','imagePath'].includes(k))
        return res.status(400).json({ success:false, message:`property ${k} should not exist` });

    const post = await createPost(user.id, req.body);
    console.log(`POST /api/posts 201`);
    res.status(201).json({ success:true, statusCode:201, data:post, timestamp:new Date().toISOString() });
  } catch (e) {
    console.error(e);
    res.status(500).json({ success: false, message: '...' });
  }
});
```

Và **lặp lại y hệt** cho 4 endpoint còn lại.

## 2.7 Platform-agnostic: `ExecutionContext`

```ts
const ctx = host.switchToHttp();
```

Dòng này "thừa" một cách cố ý. NestJS thiết kế để cùng một `AuthGuard` chạy được trên
HTTP, WebSocket, gRPC, hay message queue — chỉ cần đổi `switchToHttp()` thành `switchToWs()`.

## 2.8 RxJS trong Interceptor

Interceptor trả về **Observable**, không phải giá trị:

```ts
return next.handle().pipe(
  map((data) => ({ success: true, statusCode, data, timestamp })),
);
```

Cho phép những thứ khó làm với Promise: `timeout(5000)`, `retry(3)`, `catchError()`,
caching, throttling — mỗi thứ một toán tử.

Cũng là lý do `LoggingInterceptor` dùng `tap({ next, error })` chứ không phải `try/catch`.

---

# PHẦN 3 — SO SÁNH TRỰC TIẾP

| | Express thuần | NestJS |
|---|---|---|
| Cấu trúc thư mục | Tự nghĩ, mỗi project một kiểu | Bắt buộc module/controller/service |
| Dependency | `require()` thủ công, tự `new` | DI container tự tiêm |
| Lỗi thiếu dependency | Runtime, lúc user gọi API | **Boot time**, trước khi mở port |
| Validate input | Viết tay hoặc gọi joi thủ công | Decorator trên DTO, tự động |
| Auth | Middleware, dễ quên gắn | `@UseGuards()`, thấy ngay trên method |
| Xử lý lỗi | `try/catch` rải khắp nơi | Một filter global |
| Test | Phải mock `require` | Inject mock qua DI |
| TypeScript | Optional | Bắt buộc (cần metadata) |
| Learning curve | Vài giờ | Vài ngày |
| Boilerplate | Ít lúc đầu, nhiều dần | Nhiều lúc đầu, ổn định về sau |

---

# PHẦN 4 — ĐIỀU GÌ THỰC SỰ ĐẶC BIỆT?

Bỏ qua marketing, có **3 thứ** NestJS làm mà framework Node khác không làm:

### 1. Dùng hệ thống kiểu của TypeScript làm cấu hình runtime

`design:paramtypes` biến khai báo kiểu — thứ vốn bị xóa sạch khi compile — thành thông tin runtime.
Bạn viết kiểu để IDE gợi ý, NestJS dùng chính kiểu đó để tiêm dependency.
**Một lần viết, hai lần dùng.**

### 2. Dịch chuyển lỗi từ runtime sang boot time

Toàn bộ đồ thị phụ thuộc được dựng và kiểm tra **trước khi** mở port.
Cả lớp lỗi "quên wire dependency" biến mất khỏi production.

### 3. Kiến trúc là thứ được thực thi, không phải khuyến nghị

Với Express, "hãy tách business logic ra service" là lời khuyên — nhóm 5 người sẽ có 5 cách hiểu.
Với NestJS, cấu trúc đó là **điều kiện để code chạy được**.

### Cái giá phải trả

- Boilerplate nhiều với app nhỏ — project này có ~20 file cho 10 endpoint.
- Phải hiểu DI, decorator, RxJS mới debug được.
- "Magic" — lỗi khó đọc nếu không nắm cơ chế bên dưới (chính là lý do bộ docs này tồn tại).

---

# PHẦN 5 — SCRIPT TỰ ĐO LẠI

## Đo `scryptSync` chặn event loop

```js
// eventloop-demo.js
const { scryptSync, scrypt, randomBytes } = require("node:crypto");
const PW = "123456";
const SALT = randomBytes(16).toString("hex");

let t = process.hrtime.bigint();
scryptSync(PW, SALT, 64);
console.log(`scryptSync 1 lần: ${(Number(process.hrtime.bigint() - t) / 1e6).toFixed(1)} ms`);

const t0 = process.hrtime.bigint();
setTimeout(() => {
  const late = Number(process.hrtime.bigint() - t0) / 1e6;
  console.log(`setTimeout(0) nổ sau: ${late.toFixed(1)} ms  ← event loop bị chặn`);
  compare();
}, 0);
scryptSync(PW, SALT, 64);   // chặn ngay tại đây

function compare() {
  const N = 8;
  let s = process.hrtime.bigint();
  for (let i = 0; i < N; i++) scryptSync(PW, SALT, 64);
  const syncMs = Number(process.hrtime.bigint() - s) / 1e6;
  console.log(`${N}x scryptSync (tuần tự): ${syncMs.toFixed(1)} ms`);

  s = process.hrtime.bigint();
  let done = 0;
  for (let i = 0; i < N; i++) {
    scrypt(PW, SALT, 64, () => {
      if (++done === N) {
        const asyncMs = Number(process.hrtime.bigint() - s) / 1e6;
        console.log(`${N}x scrypt (song song): ${asyncMs.toFixed(1)} ms`);
        console.log(`→ nhanh gấp ${(syncMs / asyncMs).toFixed(1)}x nhờ thread pool`);
        console.log(`UV_THREADPOOL_SIZE = ${process.env.UV_THREADPOOL_SIZE ?? "4 (mặc định)"}`);
        console.log(`CPU cores = ${require("node:os").cpus().length}`);
      }
    });
  }
}
```

```bash
node eventloop-demo.js
UV_THREADPOOL_SIZE=8 node eventloop-demo.js   # so sánh khi tăng pool
```

## Xem thứ tự pha của event loop

```js
// phases.js
const order = [];
const log = (s) => order.push(s);

setTimeout(()   => log("1. timers      : setTimeout(0)"), 0);
setImmediate(() => log("3. check       : setImmediate"));
require("node:fs").readFile(__filename, () => {
  log("2. poll        : fs.readFile callback");
  setTimeout(()   => log("6. timers      : setTimeout trong I/O"), 0);
  setImmediate(() => log("5. check       : setImmediate trong I/O  ← luôn trước setTimeout"));
  process.nextTick(() => log("4. nextTick    : chen ngay sau I/O callback"));
});
process.nextTick(()      => log("0a. nextTick   : trước tất cả"));
Promise.resolve().then(() => log("0b. Promise    : sau nextTick, vẫn trước mọi pha"));

setTimeout(() => console.log("Thứ tự thực tế:\n  " + order.join("\n  ")), 50);
```

## Dump metadata của NestJS

Cần build trước: `npm run build`

```js
// metadata-demo.js  (đặt trong thư mục backend/)
require("reflect-metadata");
const { PostsModule }     = require("./dist/posts/posts.module");
const { PostsController } = require("./dist/posts/posts.controller");
const { AuthGuard }       = require("./dist/auth/auth.guard");

const names = (a) => (a || []).map((c) => c?.name ?? String(c));

for (const key of ["imports", "controllers", "providers", "exports"])
  console.log(`${key.padEnd(12)} =`, names(Reflect.getMetadata(key, PostsModule)));

console.log("controller path =", Reflect.getMetadata("path", PostsController));

const create = PostsController.prototype.create;
const METHODS = ["GET","POST","PUT","DELETE","PATCH","ALL","OPTIONS","HEAD"];
console.log("method  =", METHODS[Reflect.getMetadata("method", create)]);
console.log("guards  =", names(Reflect.getMetadata("__guards__", create)));

console.log("AuthGuard cần      :", names(Reflect.getMetadata("design:paramtypes", AuthGuard)));
console.log("PostsController cần:", names(Reflect.getMetadata("design:paramtypes", PostsController)));
```

> ⚠️ Nhớ xóa file demo khỏi thư mục `backend/` sau khi chạy xong, hoặc để trong `/tmp`.

---

## Đọc Thêm

- [03-luong-request.md](03-luong-request.md) — vòng đời request cụ thể trong project này
- [05-module-va-di.md](05-module-va-di.md) — cách dùng DI hằng ngày
- [06-van-de-ton-dong.md](06-van-de-ton-dong.md) — các vấn đề cần sửa, gồm `scryptSync`
