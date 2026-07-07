import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/localization/app_strings.dart';
import '../../../core/utils/app_snackbar.dart';
import '../../../shared/widgets/animated_list_item.dart';
import '../../../shared/widgets/custom_app_bar.dart';
import '../../auth/providers/auth_provider.dart';

class AccountScreen extends ConsumerWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    final strings = ref.watch(appStringsProvider);

    return Scaffold(
      appBar: CustomAppBar(title: strings.account),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              color: Theme.of(context).colorScheme.primaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      child: Text(
                        (user?.fullName.isNotEmpty ?? false)
                            ? user!.fullName.characters.first.toUpperCase()
                            : 'U',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onPrimary,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user?.fullName ?? strings.account,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onPrimaryContainer,
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            user?.email ?? '',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onPrimaryContainer
                                  .withValues(alpha: 0.72),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            AnimatedListItem(
              index: 0,
              child: _AccountTile(
                icon: Icons.badge_outlined,
                title: strings.profile,
                onTap: () => context.push('/account/profile'),
              ),
            ),
            AnimatedListItem(
              index: 1,
              child: _AccountTile(
                icon: Icons.settings_outlined,
                title: strings.settings,
                onTap: () => context.push('/settings'),
              ),
            ),
            AnimatedListItem(
              index: 2,
              child: _AccountTile(
                icon: Icons.security_outlined,
                title: strings.accountSecurity,
                onTap: () => context.push('/account/security'),
              ),
            ),
            AnimatedListItem(
              index: 3,
              child: _AccountTile(
                icon: Icons.logout,
                title: strings.logout,
                onTap: () async {
                  await _confirmLogout(context, ref, strings);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> _confirmLogout(
  BuildContext context,
  WidgetRef ref,
  AppStrings strings,
) async {
  final shouldLogout = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(strings.logoutTitle),
      content: Text(strings.logoutMessage),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: Text(strings.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: Text(strings.logout),
        ),
      ],
    ),
  );

  if (shouldLogout != true || !context.mounted) return;

  await ref.read(authProvider.notifier).logout();
  if (!context.mounted) return;

  AppSnackbar.show(context, strings.loggedOut);
  context.go('/login');
}

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    final strings = ref.watch(appStringsProvider);

    return Scaffold(
      appBar: CustomAppBar(
        title: strings.personalProfile,
        showBackButton: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _InfoRow(label: strings.fullName, value: user?.fullName ?? ''),
          _InfoRow(label: strings.email, value: user?.email ?? ''),
          _InfoRow(label: strings.gender, value: user?.gender ?? ''),
          _InfoRow(label: strings.city, value: user?.city ?? ''),
          _InfoRow(
            label: strings.hobbies,
            value: user?.hobbies.join(', ') ?? '',
          ),
        ],
      ),
    );
  }
}

class AccountSecurityScreen extends StatelessWidget {
  const AccountSecurityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'Bảo mật', showBackButton: true),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          Card(
            child: ListTile(
              leading: Icon(Icons.key_outlined),
              title: Text('Token đăng nhập'),
              subtitle: Text('App đang lưu token trong SharedPreferences.'),
            ),
          ),
          Card(
            child: ListTile(
              leading: Icon(Icons.lock_outline),
              title: Text('Đổi mật khẩu'),
              subtitle: Text('Có thể thêm API đổi mật khẩu ở bước tiếp theo.'),
            ),
          ),
        ],
      ),
    );
  }
}

class _AccountTile extends StatelessWidget {
  const _AccountTile({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}

class _InfoRow extends ConsumerWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(appStringsProvider);

    return Card(
      child: ListTile(
        title: Text(label),
        subtitle: Text(value.isEmpty ? strings.noData : value),
      ),
    );
  }
}
