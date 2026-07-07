import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/settings/providers/settings_provider.dart';

final appStringsProvider = Provider<AppStrings>((ref) {
  final locale = ref.watch(settingsProvider).locale;
  return AppStrings(locale.languageCode);
});

class AppStrings {
  const AppStrings(this.languageCode);

  final String languageCode;

  bool get isEnglish => languageCode == 'en';

  String get appName => 'Study Flutter';
  String get home => isEnglish ? 'Home' : 'Home';
  String get posts => isEnglish ? 'Posts' : 'Posts';
  String get createPost => isEnglish ? 'Create post' : 'Tạo bài viết';
  String get postTitle => isEnglish ? 'Title' : 'Tiêu đề';
  String get postContent => isEnglish ? 'Content' : 'Nội dung';
  String get savePost => isEnglish ? 'Save post' : 'Lưu bài viết';
  String get postCreated => isEnglish ? 'Post created.' : 'Đã tạo bài viết.';
  String get chooseImage => isEnglish ? 'Choose image' : 'Chọn ảnh';
  String get imageSelected => isEnglish ? 'Image selected' : 'Đã chọn ảnh';
  String get photoPermissionRequired => isEnglish
      ? 'Photo permission is required.'
      : 'Bạn cần cấp quyền truy cập ảnh.';
  String get account => isEnglish ? 'Account' : 'Account';
  String get settings => isEnglish ? 'Settings' : 'Cài đặt';
  String get notifications => isEnglish ? 'Notifications' : 'Thông báo';
  String get profile => isEnglish ? 'Profile' : 'Hồ sơ cá nhân';
  String get security => isEnglish ? 'Security' : 'Bảo mật';
  String get appearance => isEnglish ? 'Appearance' : 'Giao diện';
  String get language => isEnglish ? 'Language' : 'Ngôn ngữ';
  String get aboutApp => isEnglish ? 'About app' : 'Thông tin app';
  String get system => isEnglish ? 'System' : 'Theo hệ thống';
  String get light => isEnglish ? 'Light' : 'Sáng';
  String get dark => isEnglish ? 'Dark' : 'Tối';
  String get vietnamese => isEnglish ? 'Vietnamese' : 'Tiếng Việt';
  String get english => 'English';
  String get notificationsSetting => isEnglish ? 'Notifications' : 'Thông báo';
  String get themeAndColors =>
      isEnglish ? 'Theme and colors' : 'Theme và màu sắc';
  String get hello => isEnglish ? 'Hello' : 'Xin chào';
  String helloUser(String name) =>
      isEnglish ? 'Hello, $name' : 'Xin chào, $name';
  String get todayOverview =>
      isEnglish ? 'Today overview' : 'Tổng quan học tập hôm nay';
  String get activeTracking => isEnglish ? 'Tracking' : 'Đang theo dõi';
  String get backendPosts => isEnglish ? 'Backend posts' : 'Bài viết backend';
  String postCount(int count) => isEnglish ? '$count posts' : '$count bài viết';
  String get cannotLoadData =>
      isEnglish ? 'Could not load data' : 'Chưa tải được dữ liệu';
  String get backendPostList =>
      isEnglish ? 'Posts from backend' : 'Bài viết từ backend';
  String get emptyPostList =>
      isEnglish ? 'No posts yet.' : 'Chưa có bài viết nào.';
  String get cannotLoadPosts =>
      isEnglish ? 'Could not load posts' : 'Không tải được bài viết';
  String get reload => isEnglish ? 'Reload' : 'Tải lại';
  String get tryAgain => isEnglish ? 'Try again' : 'Thử lại';
  String get noConnectionTitle =>
      isEnglish ? 'No internet connection' : 'Mất kết nối mạng';
  String get noConnectionMessage => isEnglish
      ? 'Please check Wi-Fi or mobile data, then try again.'
      : 'Vui lòng kiểm tra Wi-Fi hoặc dữ liệu di động rồi thử lại.';
  String get postDetail => isEnglish ? 'Post detail' : 'Chi tiết bài viết';
  String get notFoundPost =>
      isEnglish ? 'Post not found.' : 'Không tìm thấy bài viết.';
  String get selectedImage => isEnglish ? 'Selected image' : 'Ảnh đã chọn';
  String get personalProfile =>
      isEnglish ? 'Personal profile' : 'Hồ sơ cá nhân';
  String get fullName => isEnglish ? 'Full name' : 'Họ tên';
  String get email => 'Email';
  String get gender => isEnglish ? 'Gender' : 'Giới tính';
  String get city => isEnglish ? 'City' : 'Thành phố';
  String get hobbies => isEnglish ? 'Hobbies' : 'Sở thích';
  String get noData => isEnglish ? 'No data' : 'Chưa có dữ liệu';
  String get accountSecurity =>
      isEnglish ? 'Account security' : 'Bảo mật tài khoản';
  String get logout => isEnglish ? 'Log out' : 'Đăng xuất';
  String get logoutTitle => isEnglish ? 'Log out?' : 'Đăng xuất?';
  String get logoutMessage => isEnglish
      ? 'You will need to log in again to continue.'
      : 'Bạn sẽ cần đăng nhập lại để tiếp tục.';
  String get cancel => isEnglish ? 'Cancel' : 'Huỷ';
  String get loggedOut => isEnglish ? 'Logged out.' : 'Đã đăng xuất.';
  String get postChart => isEnglish ? 'Post chart' : 'Biểu đồ bài viết';
  String get postsChartCenter => isEnglish ? 'Posts' : 'Bài viết';
  String get imageUsageOverview =>
      isEnglish ? 'Image usage overview' : 'Tổng quan ảnh trong bài viết';
  String imagePostCount(int count) =>
      isEnglish ? 'With image: $count' : 'Có ảnh: $count';
  String textPostCount(int count) =>
      isEnglish ? 'No image: $count' : 'Không ảnh: $count';
  String get login => isEnglish ? 'Log in' : 'Đăng nhập';
  String get password => isEnglish ? 'Password' : 'Mật khẩu';
  String get loginSubtitle => isEnglish
      ? 'Use your registered account to continue.'
      : 'Dùng tài khoản vừa đăng ký để vào màn quản lý.';
  String get loginSuccess =>
      isEnglish ? 'Logged in successfully' : 'Đăng nhập thành công';
  String get enteringApp =>
      isEnglish ? 'Taking you into the app...' : 'Đang đưa bạn vào app...';
  String get registerSuccess => isEnglish
      ? 'Registered successfully. Please log in.'
      : 'Đăng ký thành công. Hãy đăng nhập.';
  String get goRegister =>
      isEnglish ? 'No account? Register' : 'Chưa có tài khoản? Đăng ký';
}
