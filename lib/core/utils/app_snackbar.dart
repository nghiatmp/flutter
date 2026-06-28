import 'package:flutter/material.dart';

class AppSnackbar {
  const AppSnackbar._();

  /// Hàm hiển thị thông báo dùng chung toàn app.
  /// isError = true thì dùng màu đỏ, ngược lại dùng màu xanh thành công.
  /// Việc gom về một chỗ giúp các màn hình không phải lặp code SnackBar.
  static void show(
    BuildContext context,
    String message, {
    bool isError = false,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red.shade700 : Colors.green.shade700,
      ),
    );
  }
}
