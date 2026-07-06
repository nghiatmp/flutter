import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/permissions/permission_service.dart';
import '../../../core/utils/app_snackbar.dart';
import '../../../shared/widgets/custom_app_bar.dart';
import '../../../shared/widgets/empty_view.dart';
import '../../../shared/widgets/loading_view.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/task_model.dart';
import '../providers/task_provider.dart';
import '../repositories/post_repository.dart';
import '../widgets/task_form.dart';
import '../widgets/task_item.dart';

/// Màn quản lý sau khi đăng nhập.
/// Màn này gom nhiều kỹ thuật quan trọng:
/// - đọc global auth state để hiển thị user
/// - CRUD task bằng Riverpod
/// - lưu task local storage qua TaskNotifier
/// - check permission và chọn ảnh
/// - gọi API GET bên thứ ba bằng FutureProvider
class ManagementScreen extends ConsumerStatefulWidget {
  const ManagementScreen({super.key});

  @override
  ConsumerState<ManagementScreen> createState() => _ManagementScreenState();
}

class _ManagementScreenState extends ConsumerState<ManagementScreen> {
  /// ImagePicker mở thư viện ảnh của thiết bị.
  final _picker = ImagePicker();

  /// PermissionService kiểm tra quyền trước khi mở thư viện ảnh.
  final _permissionService = PermissionService();

  /// Ảnh được chọn cho form thêm mới.
  /// Khi thêm task xong sẽ reset về null.
  String? _selectedImagePath;

  /// Hàm chọn ảnh dùng chung cho cả thêm mới và chỉnh sửa.
  /// Trả về đường dẫn ảnh nếu chọn thành công, trả về null nếu hủy hoặc chưa có quyền.
  Future<String?> _pickImage() async {
    /// Bước 1: request/check quyền truy cập ảnh.
    final hasPermission = await _permissionService.requestPhotoPermission();
    if (!mounted) return null;

    /// Bước 2: nếu không có quyền thì báo lỗi và dừng.
    if (!hasPermission) {
      AppSnackbar.show(
        context,
        'Bạn cần cấp quyền truy cập ảnh để upload ảnh.',
        isError: true,
      );
      return null;
    }

    /// Bước 3: đã có quyền thì mở thư viện ảnh.
    /// image_picker trả về XFile, app chỉ lưu path để demo.
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    return pickedFile?.path;
  }

  /// Chọn ảnh cho form thêm mới.
  /// Sau khi chọn, lưu path vào state local của màn để truyền xuống TaskForm.
  Future<void> _pickImageForCreate() async {
    final path = await _pickImage();
    if (path == null) return;

    /// setState làm màn hình build lại để nút chọn ảnh đổi sang "Đã chọn ảnh".
    setState(() => _selectedImagePath = path);
    if (!mounted) return;
    AppSnackbar.show(context, 'Đã chọn ảnh cho công việc mới.');
  }

  /// Đăng xuất khỏi app:
  /// 1. Gọi authProvider để cập nhật local storage và global state.
  /// 2. Điều hướng về màn login.
  Future<void> _logout() async {
    await ref.read(authProvider.notifier).logout();
    if (!mounted) return;
    context.go('/login');
  }

