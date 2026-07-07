import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/app_constants.dart';

/// Provider tạo ApiClient dùng chung cho service/repository.
final apiClientProvider = Provider<ApiClient>((ref) => ApiClient());

/// ApiClient là nơi cấu hình HTTP client dùng chung toàn app.
/// Màn hình không gọi Dio trực tiếp, mà đi qua repository/service để code dễ bảo trì.
class ApiClient {
  ApiClient()
    : dio = Dio(
        BaseOptions(
          /// Base URL backend NestJS.
          /// Khi gọi API chỉ cần truyền path như "/posts", không lặp lại domain.
          baseUrl: AppConstants.apiBaseUrl,

          /// Timeout giúp app không chờ vô hạn nếu mạng lỗi hoặc server chậm.
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),

          /// Header mặc định báo cho server biết app mong muốn nhận JSON.
          headers: const {'Accept': 'application/json'},
        ),
      ) {
    /// Interceptor dùng để log request/response khi debug.
    /// responseBody để false để console không bị quá dài trong demo.
    dio.interceptors.add(
      LogInterceptor(requestBody: true, responseBody: false),
    );
  }

  final Dio dio;

  /// Hàm GET dùng chung.
  /// queryParameters dành cho các API có filter, paging, search...
  Future<Response<dynamic>> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    String? accessToken,
  }) {
    return dio.get(
      path,
      queryParameters: queryParameters,
      options: _authOptions(accessToken),
    );
  }

  Future<Response<dynamic>> post(
    String path, {
    Object? data,
    String? accessToken,
  }) {
    return dio.post(path, data: data, options: _authOptions(accessToken));
  }

  Future<Response<dynamic>> patch(
    String path, {
    Object? data,
    String? accessToken,
  }) {
    return dio.patch(path, data: data, options: _authOptions(accessToken));
  }

  Future<Response<dynamic>> delete(String path, {String? accessToken}) {
    return dio.delete(path, options: _authOptions(accessToken));
  }

  Options? _authOptions(String? accessToken) {
    if (accessToken == null || accessToken.isEmpty) return null;
    return Options(headers: {'Authorization': 'Bearer $accessToken'});
  }
}
