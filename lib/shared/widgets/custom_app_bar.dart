import 'package:flutter/material.dart';

/// AppBar dùng chung.
/// Khi nhiều màn hình cùng dùng app bar, tách widget giúp đồng bộ title/actions/style.
class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  const CustomAppBar({
    super.key,
    required this.title,
    this.actions,
    this.showBackButton = false,
  });

  final String title;
  final List<Widget>? actions;
  final bool showBackButton;

  @override
  Widget build(BuildContext context) {
    return AppBar(
      /// showBackButton cho phép bật/tắt nút back theo từng màn.
      automaticallyImplyLeading: showBackButton,
      title: Text(title),
      centerTitle: false,
      actions: actions,
    );
  }

  @override
  /// PreferredSizeWidget yêu cầu khai báo chiều cao app bar.
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
