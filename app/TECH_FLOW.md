# Luồng Hoạt Động Kỹ Thuật Của App

File này mô tả luồng chính của Flutter app.

## Công Nghệ Chính

```txt
flutter_riverpod
go_router
dio
shared_preferences
permission_handler
image_picker
flutter_localizations
```

Vai trò:

- `flutter_riverpod`: quản lý state.
- `go_router`: điều hướng và redirect.
- `dio`: gọi NestJS API.
- `shared_preferences`: lưu token, user cache, theme, language.
- `permission_handler`: xin quyền ảnh.
- `image_picker`: chọn ảnh từ thiết bị.
- `flutter_localizations`: hỗ trợ locale hệ thống của Flutter widgets.

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
GoRouter + authProvider
  |
  +--> Auth screens
  +--> MainShellScreen
        |
        +--> Home      (chart + summary)
        +--> Posts     (animated list + create post)
        +--> Account   (profile/settings/security/logout modal)
```

## Auth Flow

Đăng ký:

```txt
RegisterScreen
  -> authProvider.register(user)
  -> AuthService.register()
  -> POST /auth/register
  -> cache user gần nhất
  -> chuyển sang /login
```

Đăng nhập:

```txt
LoginScreen
  -> authProvider.login(email, password)
  -> AuthService.login()
  -> POST /auth/login
  -> lưu access_token
  -> AuthState.isLoggedIn = true
  -> /login-success
  -> LoginSuccessScreen chạy animation
  -> /management
```

Khôi phục session:

```txt
App mở
  -> AuthNotifier.loadSession()
  -> đọc is_logged_in + access_token
  -> GET /auth/me
  -> cập nhật AuthState
```

## Shell Và Navigation

Sau đăng nhập:

```txt
/management -> MainShellScreen
```

Bottom navigation:

```txt
Home | Posts | Account
```

Màn đi sâu dùng `context.push(...)` để có back:

```txt
Home -> Notifications
Posts -> CreatePost
Posts -> PostDetail
Account -> Profile
Account -> Settings -> Theme/Language/About
```

Chuyển tab trong `MainShellScreen` dùng `AnimatedSwitcher` để có fade/slide nhẹ.

## Posts Flow

Lấy danh sách post:

```txt
PostsScreen
  -> postsProvider
  -> PostRepository.fetchPosts()
  -> GET /posts
  -> map JSON -> PostModel
```

Tạo post:

```txt
CreatePostScreen
  -> nhập title/body
  -> chọn ảnh bằng ImagePickerBox
  -> PermissionService.requestPhotoPermission()
  -> ImagePicker.pickImage()
  -> PostRepository.createPost()
  -> POST /posts với Bearer token
  -> ref.invalidate(postsProvider)
  -> quay lại Posts
```

Post đang hỗ trợ:

```txt
title
body
imagePath
```

Toast thành công/lỗi trong toàn app gọi qua:

```txt
AppSnackbar.show(context, message)
```

Toast được render bằng `OverlayEntry` ở phía trên màn hình.

## No Connection Flow

```txt
Repository/Provider gọi API
  -> Dio ném lỗi timeout/connection
  -> NetworkError.isOffline(error)
  -> NoConnectionView
  -> người dùng bấm Thử lại
  -> ref.invalidate(provider)
```

Các màn đang dùng:

```txt
Home chart
Posts list
Post detail
```

## Home Chart Flow

```txt
HomeScreen
  -> postsProvider
  -> đếm tổng post
  -> đếm post có imagePath
  -> _PostsChartCard
  -> CustomPainter vẽ chart có animation
```

## Account Logout Flow

```txt
AccountScreen
  -> bấm Logout
  -> AlertDialog xác nhận
  -> AuthNotifier.logout()
  -> AppSnackbar.show(...)
  -> /login
```

## Settings Flow

Settings dùng `settingsProvider`:

```txt
SettingsScreen
  -> SettingsNotifier
  -> LocalStorage
  -> MaterialApp.router(themeMode, locale)
  -> appStringsProvider đổi text theo locale
```

Storage:

```txt
theme_mode     -> system, light, dark
language_code  -> vi, en
```

## Local Storage

```txt
user_data      -> cache user gần nhất để tự điền login
is_logged_in   -> trạng thái đăng nhập
access_token   -> token backend
theme_mode     -> system, light, dark
language_code  -> vi, en
```

## Network

Base URL nằm ở:

```txt
AppConstants.apiBaseUrl
```

Mặc định:

```txt
http://localhost:3000/api
```

Khi chạy trên máy thật, truyền IP LAN của máy chạy backend:

```txt
flutter run --dart-define=API_BASE_URL=http://<IP_MAC>:3000/api
```
