import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/providers/auth_provider.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/auth/screens/login_success_screen.dart';
import '../features/auth/screens/register_screen.dart';
import '../features/auth/screens/splash_screen.dart';
import '../features/account/screens/account_screen.dart';
import '../features/home/screens/home_screen.dart';
import '../features/posts/screens/posts_screen.dart';
import '../features/settings/screens/settings_screen.dart';
import '../features/shell/screens/main_shell_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  /// Theo dõi auth state để quyết định người dùng được đi tới màn nào.
  /// Ví dụ: chưa đăng nhập thì không cho vào /management.
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final path = state.uri.path;
      final isAuthPage = path == '/login' || path == '/register' || path == '/';
      final isProtectedPage = !isAuthPage;

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

      /// Nếu chưa đăng nhập mà cố mở màn sau auth thì bắt đăng nhập trước.
      if (!authState.isLoggedIn && isProtectedPage) {
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
        path: '/login-success',
        builder: (context, state) => const LoginSuccessScreen(),
      ),
      GoRoute(
        path: '/management',
        builder: (context, state) => const MainShellScreen(),
      ),
      GoRoute(
        path: '/notifications',
        builder: (context, state) => const NotificationsScreen(),
      ),
      GoRoute(
        path: '/create-post',
        builder: (context, state) => const CreatePostScreen(),
      ),
      GoRoute(
        path: '/posts/create',
        builder: (context, state) => const CreatePostScreen(),
      ),
      GoRoute(
        path: '/posts/:id',
        builder: (context, state) =>
            PostDetailScreen(postId: state.pathParameters['id'] ?? ''),
      ),
      GoRoute(
        path: '/account/profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: '/account/security',
        builder: (context, state) => const AccountSecurityScreen(),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/settings/theme',
        builder: (context, state) => const ThemeSettingsScreen(),
      ),
      GoRoute(
        path: '/settings/language',
        builder: (context, state) => const LanguageSettingsScreen(),
      ),
      GoRoute(
        path: '/settings/about',
        builder: (context, state) => const AboutScreen(),
      ),
    ],
  );
});
