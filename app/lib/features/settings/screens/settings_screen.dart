import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/localization/app_strings.dart';
import '../../../shared/widgets/custom_app_bar.dart';
import '../providers/settings_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _notificationsEnabled = true;

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final strings = ref.watch(appStringsProvider);

    return Scaffold(
      appBar: CustomAppBar(title: strings.settings, showBackButton: true),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: SwitchListTile(
              secondary: const Icon(Icons.notifications_outlined),
              title: Text(strings.notificationsSetting),
              value: _notificationsEnabled,
              onChanged: (value) {
                setState(() => _notificationsEnabled = value);
              },
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.palette_outlined),
              title: Text(strings.appearance),
              subtitle: Text(_themeModeLabel(settings.themeMode)),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/settings/theme'),
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.language_outlined),
              title: Text(strings.language),
              subtitle: Text(_languageLabel(settings.locale)),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/settings/language'),
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.info_outline),
              title: Text(strings.aboutApp),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/settings/about'),
            ),
          ),
        ],
      ),
    );
  }

  String _themeModeLabel(ThemeMode themeMode) {
    final strings = ref.read(appStringsProvider);
    return switch (themeMode) {
      ThemeMode.light => strings.light,
      ThemeMode.dark => strings.dark,
      ThemeMode.system => strings.system,
    };
  }

  String _languageLabel(Locale locale) {
    final strings = ref.read(appStringsProvider);
    return locale.languageCode == 'en' ? strings.english : strings.vietnamese;
  }
}

class ThemeSettingsScreen extends ConsumerWidget {
  const ThemeSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedThemeMode = ref.watch(settingsProvider).themeMode;
    final strings = ref.watch(appStringsProvider);

    return Scaffold(
      appBar: CustomAppBar(title: strings.appearance, showBackButton: true),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _OptionTile<ThemeMode>(
            value: ThemeMode.system,
            selectedValue: selectedThemeMode,
            title: strings.system,
            icon: Icons.brightness_auto_outlined,
            onSelected: (value) {
              ref.read(settingsProvider.notifier).setThemeMode(value);
            },
          ),
          _OptionTile<ThemeMode>(
            value: ThemeMode.light,
            selectedValue: selectedThemeMode,
            title: strings.light,
            icon: Icons.light_mode_outlined,
            onSelected: (value) {
              ref.read(settingsProvider.notifier).setThemeMode(value);
            },
          ),
          _OptionTile<ThemeMode>(
            value: ThemeMode.dark,
            selectedValue: selectedThemeMode,
            title: strings.dark,
            icon: Icons.dark_mode_outlined,
            onSelected: (value) {
              ref.read(settingsProvider.notifier).setThemeMode(value);
            },
          ),
        ],
      ),
    );
  }
}

class LanguageSettingsScreen extends ConsumerWidget {
  const LanguageSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedLocale = ref.watch(settingsProvider).locale;
    final strings = ref.watch(appStringsProvider);

    return Scaffold(
      appBar: CustomAppBar(title: strings.language, showBackButton: true),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _OptionTile<String>(
            value: 'vi',
            selectedValue: selectedLocale.languageCode,
            title: strings.vietnamese,
            icon: Icons.translate_outlined,
            onSelected: (value) {
              ref.read(settingsProvider.notifier).setLocale(Locale(value));
            },
          ),
          _OptionTile<String>(
            value: 'en',
            selectedValue: selectedLocale.languageCode,
            title: strings.english,
            icon: Icons.language_outlined,
            onSelected: (value) {
              ref.read(settingsProvider.notifier).setLocale(Locale(value));
            },
          ),
        ],
      ),
    );
  }
}

class _OptionTile<T> extends StatelessWidget {
  const _OptionTile({
    required this.value,
    required this.selectedValue,
    required this.title,
    required this.icon,
    required this.onSelected,
  });

  final T value;
  final T selectedValue;
  final String title;
  final IconData icon;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) {
    final isSelected = value == selectedValue;

    return Card(
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        trailing: Icon(
          isSelected ? Icons.check_circle : Icons.circle_outlined,
          color: isSelected ? Theme.of(context).colorScheme.primary : null,
        ),
        onTap: () => onSelected(value),
      ),
    );
  }
}

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'Thông tin app', showBackButton: true),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          Card(
            child: ListTile(
              leading: Icon(Icons.flutter_dash_outlined),
              title: Text('Study Flutter'),
              subtitle: Text('Flutter app kết nối NestJS backend.'),
            ),
          ),
          Card(
            child: ListTile(
              leading: Icon(Icons.storage_outlined),
              title: Text('Backend'),
              subtitle: Text('NestJS API lưu dữ liệu demo bằng JSON local.'),
            ),
          ),
        ],
      ),
    );
  }
}
