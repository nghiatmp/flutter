/// Model dữ liệu lấy từ API bên thứ ba jsonplaceholder.
/// App chỉ cần id, title và body để demo hiển thị ListTile.
class PostModel {
  const PostModel({required this.id, required this.title, required this.body});

  final int id;
  final String title;
  final String body;

  /// Parse dữ liệu dạng Map từ API thành object Dart.
  factory PostModel.fromMap(Map<String, dynamic> map) {
    return PostModel(
      id: map['id'] as int,
      title: map['title'] as String,
      body: map['body'] as String,
    );
  }
}
