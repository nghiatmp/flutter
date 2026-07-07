import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/localization/app_strings.dart';
import '../../../core/utils/app_snackbar.dart';
import '../../../core/utils/validators.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../shared/widgets/custom_text_field.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with SingleTickerProviderStateMixin {
  /// Key dùng để validate toàn bộ form đăng nhập.
  final _formKey = GlobalKey<FormState>();

  /// Controller lấy dữ liệu email/password người dùng nhập.
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  late final AnimationController _entryController;
  late final Animation<double> _headerFadeAnimation;
  late final Animation<double> _formFadeAnimation;
  late final Animation<Offset> _headerOffsetAnimation;
  late final Animation<Offset> _formOffsetAnimation;

  /// Biến loading để tránh bấm nút đăng nhập nhiều lần.
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 780),
    );
    _headerFadeAnimation = CurvedAnimation(
      parent: _entryController,
      curve: const Interval(0, 0.72, curve: Curves.easeOut),
    );
    _formFadeAnimation = CurvedAnimation(
      parent: _entryController,
      curve: const Interval(0.22, 1, curve: Curves.easeOut),
    );
    _headerOffsetAnimation =
        Tween<Offset>(begin: const Offset(0, 0.10), end: Offset.zero).animate(
          CurvedAnimation(parent: _entryController, curve: Curves.easeOutCubic),
        );
    _formOffsetAnimation =
        Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _entryController,
            curve: const Interval(0.18, 1, curve: Curves.easeOutCubic),
          ),
        );
    _entryController.forward();
    _fillRegisteredAccount();
  }

  Future<void> _fillRegisteredAccount() async {
    final user = await ref.read(authServiceProvider).getRegisteredUser();
    if (!mounted) return;

    /// Nếu máy chưa từng đăng ký tài khoản nào, tự điền tài khoản demo
    /// mà backend đã seed sẵn để người dùng đăng nhập thử ngay.
    _emailController.text = user?.email ?? AppConstants.demoUserEmail;
    _passwordController.text = user?.password ?? AppConstants.demoUserPassword;
  }

  @override
  void dispose() {
    /// Dispose controller khi rời màn hình để giải phóng tài nguyên.
    _entryController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    /// Bước 1: validate email/password.
    /// Nếu form chưa hợp lệ thì dừng, không gọi login.
    if (!_formKey.currentState!.validate()) return;

    /// Bước 2: bật trạng thái đang xử lý.
    setState(() => _isSubmitting = true);
    try {
      /// Bước 3: gọi AuthNotifier.login.
      /// Provider sẽ kiểm tra tài khoản trong local storage và cập nhật global state.
      await ref
          .read(authProvider.notifier)
          .login(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );
      if (!mounted) return;

      /// Bước 4: login thành công thì vào màn animation chuyển tiếp.
      context.go('/login-success');
    } catch (error) {
      /// Nếu email/password sai hoặc chưa đăng ký, hiển thị lỗi từ AuthService.
      if (!mounted) return;
      AppSnackbar.show(
        context,
        error.toString().replaceFirst('Exception: ', ''),
        isError: true,
      );
    } finally {
      /// Luôn tắt loading sau khi xử lý xong.
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = ref.watch(appStringsProvider);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Form(
                /// Form chứa các input đăng nhập và quản lý validate.
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    FadeTransition(
                      opacity: _headerFadeAnimation,
                      child: SlideTransition(
                        position: _headerOffsetAnimation,
                        child: _LoginHeader(
                          strings: strings,
                          animation: _headerFadeAnimation,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    FadeTransition(
                      opacity: _formFadeAnimation,
                      child: SlideTransition(
                        position: _formOffsetAnimation,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            CustomTextField(
                              controller: _emailController,
                              label: 'Email',
                              keyboardType: TextInputType.emailAddress,
                              prefixIcon: Icons.email_outlined,

                              /// Validate email trước khi gọi login.
                              validator: Validators.email,
                            ),
                            const SizedBox(height: 14),
                            CustomTextField(
                              controller: _passwordController,
                              label: strings.password,
                              obscureText: true,
                              prefixIcon: Icons.lock_outline,

                              /// Validate password tối thiểu 6 ký tự như lúc đăng ký.
                              validator: Validators.password,
                            ),
                            const SizedBox(height: 20),
                            CustomButton(
                              label: strings.login,
                              icon: Icons.login,
                              isLoading: _isSubmitting,

                              /// Khi bấm nút, chạy submit login.
                              onPressed: _submit,
                            ),
                            TextButton(
                              /// Chưa có tài khoản thì quay sang màn đăng ký.
                              onPressed: () => context.go('/register'),
                              child: Text(strings.goRegister),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LoginHeader extends StatelessWidget {
  const _LoginHeader({required this.strings, required this.animation});

  final AppStrings strings;
  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedBuilder(
          animation: animation,
          builder: (context, child) {
            return Transform.scale(
              scale: 0.92 + (0.08 * animation.value),
              child: child,
            );
          },
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: colorScheme.primary.withValues(alpha: 0.16),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Icon(
                Icons.lock_open_rounded,
                color: colorScheme.primary,
                size: 30,
              ),
            ),
          ),
        ),
        const SizedBox(height: 18),
        Text(
          strings.login,
          style: Theme.of(
            context,
          ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        Text(
          strings.loginSubtitle,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }
}
