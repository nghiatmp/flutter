# Cấu Trúc Project Flutter Demo

File này mô tả cách project đang được chia thư mục và vai trò của từng phần. Mục tiêu là giúp bạn đọc code theo đúng hướng: phần app chung, phần core dùng lại, phần shared widget, sau đó mới tới từng feature.

## Tổng Quan

```txt
lib/
├── main.dart
├── app/
├── core/
├── shared/
└── features/
```

Ý nghĩa chính:

- `main.dart`: điểm bắt đầu chạy app.
- `app/`: cấu hình cấp ứng dụng như router, theme, app root.
- `core/`: các service, helper, config dùng chung toàn app.
- `shared/`: các widget tái sử dụng giữa nhiều màn hình.
- `features/`: code nghiệp vụ theo từng chức năng lớn.

## main.dart

```txt
lib/main.dart
```

Vai trò:

- Khởi tạo Flutter binding.
- Bọc app bằng `ProviderScope`.
- `ProviderScope` là vùng chứa global state của Riverpod, tương tự `Provider` trong React Redux.
- Chạy widget gốc `StudyFlutterApp`.

## app/

```txt
lib/app/
├── app.dart
├── router.dart
└── theme.dart
```

### app.dart

File này chứa widget gốc `StudyFlutterApp`.

Nhiệm vụ:

- Tạo `MaterialApp.router`.
- Gắn router từ `appRouterProvider`.
- Gắn theme dùng chung.
- Tắt debug banner.

### router.dart

File này cấu hình điều hướng bằng `go_router`.

Các route hiện có:

```txt
/            -> SplashScreen
/register    -> RegisterScreen
/login       -> LoginScreen
/management  -> ManagementScreen
```

Router có logic redirect theo auth state:

- App chưa đọc xong session thì ở `/`.
- Đã đăng nhập thì vào `/management`.
- Chưa đăng nhập thì vào `/register` hoặc `/login`.
- Chưa đăng nhập mà mở `/management` thì bị đưa về `/login`.

### theme.dart

File này cấu hình giao diện chung:

- `ColorScheme`
- `InputDecorationTheme`
- `ElevatedButtonTheme`
- `CardTheme`
- `scaffoldBackgroundColor`

Khi muốn đổi style toàn app, ưu tiên sửa ở đây.

## core/

```txt
lib/core/
├── constants/
├── network/
├── permissions/
├── storage/
└── utils/
```

`core` chứa các phần nền tảng dùng lại ở nhiều feature.

### core/constants/

```txt
lib/core/constants/
├── app_constants.dart
└── storage_keys.dart
```

Vai trò:

- `app_constants.dart`: khai báo hằng số cấp app, ví dụ tên app.
- `storage_keys.dart`: khai báo key dùng cho local storage.

Các storage key hiện có:

```txt
user_data
is_logged_in
tasks_data
```

### core/network/

```txt
lib/core/network/
├── api_client.dart
└── api_endpoints.dart
```

Vai trò:

- `api_client.dart`: cấu hình `Dio`, `baseUrl`, timeout, header, interceptor.
- `api_endpoints.dart`: gom endpoint API vào một nơi.

API base URL hiện tại:

```txt
https://jsonplaceholder.typicode.com
```

Endpoint demo:

```txt
GET /posts
```

### core/permissions/

```txt
lib/core/permissions/
└── permission_service.dart
```

Vai trò:

- Tách logic request permission khỏi UI.
- Hiện dùng để xin quyền truy cập ảnh/thư viện ảnh trước khi chọn ảnh.

### core/storage/

```txt
lib/core/storage/
└── local_storage.dart
```

Vai trò:

- Bọc `shared_preferences`.
- Cung cấp hàm `setString`, `getString`, `setBool`, `getBool`, `remove`.
- Giúp feature không phụ thuộc trực tiếp vào plugin storage.

### core/utils/

```txt
lib/core/utils/
├── app_snackbar.dart
└── validators.dart
```

Vai trò:

- `app_snackbar.dart`: hiển thị thông báo thành công/lỗi.
- `validators.dart`: chứa rule validate form như required, email, password.

## shared/

```txt
lib/shared/
└── widgets/
    ├── custom_app_bar.dart
    ├── custom_button.dart
    ├── custom_text_field.dart
    ├── empty_view.dart
    └── loading_view.dart
```

`shared/widgets` chứa các widget dùng lại ở nhiều nơi.

### custom_app_bar.dart

App bar dùng chung.

Hỗ trợ:

- `title`
- `actions`
- `showBackButton`

### custom_button.dart

Button dùng chung.

Hỗ trợ:

- label
- icon
- loading
- disable khi loading

### custom_text_field.dart

Text field dùng chung cho form.

Hỗ trợ:

- controller
- label
- hint text
- validator
- keyboard type
- obscure text
- max lines
- prefix icon

### empty_view.dart

Widget hiển thị trạng thái không có dữ liệu.

Ví dụ dùng khi danh sách task rỗng.

### loading_view.dart

Widget hiển thị trạng thái đang tải.

Ví dụ dùng khi app đang check session hoặc đang gọi API.

