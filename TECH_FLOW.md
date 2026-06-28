# Luồng Hoạt Động Kỹ Thuật Của App

File này mô tả app chạy như thế nào theo góc nhìn kỹ thuật. Nội dung tập trung vào luồng dữ liệu, global state, local storage, permission, form validate, route và API.

## Công Nghệ Chính

Project đang dùng các package chính:

```txt
flutter_riverpod
go_router
dio
shared_preferences
permission_handler
image_picker
```

Vai trò:

- `flutter_riverpod`: quản lý global state, tương tự Redux trong React.
- `go_router`: quản lý route và redirect.
- `dio`: gọi API.
- `shared_preferences`: lưu dữ liệu local.
- `permission_handler`: xin quyền truy cập ảnh/thư viện.
- `image_picker`: mở thư viện ảnh để chọn ảnh.

## Sơ Đồ Tổng Quát

```txt
main.dart
  |
  v
ProviderScope
  |
  v
StudyFlutterApp
  |
  v
MaterialApp.router
  |
  v
GoRouter đọc authProvider
  |
  +--> SplashScreen
  +--> RegisterScreen
  +--> LoginScreen
  +--> ManagementScreen
```

## 1. Luồng Khởi Động App

Khi app chạy, hàm `main()` được gọi trước.

```txt
main()
  -> WidgetsFlutterBinding.ensureInitialized()
  -> runApp(ProviderScope(child: StudyFlutterApp()))
```

Ý nghĩa:

- `WidgetsFlutterBinding.ensureInitialized()` chuẩn bị Flutter engine trước khi dùng plugin native.
- `ProviderScope` tạo vùng global state cho Riverpod.
- Tất cả provider trong app đều hoạt động bên trong `ProviderScope`.

So với React Redux:

```txt
ProviderScope  ~=  <Provider store={store}>
```

## 2. Luồng Router Và Check Session

`StudyFlutterApp` dùng `MaterialApp.router`.

Router được lấy từ:

```txt
appRouterProvider
```

Trong `router.dart`, router đọc:

```txt
authProvider
```

Mục đích:

- biết app đã đọc xong session chưa
- biết user đã đăng nhập chưa
- redirect người dùng sang màn phù hợp

Luồng redirect:

```txt
App mở
  |
  v
authProvider.isReady == false
  |
  v
ở SplashScreen
  |
  v
AuthNotifier.loadSession()
  |
  v
đọc is_logged_in và user_data từ local storage
  |
  v
authProvider.isReady == true
  |
  +--> isLoggedIn == true  -> /management
  |
  +--> isLoggedIn == false -> /register
```

Nếu user chưa đăng nhập mà cố vào `/management`:

```txt
/management -> redirect /login
```

Nếu user đã đăng nhập mà vào `/login` hoặc `/register`:

```txt
/login hoặc /register -> redirect /management
```

## 3. Global State Giống Redux

App có global state bằng Riverpod.

### Mapping Với Redux React

```txt
Redux store        -> ProviderScope
Redux slice state  -> AuthState / List<TaskModel>
Redux action       -> login(), logout(), addTask(), updateTask(), deleteTask()
Redux reducer      -> AuthNotifier / TaskNotifier
useSelector        -> ref.watch(...)
dispatch           -> ref.read(...notifier).method()
```

### Global Auth State

File:

```txt
lib/features/auth/providers/auth_provider.dart
```

Provider chính:

```txt
authProvider
```

State:

```txt
AuthState {
  isReady
  isLoggedIn
  user
}
```

Action:

```txt
loadSession()
register(user)
login(email, password)
logout()
```

Ví dụ đọc state:

```dart
final authState = ref.watch(authProvider);
```

Ví dụ gọi action:

```dart
await ref.read(authProvider.notifier).login(
  email: email,
  password: password,
);
```

### Global Task State

File:

```txt
lib/features/management/providers/task_provider.dart
```

Provider chính:

```txt
taskProvider
```

State:

```txt
List<TaskModel>
```

Action:

```txt
loadTasks()
addTask()
updateTask()
deleteTask()
```

Ví dụ đọc danh sách task:

```dart
final tasks = ref.watch(taskProvider);
```

Ví dụ thêm task:

```dart
await ref.read(taskProvider.notifier).addTask(
  title: title,
  description: description,
  imagePath: imagePath,
);
```

## 4. Luồng Đăng Ký

Màn hình:

```txt
RegisterScreen
```

Form gồm:

- Họ tên
- Email
- Mật khẩu
- Xác nhận mật khẩu

Luồng kỹ thuật:

