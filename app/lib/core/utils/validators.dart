class Validators {
  const Validators._();

  /// Validate bắt buộc nhập.
  /// Trả về chuỗi lỗi để TextFormField hiển thị dưới input.
  /// Trả về null nghĩa là dữ liệu hợp lệ.
  static String? required(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName không được để trống';
    }
    return null;
  }

  /// Validate email gồm 2 bước:
  /// 1. Không được trống.
  /// 2. Phải khớp định dạng email cơ bản.
  static String? email(String? value) {
    final requiredError = required(value, 'Email');
    if (requiredError != null) return requiredError;

    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!emailRegex.hasMatch(value!.trim())) {
      return 'Email không đúng định dạng';
    }
    return null;
  }

  /// Validate mật khẩu:
  /// 1. Không được trống.
  /// 2. Tối thiểu 6 ký tự cho demo.
  static String? password(String? value) {
    final requiredError = required(value, 'Mật khẩu');
    if (requiredError != null) return requiredError;

    if (value!.length < 6) {
      return 'Mật khẩu tối thiểu 6 ký tự';
    }
    return null;
  }
}
