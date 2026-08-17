# Module & Dependency Injection

Module trong NestJS là **hai thứ cùng lúc**:

1. Đơn vị tổ chức code theo tính năng
2. **Biên giới DI** — quyết định provider nào nhìn thấy provider nào

Hiểu vế thứ hai là chìa khóa để không bị mắc kẹt với lỗi *"can't resolve dependencies"*.

---

## Bốn Key Của `@Module`

Lấy [`../src/posts/posts.module.ts`](../src/posts/posts.module.ts) làm ví dụ:

```ts
@Module({
  imports:     [AuthModule],       // mượn gì từ module khác
  controllers: [PostsController],  // ai nhận HTTP request
  providers:   [PostsService],     // ai được DI container tạo & quản lý
})
export class PostsModule {}
```

Class rỗng `{}` — toàn bộ ý nghĩa nằm ở **metadata trong decorator**,
được `reflect-metadata` đọc lúc `NestFactory.create()` chạy.

| Key | Nghĩa | Quên thì sao |
|---|---|---|
| `controllers` | Class xử lý HTTP route | Route biến mất, **404 âm thầm, không báo lỗi** |
| `providers` | Service/Guard được DI tạo trong module này | Crash boot: *can't resolve dependencies* |
| `imports` | Module khác cần mượn provider | Crash boot |
| `exports` | Provider công khai cho module khác | Module khác không dùng được |

---

## `controllers` → Sinh Bảng Route

Nhờ khai `PostsController` mà lúc boot server in ra (log thật):

```txt
[RoutesResolver]  PostsController {/api/posts}:
[RouterExplorer]  Mapped {/api/posts, GET} route
[RouterExplorer]  Mapped {/api/posts, POST} route
[RouterExplorer]  Mapped {/api/posts/:id, PATCH} route
[RouterExplorer]  Mapped {/api/posts/:id, DELETE} route
```

> ⚠️ **Bẫy phổ biến nhất với người mới**: quên khai controller ở đây thì file vẫn compile bình thường,
> nhưng route **không tồn tại** → gọi API trả 404, và **không có thông báo lỗi nào**.
> Cách kiểm tra: xem log boot có dòng `Mapped {...}` cho route đó không.

---

## `providers` → Cho Phép Inject

Khai `PostsService` khiến Nest tạo **một instance duy nhất (singleton)** và tiêm vào constructor:

```ts
constructor(private readonly postsService: PostsService) {}
```

Không bao giờ phải `new PostsService(...)` thủ công.

---

## `imports` → Mở Cửa Sang Module Khác

### Vì sao `PostsModule` phải import `AuthModule`?

Nhìn `posts.controller.ts`:

```ts
@Post()
@UseGuards(AuthGuard)     // ← thủ phạm
create(...) { ... }
```

`AuthGuard` **không thuộc về** PostsModule — nó khai báo trong `auth.module.ts`.
Mà `AuthGuard` lại cần 2 thứ nữa:

```ts
constructor(
  private readonly authService: AuthService,
  private readonly crypto: CryptoService,
) {}
```

Trong NestJS, **mỗi module là biên giới DI khép kín**. PostsModule mặc định *không nhìn thấy*
provider của module khác. `imports: [AuthModule]` chính là **mở cửa**.

### Bằng chứng thực nghiệm

Đã thử xóa dòng `imports: [AuthModule]` rồi chạy `npx nest start`. Kết quả:

```txt
[Nest] ERROR [ExceptionHandler] Nest can't resolve dependencies of the
AuthGuard (?, CryptoService). Please make sure that the argument
AuthService at index [0] is available in the PostsModule context.

Potential solutions:
- Is PostsModule a valid NestJS module?
- If AuthService is a provider, is it part of the current PostsModule?
- If AuthService is exported from a separate @Module, is that module
  imported within PostsModule?
    @Module({
      imports: [ /* the Module containing AuthService */ ]
    })
```

App **chết ngay khi khởi động**, chưa mở port.
Dấu `?` trong `(?, CryptoService)` là cách Nest in lại chữ ký constructor
và đánh dấu tham số đầu tiên nó không giải được.

> 💡 Điểm mạnh của NestJS: lỗi DI luôn nổ **lúc boot**, không phải lúc user gọi API.

### Cần cả hai vế: `imports` + `exports`

`imports` chỉ có tác dụng nếu phía bên kia **cho phép**. `auth.module.ts`:

```ts
@Module({
  controllers: [AuthController],
  providers:   [AuthService, AuthGuard, CryptoService],
  exports:     [AuthService, AuthGuard, CryptoService],   // ← công khai cả 3
})
```

Nếu AuthModule chỉ khai `providers` mà không `exports`, thì dù PostsModule có `imports`
vẫn lỗi y hệt.

---

## `@Global()` — Ngoại Lệ

### Câu hỏi: sao `PostsModule` không import `DatabaseModule`?

`PostsService` rõ ràng dùng `DatabaseService`:

