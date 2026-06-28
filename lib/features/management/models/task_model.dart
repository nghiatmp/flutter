import 'dart:convert';

/// Model biểu diễn một công việc trong màn quản lý.
/// Task được lưu local nên cần có hàm chuyển qua lại giữa object và JSON.
class TaskModel {
  const TaskModel({
    required this.id,
    required this.title,
    required this.description,
    this.imagePath,
  });

  final String id;
  final String title;
  final String description;
  final String? imagePath;

  /// copyWith dùng khi sửa task.
  /// Thay vì sửa trực tiếp object cũ, ta tạo object mới với một vài field được cập nhật.
  /// Cách này phù hợp với state bất biến trong Riverpod.
  TaskModel copyWith({
    String? title,
    String? description,
    String? imagePath,
    bool clearImage = false,
  }) {
    return TaskModel(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      imagePath: clearImage ? null : imagePath ?? this.imagePath,
    );
  }

  /// Chuyển TaskModel thành Map để encode JSON.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'imagePath': imagePath,
    };
  }

  /// Tạo TaskModel từ Map sau khi decode JSON từ local storage.
  factory TaskModel.fromMap(Map<String, dynamic> map) {
    return TaskModel(
      id: map['id'] as String,
      title: map['title'] as String,
      description: map['description'] as String,
      imagePath: map['imagePath'] as String?,
    );
  }

  /// Encode một task thành JSON string.
  String toJson() => jsonEncode(toMap());

  /// Decode JSON string thành TaskModel.
  factory TaskModel.fromJson(String source) {
    return TaskModel.fromMap(jsonDecode(source) as Map<String, dynamic>);
  }
}
