import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/storage_keys.dart';
import '../../../core/storage/local_storage.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/task_model.dart';

/// Global state cho danh sách công việc.
/// Mọi màn hình/widget có thể watch taskProvider để lấy list task hiện tại.
final taskProvider = StateNotifierProvider<TaskNotifier, List<TaskModel>>((
  ref,
) {
  return TaskNotifier(ref.watch(localStorageProvider));
});

/// TaskNotifier quản lý CRUD cho task:
/// - load từ local storage
/// - thêm task
/// - sửa task
/// - xóa task
/// - lưu lại local storage sau mỗi thay đổi
class TaskNotifier extends StateNotifier<List<TaskModel>> {
  TaskNotifier(this._storage) : super(const []) {
    /// Khi provider được tạo, tự đọc danh sách task đã lưu trước đó.
    loadTasks();
  }

  final LocalStorage _storage;

  /// Đọc danh sách task từ local storage.
  /// Dữ liệu được lưu dạng JSON array, nên cần jsonDecode rồi map từng item.
  Future<void> loadTasks() async {
    final rawTasks = await _storage.getString(StorageKeys.tasks);
    if (rawTasks == null) return;

    final decoded = jsonDecode(rawTasks) as List<dynamic>;
    state = decoded
        .map((item) => TaskModel.fromMap(item as Map<String, dynamic>))
        .toList();
  }

  Future<void> addTask({
    required String title,
    required String description,
    String? imagePath,
  }) async {
    /// Tạo id đơn giản bằng timestamp microseconds.
    /// Với demo local app, cách này đủ để phân biệt task.
    final task = TaskModel(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      title: title,
      description: description,
      imagePath: imagePath,
    );

    /// Thêm task mới lên đầu danh sách để người dùng thấy ngay item vừa tạo.
    state = [task, ...state];
    await _save();
  }

  /// Cập nhật task theo id.
  /// Dùng vòng for để tạo list mới, thay item cần sửa và giữ nguyên các item còn lại.
  Future<void> updateTask(TaskModel updatedTask) async {
    state = [
      for (final task in state)
        if (task.id == updatedTask.id) updatedTask else task,
    ];
    await _save();
  }

  /// Xóa task theo id.
  /// where tạo list mới chỉ gồm các task có id khác id cần xóa.
  Future<void> deleteTask(String id) async {
    state = state.where((task) => task.id != id).toList();
    await _save();
  }

  /// Lưu toàn bộ danh sách task hiện tại vào local storage.
  /// Mỗi lần thêm/sửa/xóa đều gọi _save để dữ liệu không mất khi đóng app.
  Future<void> _save() async {
    final rawTasks = jsonEncode(state.map((task) => task.toMap()).toList());
    await _storage.setString(StorageKeys.tasks, rawTasks);
  }
}
