import 'package:flutter/material.dart';

/// Widget hiển thị trạng thái rỗng.
/// Ví dụ: danh sách post chưa có dữ liệu.
class EmptyView extends StatelessWidget {
  const EmptyView({
    super.key,
    required this.message,
    this.icon = Icons.inbox_outlined,
  });

  final String message;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            /// Icon giúp người dùng nhận biết đây là trạng thái trống chứ không phải lỗi.
            Icon(icon, size: 44, color: Colors.grey.shade500),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
        ),
      ),
    );
  }
}
