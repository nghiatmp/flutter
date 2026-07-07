import 'package:chucker_flutter/chucker_flutter.dart';
import 'package:flutter/material.dart';

/// Nút nổi hình con bọ để mở màn hình xem lịch sử request/response
/// (Chucker) ngay trong app. Kéo thả được để không che nội dung.
class ChuckerBugButton extends StatefulWidget {
  const ChuckerBugButton({super.key});

  @override
  State<ChuckerBugButton> createState() => _ChuckerBugButtonState();
}

class _ChuckerBugButtonState extends State<ChuckerBugButton> {
  Offset _offset = const Offset(16, 100);

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);

    /// size có thể là 0 ở khung hình đầu tiên (trước khi layout xong).
    /// Dùng max(0, ...) để cận trên luôn >= cận dưới, tránh clamp() ném lỗi.
    final maxX = (size.width - 56).clamp(0.0, double.infinity);
    final maxY = (size.height - 56).clamp(0.0, double.infinity);

    return Positioned(
      left: _offset.dx.clamp(0, maxX),
      top: _offset.dy.clamp(0, maxY),
      child: GestureDetector(
        onPanUpdate: (details) {
          setState(() => _offset += details.delta);
        },
        child: FloatingActionButton(
          heroTag: 'chucker_bug_button',
          backgroundColor: Colors.redAccent,
          onPressed: ChuckerFlutter.showChuckerScreen,
          child: const Icon(Icons.bug_report, color: Colors.white),
        ),
      ),
    );
  }
}
