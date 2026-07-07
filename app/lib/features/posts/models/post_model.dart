/// Model dữ liệu bài viết lấy từ backend.
/// App hiển thị id, title, body và ảnh đã chọn nếu có.
class PostModel {
  const PostModel({
    required this.id,
    required this.title,
    required this.body,
    this.imagePath,
  });

  final String id;
  final String title;
  final String body;
  final String? imagePath;

  /// Parse dữ liệu dạng Map từ API thành object Dart.
  factory PostModel.fromMap(Map<String, dynamic> map) {
    return PostModel(
      id: map['id'].toString(),
      title: map['title'] as String? ?? '',
      body: map['body'] as String? ?? '',
      imagePath: map['imagePath'] as String?,
    );
  }
}
