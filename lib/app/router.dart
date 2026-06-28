import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/providers/auth_provider.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/auth/screens/register_screen.dart';
import '../features/auth/screens/splash_screen.dart';
import '../features/management/screens/management_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  /// Theo dõi auth state để quyết định người dùng được đi tới màn nào.
  /// Ví dụ: chưa đăng nhập thì không cho vào /management.
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final path = state.uri.path;
      final isAuthPage = path == '/login' || path == '/register' || path == '/';

      /// Khi app vừa mở, authProvider cần đọc local storage trước.
      /// Nếu chưa đọc xong thì giữ người dùng ở splash screen (/).
      if (!authState.isReady) {
        return path == '/' ? null : '/';
      }

      /// Sau khi đọc xong local storage:
      /// - Nếu đã đăng nhập thì vào màn quản lý.
      /// - Nếu chưa đăng nhập thì vào màn đăng ký để bắt đầu flow học tập.
      if (path == '/') {
        return authState.isLoggedIn ? '/management' : '/register';
      }

      /// Nếu đã đăng nhập mà quay lại login/register thì tự chuyển về màn quản lý.
      if (authState.isLoggedIn && isAuthPage) {
        return '/management';
      }

      /// Nếu chưa đăng nhập mà cố mở màn quản lý thì bắt đăng nhập trước.
      if (!authState.isLoggedIn && path == '/management') {
        return '/login';
      }

      return null;
    },
    routes: [
      GoRoute(path: '/', builder: (context, state) => const SplashScreen()),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/management',
        builder: (context, state) => const ManagementScreen(),
      ),
    ],
  );
});