## features/

```txt
lib/features/
├── auth/
└── management/
```

`features` chứa code theo từng nhóm chức năng. Đây là cấu trúc phổ biến để project dễ mở rộng.

## features/auth/

```txt
lib/features/auth/
├── models/
├── providers/
├── screens/
└── services/
```

Feature auth xử lý đăng ký, đăng nhập, đăng xuất và session.

### auth/models/

```txt
lib/features/auth/models/
└── user_model.dart
```

`UserModel` chứa:

- fullName
- email
- password

Ngoài ra có hàm chuyển đổi:

- `toMap`
- `fromMap`
- `toJson`
- `fromJson`

Lưu ý: đây là demo học Flutter nên password đang lưu local để minh họa flow. App thực tế không nên lưu password plain text.

### auth/services/

```txt
lib/features/auth/services/
└── auth_service.dart
```

`AuthService` xử lý nghiệp vụ auth:

- đăng ký user
- đọc user đã đăng ký
- login
- kiểm tra trạng thái login
- logout

Service này làm việc với `LocalStorage`.

### auth/providers/

```txt
lib/features/auth/providers/
└── auth_provider.dart
```

Đây là phần global state cho auth.

Các provider chính:

- `localStorageProvider`
- `authServiceProvider`
- `authProvider`

`authProvider` là `StateNotifierProvider<AuthNotifier, AuthState>`.

`AuthState` chứa:

- `isReady`
- `isLoggedIn`
- `user`

`AuthNotifier` chứa các action:

- `loadSession`
- `register`
- `login`
- `logout`

### auth/screens/

```txt
lib/features/auth/screens/
├── login_screen.dart
├── register_screen.dart
└── splash_screen.dart
```

Các màn hình:

- `SplashScreen`: chờ đọc session.
- `RegisterScreen`: form đăng ký, validate, lưu user local.
- `LoginScreen`: form đăng nhập, validate, kiểm tra user local.

## features/management/

```txt
lib/features/management/
├── models/
├── providers/
├── repositories/
├── screens/
└── widgets/
```

Feature management xử lý màn sau đăng nhập.

Bao gồm:

- thêm task
- sửa task
- xóa task
- hiển thị list task
- chọn ảnh có check permission
- lưu task local
- gọi API bên thứ ba

### management/models/

```txt
lib/features/management/models/
├── post_model.dart
└── task_model.dart
```

`TaskModel` dùng cho dữ liệu local:

- id
- title
- description
- imagePath

`PostModel` dùng cho dữ liệu API:

- id
- title
- body

### management/providers/

```txt
lib/features/management/providers/
└── task_provider.dart
```

Đây là global state cho danh sách task.

`taskProvider` là `StateNotifierProvider<TaskNotifier, List<TaskModel>>`.

`TaskNotifier` chứa các action:

- `loadTasks`
- `addTask`
- `updateTask`
- `deleteTask`
- `_save`

Sau mỗi action thêm/sửa/xóa, danh sách task được lưu lại vào local storage.

### management/repositories/

```txt
lib/features/management/repositories/
└── post_repository.dart
```

Repository gọi API bên thứ ba.

Các provider:

- `apiClientProvider`
- `postRepositoryProvider`
- `postsProvider`

`postsProvider` là `FutureProvider<List<PostModel>>`, dùng để quản lý trạng thái:

- loading
- data
- error

### management/screens/

```txt
lib/features/management/screens/
└── management_screen.dart
```

Màn quản lý chính.

Nhiệm vụ:

- đọc user từ `authProvider`
- đọc task từ `taskProvider`
- đọc post API từ `postsProvider`
- thêm task
- sửa task bằng bottom sheet
- xóa task
- chọn ảnh sau khi check permission
- logout
- refresh API

### management/widgets/

```txt
lib/features/management/widgets/
├── image_picker_box.dart
├── task_form.dart
└── task_item.dart
```

Các widget riêng của feature management:

- `TaskForm`: form thêm/sửa task.
- `TaskItem`: hiển thị một item trong list task.
- `ImagePickerBox`: nút chọn ảnh.

## Platform Folders

Ngoài `lib`, project còn có các thư mục platform do Flutter tạo:

```txt
android/
ios/
web/
macos/
linux/
windows/
```

Trong demo này có chỉnh:

- `android/app/src/main/AndroidManifest.xml`: thêm quyền đọc ảnh.
- `ios/Runner/Info.plist`: thêm mô tả quyền truy cập thư viện ảnh.

## Tóm Tắt Cách Đọc Code

Nên đọc theo thứ tự:

1. `lib/main.dart`
2. `lib/app/app.dart`
3. `lib/app/router.dart`
4. `lib/features/auth/providers/auth_provider.dart`
5. `lib/features/auth/services/auth_service.dart`
6. `lib/features/auth/screens/register_screen.dart`
7. `lib/features/auth/screens/login_screen.dart`
8. `lib/features/management/screens/management_screen.dart`
9. `lib/features/management/providers/task_provider.dart`
10. `lib/features/management/repositories/post_repository.dart`

