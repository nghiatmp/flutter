import 'package:flutter/material.dart';

import '../models/task_model.dart';

/// Widget hiển thị một task trong danh sách.
/// Nhận callback onEdit/onDelete từ màn cha để widget chỉ lo phần giao diện.
class TaskItem extends StatelessWidget {
  const TaskItem({
    super.key,
    required this.task,
    required this.onEdit,
    required this.onDelete,
  });

  final TaskModel task;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        /// Nếu task có ảnh thì đổi icon sang image để người dùng biết task đã gắn ảnh.
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          child: Icon(
            task.imagePath == null ? Icons.task_alt : Icons.image_outlined,
            color: Theme.of(context).colorScheme.onPrimaryContainer,
          ),
        ),
        title: Text(task.title, maxLines: 1, overflow: TextOverflow.ellipsis),

        /// Giới hạn mô tả 2 dòng để list không bị quá dài.
        subtitle: Text(
          task.description,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Wrap(
          spacing: 4,
          children: [
            IconButton(
              /// Gọi callback sửa do màn cha truyền vào.
              tooltip: 'Sửa',
              onPressed: onEdit,
              icon: const Icon(Icons.edit_outlined),
            ),
            IconButton(
              /// Gọi callback xóa do màn cha truyền vào.
              tooltip: 'Xóa',
              onPressed: onDelete,
              icon: const Icon(Icons.delete_outline),
            ),
          ],
        ),
      ),
    );
  }
}
