class AppConstants {
  const AppConstants._();

  /// Tên app dùng chung nếu cần hiển thị ở nhiều nơi.
  static const appName = 'Study Flutter';

  /// Base URL backend NestJS.
  /// Có thể đổi khi chạy app bằng:
  /// `--dart-define=API_BASE_URL=http://host:3000/api`
  static const apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:3000/api',
  );
}
