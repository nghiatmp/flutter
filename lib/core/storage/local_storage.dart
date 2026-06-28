import 'package:shared_preferences/shared_preferences.dart';

/// Lớp bọc shared_preferences.
/// Mục tiêu là các feature không phụ thuộc trực tiếp vào plugin,
/// giúp code dễ test và sau này có thể đổi sang storage khác.
class LocalStorage {
  /// Lưu chuỗi vào local storage.
  /// Dùng cho dữ liệu JSON như user hoặc danh sách task.
  Future<void> setString(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, value);
  }

  /// Đọc chuỗi từ local storage.
  /// Trả về null nếu key chưa từng được lưu.
  Future<String?> getString(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(key);
  }

  /// Lưu giá trị boolean.
  /// Trong app này dùng để lưu trạng thái đã đăng nhập hay chưa.
  Future<void> setBool(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  /// Đọc boolean từ local storage.
  /// Nếu chưa có dữ liệu thì mặc định là false để app an toàn hơn.
  Future<bool> getBool(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(key) ?? false;
  }

  /// Xóa dữ liệu theo key.
  /// Có thể dùng cho logout hoặc reset dữ liệu demo.
  Future<void> remove(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(key);
  }
}
