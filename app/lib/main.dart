import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';

void main() {
  /// Đảm bảo Flutter binding được khởi tạo trước khi app chạy.
  /// Bước này cần thiết khi app có dùng plugin native như shared_preferences,
  /// image_picker hoặc permission_handler.
  WidgetsFlutterBinding.ensureInitialized();

  /// ProviderScope là "vùng chứa" global state của Riverpod.
  /// Tất cả provider trong app như authProvider, taskProvider, postsProvider
  /// đều cần nằm bên trong ProviderScope để có thể đọc/ghi state.
  runApp(const ProviderScope(child: StudyFlutterApp()));
}
