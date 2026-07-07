# Cấu Trúc Project Flutter App

File này mô tả cấu trúc hiện tại của Flutter app sau khi tách workspace thành `app/` và `backend/`.

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
- `app/`: cấu hình app root, router và theme.
- `core/`: hằng số, network, storage, localization, permission, utils.
- `shared/`: widget dùng chung.
- `features/`: code theo từng chức năng lớn.

## app/

```txt
lib/app/
├── app.dart
├── router.dart
└── theme.dart
```

- `app.dart`: tạo `MaterialApp.router`, gắn router, theme, dark theme, locale.
- `router.dart`: cấu hình route bằng `go_router`.
- `theme.dart`: theme sáng/tối dùng chung toàn app.

Route hiện có:

```txt
/                 -> SplashScreen
/register         -> RegisterScreen
/login            -> LoginScreen
/login-success    -> LoginSuccessScreen
/management       -> MainShellScreen
/notifications    -> NotificationsScreen
/create-post      -> CreatePostScreen
/posts/create     -> CreatePostScreen
/posts/:id        -> PostDetailScreen
/account/profile  -> ProfileScreen
/account/security -> AccountSecurityScreen
/settings         -> SettingsScreen
/settings/theme   -> ThemeSettingsScreen
/settings/language -> LanguageSettingsScreen
/settings/about   -> AboutScreen
```

Sau đăng nhập, app vào `MainShellScreen` với bottom navigation:

```txt
Home | Posts | Account
```

## core/

```txt
lib/core/
├── constants/
├── localization/
├── network/
├── permissions/
├── storage/
└── utils/
```

- `constants/`: `AppConstants`, `StorageKeys`.
- `localization/`: `appStringsProvider`, text tiếng Việt/English.
- `network/`: `ApiClient`, `ApiEndpoints`, helper nhận diện lỗi mạng.
- `permissions/`: xin quyền ảnh trước khi chọn ảnh.
- `storage/`: wrapper cho `SharedPreferences`.
- `utils/`: snackbar, validators.

Storage key hiện có:

```txt
user_data
is_logged_in
access_token
theme_mode
language_code
```

## shared/

```txt
lib/shared/widgets/
├── animated_list_item.dart
├── custom_app_bar.dart
├── custom_button.dart
├── custom_text_field.dart
├── empty_view.dart
├── image_picker_box.dart
├── no_connection_view.dart
└── loading_view.dart
```

`image_picker_box.dart` là component chọn ảnh dùng chung. Màn cha chịu trách nhiệm xin quyền và gọi `image_picker`.

`animated_list_item.dart` là component animation dùng chung cho item trong danh sách.

`no_connection_view.dart` là màn mất mạng dùng chung cho các màn gọi API.

## features/

```txt
lib/features/
├── account/
├── auth/
├── home/
├── posts/
├── settings/
└── shell/
```

## features/auth/

```txt
lib/features/auth/
├── models/
├── providers/
├── screens/
└── services/
```

Auth xử lý:

- đăng ký qua backend
- đăng nhập qua backend
- hiển thị màn chuyển tiếp sau khi đăng nhập thành công
- lưu token
- khôi phục session qua `/auth/me`
- logout

## features/shell/

```txt
lib/features/shell/screens/main_shell_screen.dart
```

`MainShellScreen` giữ bottom navigation và dùng `AnimatedSwitcher` để chuyển tab mượt hơn.

## features/home/

```txt
lib/features/home/screens/home_screen.dart
```

Home hiển thị tổng quan bài viết, số post, chart thống kê post có ảnh/không ảnh và lối tắt tạo post.

## features/posts/

```txt
lib/features/posts/
├── models/
├── repositories/
└── screens/
```

Posts xử lý:

- lấy danh sách post từ backend
- tạo post mới
- chọn ảnh cho post
- xem chi tiết post

`PostModel` gồm:

- `id`
- `title`
- `body`
- `imagePath`

`PostRepository` gọi:

```txt
GET  /posts
POST /posts
```

## features/account/

Account hiển thị thông tin user, profile, security và logout. Logout dùng modal xác nhận trước khi thoát tài khoản.

## Shared UI Rule

- Toast/message dùng `AppSnackbar.show(...)` để hiển thị ở phía trên màn hình.
- List item nên dùng `AnimatedListItem` nếu cần hiệu ứng xuất hiện.
- Lỗi mất mạng dùng `NetworkError.isOffline(...)` + `NoConnectionView`.
- Component dùng chung đặt trong `shared/widgets/`, không hard code lại ở từng feature.

## features/settings/

Settings xử lý:

- theme: system, light, dark
- language: vi, en
- lưu lựa chọn vào local storage
