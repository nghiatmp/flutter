import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/services/auth_service.dart';
import '../models/post_model.dart';

/// Provider tạo repository xử lý API post.
final postRepositoryProvider = Provider<PostRepository>((ref) {
  return PostRepository(
    ref.watch(apiClientProvider),
    ref.watch(authServiceProvider),
  );
});

/// FutureProvider tự quản lý trạng thái loading/data/error khi gọi API.
/// Màn hình chỉ cần posts.when(...) để render UI tương ứng.
final postsProvider = FutureProvider<List<PostModel>>((ref) async {
  return ref.watch(postRepositoryProvider).fetchPosts();
});

/// Repository là lớp trung gian giữa API client và UI/provider.
/// UI không biết chi tiết endpoint hoặc parse JSON, chỉ gọi fetchPosts().
class PostRepository {
  PostRepository(this._apiClient, this._authService);

  final ApiClient _apiClient;
  final AuthService _authService;

  /// Gọi API GET /posts từ backend NestJS.
  /// Demo chỉ lấy 5 item đầu để màn hình gọn và dễ quan sát.
  Future<List<PostModel>> fetchPosts() async {
    final response = await _apiClient.get(ApiEndpoints.posts);

    /// response.data từ Dio là dynamic, cần ép về List để map sang PostModel.
    final data = response.data as List<dynamic>;
    return data
        .take(5)
        .map((item) => PostModel.fromMap(item as Map<String, dynamic>))
        .toList();
  }

  Future<PostModel> createPost({
    required String title,
    required String body,
    String? imagePath,
  }) async {
    final accessToken = await _authService.getAccessToken();
    if (accessToken == null) {
      throw Exception('Bạn cần đăng nhập để tạo bài viết');
    }

    final response = await _apiClient.post(
      ApiEndpoints.posts,
      accessToken: accessToken,
      data: {'title': title, 'body': body, 'imagePath': imagePath},
    );

    return PostModel.fromMap(response.data as Map<String, dynamic>);
  }
}
