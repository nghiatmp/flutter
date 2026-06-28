import 'package:flutter/material.dart';

import '../../../shared/widgets/loading_view.dart';

/// Màn hình tạm thời khi app đang kiểm tra session trong local storage.
/// Router sẽ tự chuyển sang đăng ký, đăng nhập hoặc quản lý sau khi authProvider sẵn sàng.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: LoadingView(message: 'Đang kiểm tra phiên đăng nhập...'),
    );
  }
}