  /// Mở bottom sheet để chỉnh sửa task.
  /// Dùng cùng TaskForm với form thêm mới, nhưng truyền initialTask để form biết đang edit.
  void _openEditSheet(TaskModel task) {
    /// Biến local lưu ảnh đang chọn trong bottom sheet.
    /// StatefulBuilder giúp chỉ rebuild nội dung bottom sheet khi đổi ảnh.
    var editingImagePath = task.imagePath;

    showModalBottomSheet<void>(
      context: context,

      /// isScrollControlled giúp bottom sheet nâng lên khi bàn phím mở.
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
              ),
              child: TaskForm(
                initialTask: task,
                imagePath: editingImagePath,
                onPickImage: () async {
                  /// Khi sửa task, chọn ảnh mới và cập nhật state riêng của bottom sheet.
                  final path = await _pickImage();
                  if (path == null) return;
                  setSheetState(() => editingImagePath = path);
                },
                onSubmit: (title, description) async {
                  /// Khi bấm lưu, tạo task mới từ task cũ bằng copyWith.
                  /// Sau đó gọi TaskNotifier.updateTask để cập nhật global task state.
                  await ref
                      .read(taskProvider.notifier)
                      .updateTask(
                        task.copyWith(
                          title: title,
                          description: description,
                          imagePath: editingImagePath,
                        ),
                      );
                  if (!mounted || !context.mounted) return;

                  /// Đóng bottom sheet và báo thành công.
                  Navigator.of(context).pop();
                  AppSnackbar.show(this.context, 'Đã cập nhật công việc.');
                },
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    /// Đọc user hiện tại từ global auth state.
    final authState = ref.watch(authProvider);

    /// Đọc danh sách task từ global task state.
    /// Khi add/update/delete, provider đổi state và ListView tự rebuild.
    final tasks = ref.watch(taskProvider);

    /// Gọi API GET /posts.
    /// posts là AsyncValue nên có 3 trạng thái: loading, data, error.
    final posts = ref.watch(postsProvider);

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Quản lý',
        actions: [
          IconButton(
            tooltip: 'Đăng xuất',
            onPressed: _logout,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            /// Kéo để refresh sẽ hủy cache FutureProvider và gọi lại API.
            ref.invalidate(postsProvider);
            try {
              await ref.read(postsProvider.future);
            } catch (_) {
              /// Nếu API lỗi, UI error state bên dưới sẽ hiển thị.
            }
          },
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _UserHeader(userName: authState.user?.fullName ?? 'Người dùng'),
              const SizedBox(height: 16),
              TaskForm(
                imagePath: _selectedImagePath,
                onPickImage: _pickImageForCreate,
                onSubmit: (title, description) async {
                  /// Submit form thêm mới:
                  /// lấy title/description từ TaskForm và ảnh đã chọn từ _selectedImagePath.
                  await ref
                      .read(taskProvider.notifier)
                      .addTask(
                        title: title,
                        description: description,
                        imagePath: _selectedImagePath,
                      );

                  /// Reset ảnh đã chọn để form tiếp theo bắt đầu sạch.
                  setState(() => _selectedImagePath = null);
                  if (!context.mounted) return;
                  AppSnackbar.show(context, 'Đã thêm công việc mới.');
                },
              ),
              const SizedBox(height: 18),
              Text(
                'Danh sách công việc',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              if (tasks.isEmpty)
                /// Empty state khi chưa có task nào.
                const SizedBox(
                  height: 180,
                  child: EmptyView(message: 'Chưa có công việc nào.'),
                )
              else
                /// Render danh sách task bằng ListView.
                /// Mỗi item có action sửa và xóa.
                ...tasks.map(
                  (task) => TaskItem(
                    task: task,
                    onEdit: () => _openEditSheet(task),
                    onDelete: () async {
                      /// Xóa task theo id và lưu lại local storage trong TaskNotifier.
                      await ref.read(taskProvider.notifier).deleteTask(task.id);
                      if (!context.mounted) return;
                      AppSnackbar.show(context, 'Đã xóa công việc.');
                    },
                  ),
                ),
              const SizedBox(height: 18),
              Text(
                'Dữ liệu API bên thứ ba',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              posts.when(
                /// Khi API thành công, render danh sách bài viết demo.
                data: (items) => Column(
                  children: items
                      .map(
                        (post) => Card(
                          child: ListTile(
                            leading: CircleAvatar(child: Text('${post.id}')),
                            title: Text(
                              post.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Text(
                              post.body,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),

                /// Khi API lỗi, hiển thị card lỗi và nút tải lại.
                error: (error, stackTrace) => Card(
                  child: ListTile(
                    leading: const Icon(Icons.wifi_off_outlined),
                    title: const Text('Không tải được API demo'),
                    subtitle: Text(error.toString()),
                    trailing: IconButton(
                      tooltip: 'Tải lại',
                      onPressed: () => ref.invalidate(postsProvider),
                      icon: const Icon(Icons.refresh),
                    ),
                  ),
                ),

                /// Khi API đang tải, hiển thị loading view.
                loading: () =>
                    const SizedBox(height: 160, child: LoadingView()),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Header nhỏ hiển thị tên user đang đăng nhập.
/// Tách thành widget riêng để ManagementScreen dễ đọc hơn.
class _UserHeader extends StatelessWidget {
  const _UserHeader({required this.userName});

  final String userName;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: Theme.of(context).colorScheme.primary,
              child: Text(
                userName.isEmpty ? 'U' : userName[0].toUpperCase(),
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimary,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Xin chào'),
                  Text(
                    userName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
