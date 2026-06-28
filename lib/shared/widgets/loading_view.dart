import 'package:flutter/material.dart';

/// Widget loading dùng chung khi app đang xử lý hoặc đang gọi API.
class LoadingView extends StatelessWidget {
  const LoadingView({super.key, this.message = 'Đang tải dữ liệu...'});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        /// mainAxisSize.min giúp loading chỉ chiếm vừa nội dung,
        /// sau đó Center sẽ đặt nó vào giữa vùng cha.
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 12),
          Text(message),
        ],
      ),
    );
  }
}
