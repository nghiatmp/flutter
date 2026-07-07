class AppConstants {
  const AppConstants._();

  /// Tên app dùng chung nếu cần hiển thị ở nhiều nơi.
  static const appName = 'Study Flutter';

  /// Base URL backend NestJS.
  /// Có thể đổi khi chạy app bằng:
  /// `--dart-define=API_BASE_URL=http://host:3000/api`
  static const apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://172.16.20.148:3000/api',
    // defaultValue: 'http://localhost:3000/api',
  );

  /// Tài khoản demo được backend tự tạo sẵn (xem AuthService.seedDefaultUser).
  /// Dùng để tự điền màn login khi máy chưa có user nào đăng ký cục bộ.
  static const demoUserEmail = 'demo@studyflutter.com';
  static const demoUserPassword = '123456';
}
