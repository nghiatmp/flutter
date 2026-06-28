import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../models/post_model.dart';

/// Provider tạo ApiClient dùng chung cho các repository.
final apiClientProvider = Provider<ApiClient>((ref) => ApiClient());

/// Provider tạo repository xử lý API post.
final postRepositoryProvider = Provider<PostRepository>((ref) {
  return PostRepository(ref.watch(apiClientProvider));
});

/// FutureProvider tự quản lý trạng thái loading/data/error khi gọi API.
/// Màn hình chỉ cần posts.when(...) để render UI tương ứng.
final postsProvider = FutureProvider<List<PostModel>>((ref) async {
  return ref.watch(postRepositoryProvider).fetchPosts();
});

/// Repository là lớp trung gian giữa API client và UI/provider.
/// UI không biết chi tiết endpoint hoặc parse JSON, chỉ gọi fetchPosts().
class PostRepository {
  PostRepository(this._apiClient);

  final ApiClient _apiClient;

  /// Gọi API GET /posts từ jsonplaceholder.
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
}