```txt
User nhập form
  |
  v
bấm Đăng ký
  |
  v
_formKey.currentState!.validate()
  |
  +--> invalid -> hiển thị lỗi dưới input
  |
  +--> valid
        |
        v
      tạo UserModel
        |
        v
      ref.read(authProvider.notifier).register(user)
        |
        v
      AuthNotifier.register()
        |
        v
      AuthService.register()
        |
        v
      LocalStorage.setString(user_data, userJson)
      LocalStorage.setBool(is_logged_in, false)
        |
        v
      cập nhật AuthState
        |
        v
      context.go('/login')
```

Validate được xử lý bởi:

```txt
lib/core/utils/validators.dart
```

Các rule:

- required
- email format
- password tối thiểu 6 ký tự
- confirm password phải trùng password

## 5. Luồng Đăng Nhập

Màn hình:

```txt
LoginScreen
```

Form gồm:

- Email
- Mật khẩu

Luồng kỹ thuật:

```txt
User nhập email/password
  |
  v
bấm Đăng nhập
  |
  v
validate form
  |
  +--> invalid -> hiển thị lỗi
  |
  +--> valid
        |
        v
      ref.read(authProvider.notifier).login(...)
        |
        v
      AuthNotifier.login()
        |
        v
      AuthService.login()
        |
        v
      đọc user_data từ local storage
        |
        v
      so khớp email/password
        |
        +--> sai -> throw Exception -> SnackBar lỗi
        |
        +--> đúng
              |
              v
            setBool(is_logged_in, true)
              |
              v
            AuthState.isLoggedIn = true
              |
              v
            context.go('/management')
```

Sau khi `AuthState.isLoggedIn = true`, router cũng có thể phản ứng theo state mới.

## 6. Luồng Màn Quản Lý

Màn hình:

```txt
ManagementScreen
```

Màn này đọc 3 provider:

```dart
final authState = ref.watch(authProvider);
final tasks = ref.watch(taskProvider);
final posts = ref.watch(postsProvider);
```

Ý nghĩa:

- `authState`: lấy thông tin user đang đăng nhập.
- `tasks`: lấy danh sách task local.
- `posts`: lấy dữ liệu API bên thứ ba.

## 7. Luồng Thêm Task

Widget form:

```txt
TaskForm
```

Luồng kỹ thuật:

```txt
User nhập tiêu đề/mô tả
  |
  v
có thể chọn ảnh
  |
  v
bấm Thêm vào danh sách
  |
  v
TaskForm validate
  |
  +--> invalid -> hiển thị lỗi
  |
  +--> valid
        |
        v
      TaskForm gọi callback onSubmit(title, description)
        |
        v
      ManagementScreen gọi taskProvider.notifier.addTask(...)
        |
        v
      TaskNotifier.addTask()
        |
        v
      tạo TaskModel mới
        |
        v
      state = [task, ...state]
        |
        v
      _save()
        |
        v
      lưu tasks_data vào local storage
        |
        v
      UI tự rebuild vì ref.watch(taskProvider)
```

Điểm quan trọng:

- `TaskForm` không tự biết thêm hay sửa task.
- `TaskForm` chỉ validate và trả dữ liệu ra ngoài qua callback.
- Màn cha quyết định gọi `addTask` hoặc `updateTask`.

## 8. Luồng Sửa Task

Khi bấm icon sửa ở `TaskItem`:

```txt
TaskItem.onEdit
  |
  v
ManagementScreen._openEditSheet(task)
  |
  v
showModalBottomSheet
  |
  v
TaskForm(initialTask: task)
```

Luồng submit sửa:

```txt
User sửa title/description/ảnh
  |
  v
bấm Lưu thay đổi
  |
  v
TaskForm validate
  |
  v
onSubmit(title, description)
  |
  v
task.copyWith(...)
  |
  v
taskProvider.notifier.updateTask(updatedTask)
  |
  v
TaskNotifier.updateTask()
  |
  v
tạo list mới, thay item có cùng id
  |
  v
_save()
  |
  v
lưu lại local storage
  |
  v
đóng bottom sheet
```

## 9. Luồng Xóa Task

Khi bấm icon xóa:

```txt
TaskItem.onDelete
  |
  v
taskProvider.notifier.deleteTask(task.id)
  |
  v
TaskNotifier.deleteTask(id)
  |
  v
state = state.where((task) => task.id != id).toList()
  |
  v
_save()
  |
  v
lưu lại tasks_data
  |
  v
UI tự rebuild
```

## 10. Luồng Lưu Local Storage

Plugin:

```txt
shared_preferences
```

Lớp bọc:

```txt
LocalStorage
```