```ts
constructor(private readonly database: DatabaseService) {}
```

Mà `imports` chỉ có `AuthModule`. Lý do ở `database.module.ts`:

```ts
@Global()          // ← đây
@Module({
  providers: [DatabaseService],
  exports:   [DatabaseService],
})
export class DatabaseModule {}
```

`@Global()` đăng ký module vào **scope toàn cục** — mọi module dùng được mà **không cần import**.
Chỉ cần `AppModule` import một lần là xong.

> 💡 **Khi nào dùng `@Global()`**: hạ tầng dùng ở khắp nơi (DB, logger, cache).
> **Khi nào KHÔNG**: mọi thứ khác. `@Global()` làm mất tính tường minh — đọc code không biết
> dependency đến từ đâu. `AuthModule` **cố ý không** `@Global()` vì chỉ vài module cần nó.

---

## Vì Sao `PostsModule` Không Có `exports`?

Vì **không ai cần `PostsService`**. Nó chỉ phục vụ `PostsController` trong cùng module.
Không export = không rò rỉ ra ngoài = giữ tính đóng gói.

Nếu sau này thêm `CommentsModule` cần đếm số post, lúc đó mới thêm:

```ts
exports: [PostsService]
```

---

## Sơ Đồ Quan Hệ Module Của Project

```txt
AppModule  (app.module.ts)
  │
  ├─ imports ConfigModule    ──[isGlobal]──┐
  ├─ imports ThrottlerModule               │
  ├─ imports DatabaseModule  ──[@Global]───┤  dùng được ở MỌI nơi
  │                                        │  mà KHÔNG cần import
  ├─ imports AuthModule                    │
  │     providers: AuthService, AuthGuard, CryptoService
  │     exports:   AuthService, AuthGuard, CryptoService
  │                          │
  │                    (cho mượn)
  │                          ↓
  ├─ imports PostsModule  ◄──┘
  │     imports:     [AuthModule]        ← để @UseGuards(AuthGuard) chạy được
  │     controllers: [PostsController]   ← sinh 5 route /api/posts
  │     providers:   [PostsService] ─────┘ inject DatabaseService (nhờ @Global)
  │     exports:     —                     không ai cần
  │
  └─ imports HealthModule
        controllers: [HealthController]   ← không provider, không dependency
```

---

## Đăng Ký Enhancer Global (Guard/Filter/Interceptor/Pipe)

`app.module.ts` dùng token đặc biệt:

```ts
providers: [
  { provide: APP_GUARD,       useClass: ThrottlerGuard },
  { provide: APP_FILTER,      useClass: HttpExceptionFilter },
  { provide: APP_INTERCEPTOR, useClass: LoggingInterceptor },
  { provide: APP_INTERCEPTOR, useClass: TransformResponseInterceptor },
],
```

| Cách đăng ký | Inject được dependency? | Ví dụ trong project |
|---|---|---|
| `{ provide: APP_*, useClass }` trong module | ✅ Có | 4 dòng trên |
| `app.useGlobalPipes(new X())` trong `main.ts` | ❌ Không | `ValidationPipe` |

`ValidationPipe` không cần dependency nên viết ở `main.ts` là ổn.
Nếu sau này cần pipe tùy biến dùng `ConfigService`, phải chuyển sang `{ provide: APP_PIPE, ... }`.

> ⚠️ Với `APP_INTERCEPTOR`, **thứ tự khai báo = thứ tự chạy lượt đi**, và **ngược lại ở lượt về**.
> `LoggingInterceptor` khai trước → nằm ngoài cùng → chạy cuối ở lượt về
> → đo được trọn thời gian của cả chuỗi bên trong.

---

## Checklist Khi Thêm Module Mới

```txt
1. Tạo thư mục src/<ten>/
2. Tạo <ten>.module.ts với @Module({})
3. Khai controller vào `controllers`      → nếu quên: 404 âm thầm
4. Khai service vào `providers`           → nếu quên: crash boot
5. Cần AuthGuard? → imports: [AuthModule]
6. Cần DatabaseService? → KHÔNG cần import (đã @Global)
7. Module khác cần service của mình? → thêm `exports`
8. Import module mới vào AppModule.imports  → nếu quên: module không tồn tại
9. Chạy `npm run start`, kiểm tra log có dòng `Mapped {...} route`
```

---

## Đọc Lỗi DI

| Thông báo | Nguyên nhân | Cách sửa |
|---|---|---|
| `Nest can't resolve dependencies of the X (?)` | Provider ở index `?` không có trong scope | Thêm vào `providers`, hoặc `imports` module chứa nó |
| `...is available in the YModule context` | Nest nói rõ **module nào** đang thiếu | Sửa `imports` của đúng module đó |
| Route trả 404 nhưng không có lỗi boot | Quên khai `controllers` | Thêm vào `controllers` |
| `Cannot read properties of undefined` lúc runtime | Provider có nhưng chưa `exports` ở module nguồn | Thêm vào `exports` |
