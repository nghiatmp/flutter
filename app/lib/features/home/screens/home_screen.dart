import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/localization/app_strings.dart';
import '../../../core/network/network_error.dart';
import '../../../shared/widgets/custom_app_bar.dart';
import '../../../shared/widgets/no_connection_view.dart';
import '../../auth/providers/auth_provider.dart';
import '../../posts/repositories/post_repository.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    final posts = ref.watch(postsProvider);
    final strings = ref.watch(appStringsProvider);

    return Scaffold(
      appBar: CustomAppBar(
        title: strings.home,
        actions: [
          IconButton(
            tooltip: strings.notifications,
            onPressed: () => context.push('/notifications'),
            icon: const Icon(Icons.notifications_outlined),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              strings.helloUser(user?.fullName ?? 'bạn'),
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              strings.todayOverview,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _SummaryTile(
                    icon: Icons.article_outlined,
                    label: strings.posts,
                    value: posts.maybeWhen(
                      data: (items) => items.length.toString(),
                      orElse: () => '0',
                    ),
                    color: Theme.of(context).colorScheme.secondaryContainer,
                    foregroundColor: Theme.of(
                      context,
                    ).colorScheme.onSecondaryContainer,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _SummaryTile(
                    icon: Icons.trending_up_outlined,
                    label: strings.activeTracking,
                    value: posts.maybeWhen(
                      data: (items) => items
                          .where((post) => post.imagePath != null)
                          .length
                          .toString(),
                      orElse: () => '0',
                    ),
                    color: Theme.of(context).colorScheme.tertiaryContainer,
                    foregroundColor: Theme.of(
                      context,
                    ).colorScheme.onTertiaryContainer,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            posts.when(
              data: (items) => _PostsChartCard(
                total: items.length,
                withImages: items
                    .where((post) => post.imagePath != null)
                    .length,
                strings: strings,
              ),
              loading: () =>
                  _PostsChartCard(total: 0, withImages: 0, strings: strings),
              error: (error, _) {
                if (NetworkError.isOffline(error)) {
                  return Card(
                    child: SizedBox(
                      height: 260,
                      child: NoConnectionView(
                        strings: strings,
                        compact: true,
                        onRetry: () => ref.invalidate(postsProvider),
                      ),
                    ),
                  );
                }

                return Card(
                  child: ListTile(
                    leading: const Icon(Icons.error_outline),
                    title: Text(strings.cannotLoadData),
                    trailing: IconButton(
                      tooltip: strings.reload,
                      onPressed: () => ref.invalidate(postsProvider),
                      icon: const Icon(Icons.refresh),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            Card(
              child: ListTile(
                leading: const Icon(Icons.add_photo_alternate_outlined),
                title: Text(strings.createPost),
                subtitle: Text(strings.backendPosts),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/create-post'),
              ),
            ),
            Card(
              child: ListTile(
                leading: const Icon(Icons.article_outlined),
                title: Text(strings.backendPosts),
                subtitle: posts.when(
                  data: (items) => Text(strings.postCount(items.length)),
                  error: (_, _) => Text(strings.cannotLoadData),
                  loading: () =>
                      Text(strings.isEnglish ? 'Loading...' : 'Đang tải...'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PostsChartCard extends StatelessWidget {
  const _PostsChartCard({
    required this.total,
    required this.withImages,
    required this.strings,
  });

  final int total;
  final int withImages;
  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    final withoutImages = (total - withImages).clamp(0, total).toInt();
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              strings.postChart,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 14),
            SizedBox(
              height: 130,
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: const Duration(milliseconds: 700),
                curve: Curves.easeOutCubic,
                builder: (context, value, _) {
                  return CustomPaint(
                    painter: _PostsChartPainter(
                      total: total,
                      withImages: withImages,
                      withoutImages: withoutImages,
                      progress: value,
                      primary: colorScheme.primary,
                      secondary: colorScheme.secondary,
                      outline: colorScheme.outline,
                      centerLabel: strings.postsChartCenter,
                      subLabel: strings.imageUsageOverview,
                    ),
                    child: const SizedBox.expand(),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                _ChartLegend(
                  color: colorScheme.primary,
                  label: strings.imagePostCount(withImages),
                ),
                _ChartLegend(
                  color: colorScheme.secondary,
                  label: strings.textPostCount(withoutImages),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ChartLegend extends StatelessWidget {
  const _ChartLegend({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          child: const SizedBox(width: 10, height: 10),
        ),
        const SizedBox(width: 6),
        Text(label),
      ],
    );
  }
}

class _PostsChartPainter extends CustomPainter {
  const _PostsChartPainter({
    required this.total,
    required this.withImages,
    required this.withoutImages,
    required this.progress,
    required this.primary,
    required this.secondary,
    required this.outline,
    required this.centerLabel,
    required this.subLabel,
  });

  final int total;
  final int withImages;
  final int withoutImages;
  final double progress;
  final Color primary;
  final Color secondary;
  final Color outline;
  final String centerLabel;
  final String subLabel;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 18;
    final center = Offset(size.width * 0.22, size.height / 2);
    final radius = size.height * 0.34;
    final rect = Rect.fromCircle(center: center, radius: radius);

    paint.color = outline.withValues(alpha: 0.35);
    canvas.drawArc(rect, -1.57, 6.28, false, paint);

    if (total > 0) {
      final imageSweep = (withImages / total) * 6.28 * progress;
      final noImageSweep = (withoutImages / total) * 6.28 * progress;

      paint.color = primary;
      canvas.drawArc(rect, -1.57, imageSweep, false, paint);
      paint.color = secondary;
      canvas.drawArc(
        rect,
        -1.57 + imageSweep + 0.08,
        noImageSweep,
        false,
        paint,
      );
    }

    final textPainter = TextPainter(
      text: TextSpan(
        text: '$total',
        style: TextStyle(
          color: primary,
          fontSize: 28,
          fontWeight: FontWeight.w900,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(
      canvas,
      center - Offset(textPainter.width / 2, textPainter.height / 2),
    );

    final labelPainter = TextPainter(
      text: TextSpan(
        text: centerLabel,
        style: TextStyle(
          color: primary.withValues(alpha: 0.72),
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: size.width * 0.5);
    labelPainter.paint(canvas, Offset(size.width * 0.48, size.height * 0.35));

    final subLabelPainter = TextPainter(
      text: TextSpan(
        text: subLabel,
        style: TextStyle(color: primary.withValues(alpha: 0.60), fontSize: 12),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: size.width * 0.48);
    subLabelPainter.paint(
      canvas,
      Offset(size.width * 0.48, size.height * 0.52),
    );
  }

  @override
  bool shouldRepaint(covariant _PostsChartPainter oldDelegate) {
    return oldDelegate.total != total ||
        oldDelegate.withImages != withImages ||
        oldDelegate.withoutImages != withoutImages ||
        oldDelegate.progress != progress ||
        oldDelegate.primary != primary ||
        oldDelegate.secondary != secondary ||
        oldDelegate.outline != outline ||
        oldDelegate.centerLabel != centerLabel ||
        oldDelegate.subLabel != subLabel;
  }
}

class _SummaryTile extends StatelessWidget {
  const _SummaryTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.foregroundColor,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final Color foregroundColor;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: color,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: foregroundColor),
            const SizedBox(height: 12),
            Text(label, style: TextStyle(color: foregroundColor)),
            const SizedBox(height: 4),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: foregroundColor,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'Thông báo', showBackButton: true),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          Card(
            child: ListTile(
              leading: Icon(Icons.check_circle_outline),
              title: Text('Backend đã sẵn sàng'),
              subtitle: Text('App đang gọi dữ liệu qua NestJS API.'),
            ),
          ),
          Card(
            child: ListTile(
              leading: Icon(Icons.info_outline),
              title: Text('Gợi ý tiếp theo'),
              subtitle: Text('Tạo post mới và chọn ảnh trong form.'),
            ),
          ),
        ],
      ),
    );
  }
}