Dữ liệu đang lưu:

```txt
user_data      -> thông tin user đăng ký
is_logged_in   -> trạng thái đăng nhập
tasks_data     -> danh sách task
```

Auth storage:

```txt
AuthService
  -> LocalStorage
  -> SharedPreferences
```

Task storage:

```txt
TaskNotifier
  -> LocalStorage
  -> SharedPreferences
```

Lưu ý:

- User và task được encode thành JSON string.
- Khi đọc ra thì decode JSON thành model.
- App thực tế không nên lưu password plain text.

## 11. Luồng Check Permission Và Chọn Ảnh

Package:

```txt
permission_handler
image_picker
```

Service:

```txt
PermissionService
```

Luồng kỹ thuật:

```txt
User bấm Chọn ảnh
  |
  v
ManagementScreen._pickImage()
  |
  v
PermissionService.requestPhotoPermission()
  |
  +--> không có quyền
  |       |
  |       v
  |     SnackBar lỗi
  |
  +--> có quyền
          |
          v
        ImagePicker.pickImage(source: ImageSource.gallery)
          |
          v
        nhận XFile?
          |
          v
        lưu pickedFile.path vào state
```

Với form thêm mới:

```txt
_selectedImagePath = path
```

Với form sửa:

```txt
editingImagePath = path
```

Platform config:

- Android: thêm quyền trong `AndroidManifest.xml`.
- iOS: thêm `NSPhotoLibraryUsageDescription` trong `Info.plist`.

## 12. Luồng Gọi API GET Bên Thứ Ba

Package:

```txt
dio
```

API client:

```txt
ApiClient
```

Config:

```txt
baseUrl: https://jsonplaceholder.typicode.com
timeout: 10 giây
headers: Accept application/json
interceptor: LogInterceptor
```

Repository:

```txt
PostRepository
```

Provider:

```txt
postsProvider
```

Luồng kỹ thuật:

```txt
ManagementScreen build
  |
  v
ref.watch(postsProvider)
  |
  v
PostRepository.fetchPosts()
  |
  v
ApiClient.get(ApiEndpoints.posts)
  |
  v
GET https://jsonplaceholder.typicode.com/posts
  |
  v
response.data
  |
  v
map JSON -> PostModel
  |
  v
posts.when(...)
```

UI xử lý 3 trạng thái:

```txt
loading -> LoadingView
data    -> danh sách post
error   -> card báo lỗi + nút tải lại
```

Khi kéo refresh:

```txt
RefreshIndicator
  |
  v
ref.invalidate(postsProvider)
  |
  v
gọi lại API
```

## 13. Luồng Logout

Khi bấm icon logout:

```txt
ManagementScreen._logout()
  |
  v
ref.read(authProvider.notifier).logout()
  |
  v
AuthNotifier.logout()
  |
  v
AuthService.logout()
  |
  v
LocalStorage.setBool(is_logged_in, false)
  |
  v
AuthState.isLoggedIn = false
AuthState.user = null
  |
  v
context.go('/login')
```

## 14. Vì Sao Cấu Trúc Này Dễ Mở Rộng

Project đang chia theo trách nhiệm:

```txt
UI screen       -> hiển thị giao diện, gọi provider action
Widget          -> component nhỏ có thể tái sử dụng
Provider        -> global state và action
Service         -> nghiệp vụ local như auth/storage
Repository      -> nghiệp vụ API
Model           -> cấu trúc dữ liệu
Core            -> tiện ích dùng chung
```

Khi thêm feature mới, có thể tạo:

```txt
lib/features/new_feature/
├── models/
├── providers/
├── repositories/
├── screens/
└── widgets/
```

## 15. Thứ Tự Nên Debug Khi Có Lỗi

Nếu lỗi đăng ký/đăng nhập:

1. Xem `RegisterScreen` hoặc `LoginScreen`.
2. Xem `authProvider`.
3. Xem `AuthService`.
4. Xem `LocalStorage`.

Nếu lỗi danh sách task:

1. Xem `ManagementScreen`.
2. Xem `TaskForm` hoặc `TaskItem`.
3. Xem `taskProvider`.
4. Xem `LocalStorage`.

Nếu lỗi API:

1. Xem `ManagementScreen` phần `posts.when`.
2. Xem `postsProvider`.
3. Xem `PostRepository`.
4. Xem `ApiClient`.
5. Kiểm tra mạng hoặc endpoint.

Nếu lỗi chọn ảnh:

1. Xem `ManagementScreen._pickImage`.
2. Xem `PermissionService`.
3. Kiểm tra Android/iOS permission config.
4. Kiểm tra `image_picker`.

