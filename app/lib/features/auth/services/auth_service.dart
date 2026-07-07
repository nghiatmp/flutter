import 'package:dio/dio.dart';

import '../../../core/constants/storage_keys.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/storage/local_storage.dart';
import '../models/user_model.dart';

/// AuthService chịu trách nhiệm xử lý nghiệp vụ đăng ký/đăng nhập.
/// Provider sẽ gọi service này, còn màn hình không thao tác trực tiếp với storage.
class AuthService {
  AuthService(this._storage, this._apiClient);

  final LocalStorage _storage;
  final ApiClient _apiClient;

  /// Đăng ký tài khoản:
  /// 1. Gửi dữ liệu lên backend.
  /// 2. Cache user gần nhất để màn login có thể tự điền.
  /// 3. Vẫn để isLoggedIn = false để người dùng đi qua màn đăng nhập.
  Future<void> register(UserModel user) async {
    try {
      await _apiClient.post(ApiEndpoints.authRegister, data: user.toMap());
      await _cacheUser(user);
      await _storage.remove(StorageKeys.accessToken);
      await _storage.setBool(StorageKeys.isLoggedIn, false);
    } on DioException catch (error) {
      throw Exception(_readErrorMessage(error));
    }
  }

  /// Đọc user đã đăng ký từ local storage.
  /// App dùng dữ liệu này để tự điền form login hoặc fallback khi cần.
  Future<UserModel?> getRegisteredUser() async {
    final rawUser = await _storage.getString(StorageKeys.user);
    if (rawUser == null) return null;
    return UserModel.fromJson(rawUser);
  }

  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.authLogin,
        data: {'email': email, 'password': password},
      );
      final body = response.data as Map<String, dynamic>;
      final user = UserModel.fromApi(
        body['user'] as Map<String, dynamic>,
        password: password,
      );
      final accessToken = body['accessToken'] as String;

      await _cacheUser(user);
      await _storage.setString(StorageKeys.accessToken, accessToken);
      await _storage.setBool(StorageKeys.isLoggedIn, true);
      return user;
    } on DioException catch (error) {
      throw Exception(_readErrorMessage(error));
    }
  }

  /// Kiểm tra trạng thái login đã lưu.
  /// Hàm này dùng khi app vừa mở để phục hồi session.
  Future<bool> isLoggedIn() async {
    final accessToken = await getAccessToken();
    final isLoggedIn = await _storage.getBool(StorageKeys.isLoggedIn);
    return isLoggedIn && accessToken != null;
  }

  Future<String?> getAccessToken() {
    return _storage.getString(StorageKeys.accessToken);
  }

  Future<UserModel?> getCurrentUser() async {
    final accessToken = await getAccessToken();
    if (accessToken == null) return null;

    try {
      final response = await _apiClient.get(
        ApiEndpoints.authMe,
        accessToken: accessToken,
      );
      final cachedUser = await getRegisteredUser();
      final user = UserModel.fromApi(
        response.data as Map<String, dynamic>,
        password: cachedUser?.password ?? '',
      );
      await _cacheUser(user);
      return user;
    } on DioException {
      await logout();
      return null;
    }
  }

  /// Logout chỉ cần đặt isLoggedIn = false.
  /// User gần nhất vẫn được giữ lại để form login tự điền.
  Future<void> logout() async {
    await _storage.remove(StorageKeys.accessToken);
    await _storage.setBool(StorageKeys.isLoggedIn, false);
  }

  Future<void> _cacheUser(UserModel user) {
    return _storage.setString(StorageKeys.user, user.toJson());
  }

  String _readErrorMessage(DioException error) {
    final data = error.response?.data;
    if (data is Map<String, dynamic>) {
      final message = data['message'];
      if (message is String) return message;
      if (message is List && message.isNotEmpty) return message.join(', ');
    }
    return 'Không kết nối được backend. Hãy kiểm tra server NestJS.';
  }
}
