import 'package:flutter/material.dart';

import '../../../core/utils/validators.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../shared/widgets/custom_text_field.dart';
import '../models/task_model.dart';
import 'image_picker_box.dart';

/// Form nhập task được tái sử dụng cho cả thêm mới và chỉnh sửa.
/// Nếu initialTask == null thì form đang ở chế độ thêm mới.
/// Nếu initialTask != null thì form đang ở chế độ cập nhật.
class TaskForm extends StatefulWidget {
  const TaskForm({
    super.key,
    this.initialTask,
    this.imagePath,
    required this.onSubmit,
    required this.onPickImage,
  });

  final TaskModel? initialTask;

  /// imagePath được truyền từ màn cha để form hiển thị trạng thái đã chọn ảnh.
  final String? imagePath;

  /// Callback trả dữ liệu title/description về màn cha.
  /// Màn cha quyết định gọi addTask hay updateTask.
  final void Function(String title, String description) onSubmit;

  /// Callback chọn ảnh được đặt ở màn cha vì màn cha biết permission service.
  final VoidCallback onPickImage;

  @override
  State<TaskForm> createState() => _TaskFormState();
}

class _TaskFormState extends State<TaskForm> {
  /// Form key để validate riêng form task.
  final _formKey = GlobalKey<FormState>();

  /// Dùng late final vì controller cần khởi tạo trong initState
  /// để lấy dữ liệu initialTask khi đang chỉnh sửa.
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;

  @override
  void initState() {
    super.initState();

    /// Nếu đang sửa, input sẽ có sẵn dữ liệu cũ.
    /// Nếu đang thêm mới, text mặc định là null/rỗng.
    _titleController = TextEditingController(text: widget.initialTask?.title);
    _descriptionController = TextEditingController(
      text: widget.initialTask?.description,
    );
  }

  @override
  void dispose() {
    /// Dispose controller khi form bị hủy.
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _submit() {
    /// Validate tiêu đề và mô tả trước khi gửi dữ liệu ra ngoài.
    if (!_formKey.currentState!.validate()) return;

    /// Gửi dữ liệu đã trim về màn cha.
    widget.onSubmit(
      _titleController.text.trim(),
      _descriptionController.text.trim(),
    );

    /// Nếu là form thêm mới thì clear input sau khi thêm thành công.
    /// Form sửa không clear vì bottom sheet sẽ đóng sau khi lưu.
    if (widget.initialTask == null) {
      _titleController.clear();
      _descriptionController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    /// Cờ xác định mode của form để đổi tiêu đề, icon và label nút.
    final isEditing = widget.initialTask != null;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          /// Form này chỉ validate các field bên trong TaskForm.
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                isEditing ? 'Cập nhật công việc' : 'Thêm công việc',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 14),
              CustomTextField(
                controller: _titleController,
                label: 'Tiêu đề',
                prefixIcon: Icons.title,

                /// Tiêu đề là bắt buộc.
                validator: (value) => Validators.required(value, 'Tiêu đề'),
              ),
              const SizedBox(height: 12),
              CustomTextField(
                controller: _descriptionController,
                label: 'Mô tả',
                prefixIcon: Icons.notes_outlined,
                maxLines: 3,

                /// Mô tả là bắt buộc.
                validator: (value) => Validators.required(value, 'Mô tả'),
              ),
              const SizedBox(height: 12),
              ImagePickerBox(
                /// Ưu tiên imagePath từ màn cha, nếu không có thì dùng ảnh cũ của task.
                imagePath: widget.imagePath ?? widget.initialTask?.imagePath,
                onPickImage: widget.onPickImage,
              ),
              const SizedBox(height: 14),
              CustomButton(
                label: isEditing ? 'Lưu thay đổi' : 'Thêm vào danh sách',
                icon: isEditing ? Icons.save_outlined : Icons.add,
                onPressed: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
