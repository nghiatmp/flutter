class StorageKeys {
  const StorageKeys._();

  /// Key lưu thông tin user đăng ký dưới dạng JSON string.
  static const user = 'user_data';

  /// Key lưu trạng thái đăng nhập để lần sau mở app có thể khôi phục session.
  static const isLoggedIn = 'is_logged_in';

  /// Key lưu danh sách task local dưới dạng JSON array.
  static const tasks = 'tasks_data';
}
