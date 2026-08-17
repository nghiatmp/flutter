import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/profile_options.dart';
import '../../../core/localization/app_strings.dart';
import '../../../core/utils/app_snackbar.dart';
import '../../../core/utils/validators.dart';
import '../../../shared/widgets/animated_list_item.dart';
import '../../../shared/widgets/custom_app_bar.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../shared/widgets/custom_checkbox_group_field.dart';
import '../../../shared/widgets/custom_date_field.dart';
import '../../../shared/widgets/custom_dropdown_field.dart';
import '../../../shared/widgets/custom_radio_group_field.dart';
import '../../../shared/widgets/custom_text_field.dart';
import '../../auth/models/user_model.dart';
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

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  String? _selectedGender;
  final Set<String> _selectedHobbies = {};
  DateTime? _selectedBirthDate;
  String? _selectedCity;
  bool _isSubmitting = false;

  /// Chỉ điền dữ liệu từ user vào form một lần — build() có thể chạy lại
  /// nhiều lần (ví dụ khi gõ chữ) nên không được ghi đè giá trị người dùng
  /// đang nhập dở.
  bool _initialized = false;

  @override
  void dispose() {
    _fullNameController.dispose();
    super.dispose();
  }

  void _initFromUser(UserModel user) {
    if (_initialized) return;
    _initialized = true;

    _fullNameController.text = user.fullName;
    _selectedGender = user.gender.isEmpty ? null : user.gender;
    _selectedHobbies.addAll(user.hobbies);
    _selectedBirthDate = user.birthDate;
    _selectedCity = user.city.isEmpty ? null : user.city;
  }

  Future<void> _submit(UserModel currentUser) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    try {
      /// copyWith giữ nguyên email — endpoint update cũng không nhận field
      /// này, nên người dùng không có cách nào đổi được email qua màn này.
      final updated = currentUser.copyWith(
        fullName: _fullNameController.text.trim(),
        gender: _selectedGender ?? '',
        hobbies: _selectedHobbies.toList(),
        birthDate: _selectedBirthDate,
        city: _selectedCity ?? '',
      );
      await ref.read(authProvider.notifier).updateProfile(updated);
      if (!mounted) return;

      AppSnackbar.show(context, ref.read(appStringsProvider).profileUpdated);
    } catch (error) {
      if (!mounted) return;
      AppSnackbar.show(
        context,
        error.toString().replaceFirst('Exception: ', ''),
        isError: true,
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    final strings = ref.watch(appStringsProvider);

    if (user == null) {
      return Scaffold(
        appBar: CustomAppBar(
          title: strings.personalProfile,
          showBackButton: true,
        ),
        body: Center(child: Text(strings.noData)),
      );
    }

    _initFromUser(user);

    return Scaffold(
      appBar: CustomAppBar(
        title: strings.personalProfile,
        showBackButton: true,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  CustomTextField(
                    controller: _fullNameController,
                    label: strings.fullName,
                    prefixIcon: Icons.person_outline,
                    validator: (value) =>
                        Validators.required(value, strings.fullName),
                  ),
                  const SizedBox(height: 14),
                  _ReadOnlyField(
                    label: strings.email,
                    value: user.email,
                    icon: Icons.email_outlined,
                    helperText: strings.emailLocked,
                  ),
                  const SizedBox(height: 14),
                  CustomRadioGroupField<String>(
                    label: strings.gender,
                    options: ProfileOptions.genders,
                    value: _selectedGender,
                    optionLabelBuilder: (gender) => gender,
                    onChanged: (value) {
                      setState(() => _selectedGender = value);
                    },
                  ),
                  const SizedBox(height: 14),
                  CustomCheckboxGroupField<String>(
                    label: strings.hobbies,
                    options: ProfileOptions.hobbies,
                    selectedValues: _selectedHobbies,
                    optionLabelBuilder: (hobby) => hobby,
                    onChanged: (values) {
                      setState(() {
                        _selectedHobbies
                          ..clear()
                          ..addAll(values);
                      });
                    },
                  ),
                  const SizedBox(height: 14),
                  CustomDateField(
                    label: strings.birthDate,
                    value: _selectedBirthDate,
                    prefixIcon: Icons.calendar_today_outlined,
                    firstDate: DateTime(1900),
                    lastDate: DateTime.now(),
                    onChanged: (value) {
                      setState(() => _selectedBirthDate = value);
                    },
                  ),
                  const SizedBox(height: 14),
                  CustomDropdownField<String>(
                    label: strings.city,
                    options: ProfileOptions.cities,
                    value: _selectedCity,
                    optionLabelBuilder: (city) => city,
                    prefixIcon: Icons.location_city_outlined,
                    onChanged: (value) {
                      setState(() => _selectedCity = value);
                    },
                  ),
                  const SizedBox(height: 20),
                  CustomButton(
                    label: strings.saveChanges,
                    icon: Icons.save_outlined,
                    isLoading: _isSubmitting,
                    onPressed: () => _submit(user),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _AccountTile(
              icon: Icons.lock_outline,
              title: strings.changePassword,
              onTap: () => context.push('/account/profile/change-password'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReadOnlyField extends StatelessWidget {
  const _ReadOnlyField({
    required this.label,
    required this.value,
    required this.icon,
    this.helperText,
  });

  final String label;
  final String value;
  final IconData icon;
  final String? helperText;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      initialValue: value,
      readOnly: true,
      enabled: false,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        helperText: helperText,
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
        children: [
          const Card(
            child: ListTile(
              leading: Icon(Icons.key_outlined),
              title: Text('Token đăng nhập'),
              subtitle: Text('App đang lưu token trong SharedPreferences.'),
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.lock_outline),
              title: const Text('Đổi mật khẩu'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/account/profile/change-password'),
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

class ChangePasswordScreen extends ConsumerStatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  ConsumerState<ChangePasswordScreen> createState() =>
      _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends ConsumerState<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    try {
      /// AuthService tự đính kèm accessToken hiện tại; backend kiểm tra
      /// currentPassword trước khi cho phép đổi mật khẩu mới.
      await ref
          .read(authServiceProvider)
          .changePassword(
            currentPassword: _currentPasswordController.text,
            newPassword: _newPasswordController.text,
          );
      if (!mounted) return;

      AppSnackbar.show(context, ref.read(appStringsProvider).passwordChanged);
      context.pop();
    } catch (error) {
      if (!mounted) return;
      AppSnackbar.show(
        context,
        error.toString().replaceFirst('Exception: ', ''),
        isError: true,
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = ref.watch(appStringsProvider);

    return Scaffold(
      appBar: CustomAppBar(
        title: strings.changePassword,
        showBackButton: true,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  CustomTextField(
                    controller: _currentPasswordController,
                    label: strings.currentPassword,
                    obscureText: true,
                    prefixIcon: Icons.lock_outline,
                    validator: Validators.password,
                  ),
                  const SizedBox(height: 14),
                  CustomTextField(
                    controller: _newPasswordController,
                    label: strings.newPassword,
                    obscureText: true,
                    prefixIcon: Icons.lock_reset_outlined,
                    validator: Validators.password,
                  ),
                  const SizedBox(height: 14),
                  CustomTextField(
                    controller: _confirmPasswordController,
                    label: strings.confirmNewPassword,
                    obscureText: true,
                    prefixIcon: Icons.verified_user_outlined,
                    validator: (value) {
                      final error = Validators.password(value);
                      if (error != null) return error;
                      if (value != _newPasswordController.text) {
                        return strings.isEnglish
                            ? 'Passwords do not match'
                            : 'Mật khẩu xác nhận không khớp';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  CustomButton(
                    label: strings.saveChanges,
                    icon: Icons.check_circle_outline,
                    isLoading: _isSubmitting,
                    onPressed: _submit,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
