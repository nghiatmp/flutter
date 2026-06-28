import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'router.dart';
import 'theme.dart';

class StudyFlutterApp extends ConsumerWidget {
  const StudyFlutterApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    /// Đọc router từ Riverpod để router có thể tự phản ứng theo auth state.
    /// Khi trạng thái đăng nhập đổi, router sẽ kiểm tra redirect lại.
    final router = ref.watch(appRouterProvider);

    /// MaterialApp.router dùng cho app có route phức tạp hơn home screen đơn giản.
    /// Ở đây go_router quản lý các màn: splash, đăng ký, đăng nhập, quản lý.
    return MaterialApp.router(
      title: 'Study Flutter',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      routerConfig: router,
    );
  }
}
