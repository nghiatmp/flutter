import 'package:permission_handler/permission_handler.dart';

/// Service chuyên xử lý permission.
/// Tách riêng khỏi màn hình để UI chỉ quan tâm "được phép hay chưa",
/// còn chi tiết request quyền nằm ở đây.
class PermissionService {
  /// Request quyền truy cập ảnh/thư viện.
  /// iOS thường dùng Permission.photos.
  /// Android đời mới có READ_MEDIA_IMAGES, Android đời cũ có READ_EXTERNAL_STORAGE.
  /// Vì vậy demo thử photos trước, nếu chưa được thì fallback sang storage.
  Future<bool> requestPhotoPermission() async {
    final photosStatus = await Permission.photos.request();

    if (photosStatus.isGranted || photosStatus.isLimited) {
      return true;
    }

    final storageStatus = await Permission.storage.request();
    return storageStatus.isGranted;
  }
}
