class ApiEndpoints {
  const ApiEndpoints._();

  /// Tách endpoint ra file riêng để tránh hard-code path trong nhiều repository.
  /// Khi API đổi path, chỉ cần sửa tại đây.
  static const authRegister = '/auth/register';
  static const authLogin = '/auth/login';
  static const authMe = '/auth/me';
  static const authChangePassword = '/auth/change-password';
  static const posts = '/posts';
}
