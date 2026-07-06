import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/local_storage.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

/// Provider tạo LocalStorage dùng chung.
/// Khi cần mock storage trong test, có thể override provider này.
final localStorageProvider = Provider<LocalStorage>((ref) => LocalStorage());

/// Provider tạo AuthService.
/// AuthService phụ thuộc LocalStorage, nên lấy storage từ localStorageProvider.
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(ref.watch(localStorageProvider));
});

/// Global auth state của toàn app.
/// Màn hình, router và các feature khác có thể watch provider này để biết user hiện tại.
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.watch(authServiceProvider));
});

/// State lưu toàn bộ thông tin liên quan tới auth.
/// isReady: đã đọc xong local storage chưa.
/// isLoggedIn: user có đang đăng nhập không.
/// user: thông tin user hiện tại nếu có.
class AuthState {
  const AuthState({required this.isReady, required this.isLoggedIn, this.user});

  const AuthState.initial() : isReady = false, isLoggedIn = false, user = null;

  final bool isReady;
  final bool isLoggedIn;
  final UserModel? user;

  /// copyWith giúp cập nhật state bất biến.
  /// clearUser dùng khi logout để xóa user khỏi state.
  AuthState copyWith({
    bool? isReady,
    bool? isLoggedIn,
    UserModel? user,
    bool clearUser = false,
  }) {
    return AuthState(
      isReady: isReady ?? this.isReady,
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
      user: clearUser ? null : user ?? this.user,
    );
  }
}

/// AuthNotifier là nơi thay đổi global auth state.
/// StateNotifier tương tự reducer/action trong Redux nhưng gọn hơn:
/// gọi method -> xử lý service -> gán state mới.
class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier(this._authService) : super(const AuthState.initial()) {
    /// Khi provider được tạo, tự đọc session local để quyết định app vào màn nào.
    loadSession();
  }

  final AuthService _authService;

  /// Load session từ local storage lúc app khởi động.
  /// Sau khi load xong, isReady = true để router bắt đầu redirect.
  Future<void> loadSession() async {
    final isLoggedIn = await _authService.isLoggedIn();
    final user = await _authService.getRegisteredUser();

    state = AuthState(
      isReady: true,
      isLoggedIn: isLoggedIn && user != null,
      user: isLoggedIn ? user : null,
    );
  }

  /// Đăng ký user mới và cập nhật state.
  /// App vẫn để isLoggedIn = false để người dùng đi qua màn login như yêu cầu.
  Future<void> register(UserModel user) async {
    await _authService.register(user);
    state = state.copyWith(isReady: true, isLoggedIn: false, user: user);
  }

  /// Đăng nhập:
  /// 1. AuthService kiểm tra email/password.
  /// 2. Nếu đúng, state chuyển sang isLoggedIn = true.
  /// 3. Router thấy state đổi sẽ cho vào màn quản lý.
  Future<void> login({required String email, required String password}) async {
    final user = await _authService.login(email: email, password: password);
    state = state.copyWith(isReady: true, isLoggedIn: true, user: user);
  }

  /// Đăng xuất:
  /// 1. Xóa flag đăng nhập trong local storage.
  /// 2. Xóa user khỏi global state.
  /// 3. Màn hình gọi context.go('/login') để quay về login.
  Future<void> logout() async {
    await _authService.logout();
    state = state.copyWith(isLoggedIn: false, clearUser: true);
  }
}
