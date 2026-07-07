import 'package:flutter/material.dart';

import '../../core/localization/app_strings.dart';
import 'custom_button.dart';

class NoConnectionView extends StatelessWidget {
  const NoConnectionView({
    super.key,
    required this.strings,
    this.onRetry,
    this.compact = false,
  });

  final AppStrings strings;
  final VoidCallback? onRetry;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: EdgeInsets.all(compact ? 16 : 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.88, end: 1),
              duration: const Duration(milliseconds: 520),
              curve: Curves.elasticOut,
              builder: (context, value, child) {
                return Transform.scale(scale: value, child: child);
              },
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: colorScheme.errorContainer,
                  shape: BoxShape.circle,
                ),
                child: Padding(
                  padding: EdgeInsets.all(compact ? 16 : 22),
                  child: Icon(
                    Icons.wifi_off_rounded,
                    size: compact ? 34 : 48,
                    color: colorScheme.onErrorContainer,
                  ),
                ),
              ),
            ),
            SizedBox(height: compact ? 14 : 18),
            Text(
              strings.noConnectionTitle,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w900,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              strings.noConnectionMessage,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            if (onRetry != null) ...[
              SizedBox(height: compact ? 16 : 22),
              SizedBox(
                width: compact ? 160 : 220,
                child: CustomButton(
                  label: strings.tryAgain,
                  icon: Icons.refresh_rounded,
                  onPressed: onRetry,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
