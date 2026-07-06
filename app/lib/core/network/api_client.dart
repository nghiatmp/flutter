import 'package:dio/dio.dart';

/// ApiClient là nơi cấu hình HTTP client dùng chung toàn app.
/// Màn hình không gọi Dio trực tiếp, mà đi qua repository/service để code dễ bảo trì.
class ApiClient {
  ApiClient()
    : dio = Dio(
        BaseOptions(
          /// Base URL cố định cho API bên thứ ba.
          /// Khi gọi API chỉ cần truyền path như "/posts", không lặp lại domain.
          baseUrl: 'https://jsonplaceholder.typicode.com',

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
  }) {
    return dio.get(path, queryParameters: queryParameters);
  }
}
