import 'package:flutter/material.dart';

/// Button dùng chung toàn app.
/// Tách ra để các màn hình dùng cùng style, cùng cách hiển thị loading và icon.
class CustomButton extends StatelessWidget {
  const CustomButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    /// Nếu đang loading thì hiển thị CircularProgressIndicator.
    /// Nếu không loading thì hiển thị icon + label.
    final child = isLoading
        ? const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 20),
                const SizedBox(width: 8),
              ],
              Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
            ],
          );

    return ElevatedButton(
      /// Khi loading, disable nút để tránh người dùng bấm nhiều lần.
      onPressed: isLoading ? null : onPressed,
      child: child,
    );
  }
}
