import 'package:flutter/material.dart';

/// Nút chọn ảnh dùng trong các form.
/// Widget này không tự request permission, chỉ phát sự kiện onPickImage cho màn cha.
class ImagePickerBox extends StatelessWidget {
  const ImagePickerBox({
    super.key,
    required this.imagePath,
    required this.onPickImage,
    this.emptyLabel = 'Chọn ảnh',
    this.selectedLabel = 'Đã chọn ảnh',
  });

  final String? imagePath;
  final VoidCallback onPickImage;
  final String emptyLabel;
  final String selectedLabel;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPickImage,
      icon: const Icon(Icons.image_outlined),
      label: Text(
        /// Nếu imagePath null nghĩa là chưa chọn ảnh.
        /// Nếu có path thì hiển thị trạng thái đã chọn.
        imagePath == null ? emptyLabel : selectedLabel,
        overflow: TextOverflow.ellipsis,
      ),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(44),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}
