import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/localization/app_strings.dart';
import '../../../core/network/network_error.dart';
import '../../../core/permissions/permission_service.dart';
import '../../../core/utils/app_snackbar.dart';
import '../../../shared/widgets/animated_list_item.dart';
import '../../../shared/widgets/custom_app_bar.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../shared/widgets/custom_text_field.dart';
import '../../../shared/widgets/empty_view.dart';
import '../../../shared/widgets/image_picker_box.dart';
import '../../../shared/widgets/loading_view.dart';
import '../../../shared/widgets/no_connection_view.dart';
import '../../posts/repositories/post_repository.dart';

class PostsScreen extends ConsumerWidget {
  const PostsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final posts = ref.watch(postsProvider);
    final strings = ref.watch(appStringsProvider);

    return Scaffold(
      appBar: CustomAppBar(
        title: strings.posts,
        actions: [
          IconButton(
            tooltip: strings.createPost,
            onPressed: () => context.push('/create-post'),
            icon: const Icon(Icons.add_circle_outline),
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(postsProvider);
            await ref.read(postsProvider.future);
          },
          child: posts.when(
            data: (items) {
              if (items.isEmpty) {
                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    SizedBox(
                      height: 260,
                      child: EmptyView(message: strings.emptyPostList),
                    ),
                  ],
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: items.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final post = items[index];
                  return AnimatedListItem(
                    index: index,
                    child: Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          child: Icon(
                            post.imagePath == null
                                ? Icons.article_outlined
                                : Icons.image_outlined,
                          ),
                        ),
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
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => context.push('/posts/${post.id}'),
                      ),
                    ),
                  );
                },
              );
            },
            error: (error, _) {
              if (NetworkError.isOffline(error)) {
                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    SizedBox(
                      height: MediaQuery.of(context).size.height * 0.62,
                      child: NoConnectionView(
                        strings: strings,
                        onRetry: () => ref.invalidate(postsProvider),
                      ),
                    ),
                  ],
                );
              }

              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.error_outline),
                      title: Text(strings.cannotLoadPosts),
                      subtitle: Text(error.toString()),
                      trailing: IconButton(
                        tooltip: strings.reload,
                        onPressed: () => ref.invalidate(postsProvider),
                        icon: const Icon(Icons.refresh),
                      ),
                    ),
                  ),
                ],
              );
            },
            loading: () => const LoadingView(),
          ),
        ),
      ),
    );
  }
}

class CreatePostScreen extends ConsumerStatefulWidget {
  const CreatePostScreen({super.key});

  @override
  ConsumerState<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends ConsumerState<CreatePostScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  final _picker = ImagePicker();
  final _permissionService = PermissionService();
  String? _selectedImagePath;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final strings = ref.read(appStringsProvider);
    final hasPermission = await _permissionService.requestPhotoPermission();
    if (!mounted) return;

    if (!hasPermission) {
      AppSnackbar.show(context, strings.photoPermissionRequired, isError: true);
      return;
    }

    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile == null) return;

    setState(() => _selectedImagePath = pickedFile.path);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    try {
      await ref
          .read(postRepositoryProvider)
          .createPost(
            title: _titleController.text.trim(),
            body: _bodyController.text.trim(),
            imagePath: _selectedImagePath,
          );
      ref.invalidate(postsProvider);
      if (!mounted) return;

      final strings = ref.read(appStringsProvider);
      AppSnackbar.show(context, strings.postCreated);
      context.pop();
    } catch (error) {
      if (!mounted) return;
      AppSnackbar.show(
        context,
        error.toString().replaceFirst('Exception: ', ''),
        isError: true,
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = ref.watch(appStringsProvider);

    return Scaffold(
      appBar: CustomAppBar(title: strings.createPost, showBackButton: true),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  CustomTextField(
                    controller: _titleController,
                    label: strings.postTitle,
                    prefixIcon: Icons.title,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return strings.postTitle;
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  CustomTextField(
                    controller: _bodyController,
                    label: strings.postContent,
                    prefixIcon: Icons.notes_outlined,
                    maxLines: 6,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return strings.postContent;
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  ImagePickerBox(
                    imagePath: _selectedImagePath,
                    onPickImage: _pickImage,
                    emptyLabel: strings.chooseImage,
                    selectedLabel: strings.imageSelected,
                  ),
                  const SizedBox(height: 20),
                  CustomButton(
                    label: strings.savePost,
                    icon: Icons.save_outlined,
                    isLoading: _isSubmitting,
                    onPressed: _submit,
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

class PostDetailScreen extends ConsumerWidget {
  const PostDetailScreen({super.key, required this.postId});

  final String postId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final posts = ref.watch(postsProvider);
    final strings = ref.watch(appStringsProvider);

    return Scaffold(
      appBar: CustomAppBar(title: strings.postDetail, showBackButton: true),
      body: posts.when(
        data: (items) {
          var post = items.isEmpty ? null : items.first;
          for (final item in items) {
            if (item.id == postId) {
              post = item;
              break;
            }
          }
          if (post?.id != postId) post = null;
          if (post == null) {
            return Center(child: Text(strings.notFoundPost));
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                post.title,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              Text(post.body),
              if (post.imagePath != null) ...[
                const SizedBox(height: 16),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.image_outlined),
                    title: Text(strings.selectedImage),
                    subtitle: Text(post.imagePath!),
                  ),
                ),
              ],
            ],
          );
        },
        error: (error, _) {
          if (NetworkError.isOffline(error)) {
            return NoConnectionView(
              strings: strings,
              onRetry: () => ref.invalidate(postsProvider),
            );
          }

          return Center(child: Text(error.toString()));
        },
        loading: () => const LoadingView(),
      ),
    );
  }
}
