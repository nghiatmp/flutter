import 'package:flutter/material.dart';

ThemeData buildAppTheme() {
  /// Tạo bảng màu chính từ một màu seed.
  /// Material 3 sẽ tự sinh các màu primary, secondary, background...
  final colorScheme = ColorScheme.fromSeed(
    seedColor: const Color(0xFF2563EB),
    brightness: Brightness.light,
  );

  /// Theme dùng chung toàn app để các màn hình có style thống nhất.
  /// Khi muốn đổi giao diện tổng thể, ưu tiên sửa ở đây thay vì sửa từng màn.
  return ThemeData(
    colorScheme: colorScheme,
    useMaterial3: true,
    scaffoldBackgroundColor: const Color(0xFFF7F8FA),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      filled: true,
      fillColor: Colors.white,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        minimumSize: const Size.fromHeight(48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
  );
}
