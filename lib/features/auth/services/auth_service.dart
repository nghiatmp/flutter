import '../../../core/constants/storage_keys.dart';
import '../../../core/storage/local_storage.dart';
import '../models/user_model.dart';

/// AuthService chịu trách nhiệm xử lý nghiệp vụ đăng ký/đăng nhập.
/// Provider sẽ gọi service này, còn màn hình không thao tác trực tiếp với storage.
class AuthService {
  AuthService(this._storage);

  final LocalStorage _storage;

  /// Đăng ký tài khoản:
  /// 1. Chuyển user thành JSON.
  /// 2. Lưu vào local storage.
  /// 3. Đặt isLoggedIn = false để bắt người dùng đăng nhập sau khi đăng ký.
  Future<void> register(UserModel user) async {
    await _storage.setString(StorageKeys.user, user.toJson());
    await _storage.setBool(StorageKeys.isLoggedIn, false);
  }

  /// Đọc user đã đăng ký từ local storage.
  /// Nếu chưa đăng ký thì trả về null.
  Future<UserModel?> getRegisteredUser() async {
    final rawUser = await _storage.getString(StorageKeys.user);
    if (rawUser == null) return null;
    return UserModel.fromJson(rawUser);
  }

  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    /// Bước 1: lấy user đã đăng ký.
    /// Vì đây là demo local auth, app chỉ có một user được lưu trong máy.
    final user = await getRegisteredUser();
    if (user == null) {
      throw Exception('Bạn chưa đăng ký tài khoản');
    }

    /// Bước 2: so khớp email và password người dùng nhập với dữ liệu local.
    /// Nếu sai thì ném lỗi để màn hình hiển thị SnackBar.
    final isValid = user.email == email && user.password == password;
    if (!isValid) {
      throw Exception('Email hoặc mật khẩu không đúng');
    }

    /// Bước 3: đăng nhập thành công thì lưu session local.
    /// Lần sau mở app, authProvider sẽ đọc flag này để vào thẳng màn quản lý.
    await _storage.setBool(StorageKeys.isLoggedIn, true);
    return user;
  }

  /// Kiểm tra trạng thái login đã lưu.
  /// Hàm này dùng khi app vừa mở để phục hồi session.
  Future<bool> isLoggedIn() {
    return _storage.getBool(StorageKeys.isLoggedIn);
  }

  /// Logout chỉ cần đặt isLoggedIn = false.
  /// User đăng ký vẫn được giữ lại để có thể đăng nhập lại.
  Future<void> logout() async {
    await _storage.setBool(StorageKeys.isLoggedIn, false);
  }
}
