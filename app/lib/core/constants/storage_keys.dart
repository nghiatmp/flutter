class StorageKeys {
  const StorageKeys._();

  /// Key lưu thông tin user đăng ký dưới dạng JSON string.
  static const user = 'user_data';

  /// Key lưu trạng thái đăng nhập để lần sau mở app có thể khôi phục session.
  static const isLoggedIn = 'is_logged_in';

  /// Token backend trả về sau khi đăng nhập.
  static const accessToken = 'access_token';

  /// Key lưu chế độ giao diện: system, light hoặc dark.
  static const themeMode = 'theme_mode';

  /// Key lưu ngôn ngữ hiện tại: vi hoặc en.
  static const languageCode = 'language_code';
}
