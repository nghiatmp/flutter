class ApiEndpoints {
  const ApiEndpoints._();

  /// Tách endpoint ra file riêng để tránh hard-code path trong nhiều repository.
  /// Khi API đổi path, chỉ cần sửa tại đây.
  static const posts = '/posts';
}
