import 'package:dio/dio.dart';

class NetworkError {
  const NetworkError._();

  static bool isOffline(Object error) {
    if (error is! DioException) {
      final message = error.toString().toLowerCase();
      return message.contains('socketexception') ||
          message.contains('connection refused') ||
          message.contains('network is unreachable') ||
          message.contains('failed host lookup');
    }

    return switch (error.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.receiveTimeout ||
      DioExceptionType.connectionError => true,
      _ => false,
    };
  }
}
