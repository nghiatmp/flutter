import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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

class _LoginScreenState extends ConsumerState<LoginScreen> {
  /// Key dùng để validate toàn bộ form đăng nhập.
  final _formKey = GlobalKey<FormState>();

  /// Controller lấy dữ liệu email/password người dùng nhập.
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  /// Biến loading để tránh bấm nút đăng nhập nhiều lần.
  bool _isSubmitting = false;

  @override
  void dispose() {
    /// Dispose controller khi rời màn hình để giải phóng tài nguyên.
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

      /// Bước 4: login thành công thì báo thành công và vào màn quản lý.
      AppSnackbar.show(context, 'Đăng nhập thành công');
      context.go('/management');
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
                    Text(
                      'Đăng nhập',
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Dùng tài khoản vừa đăng ký để vào màn quản lý.',
                    ),
                    const SizedBox(height: 24),
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
                      label: 'Mật khẩu',
                      obscureText: true,
                      prefixIcon: Icons.lock_outline,

                      /// Validate password tối thiểu 6 ký tự như lúc đăng ký.
                      validator: Validators.password,
                    ),
                    const SizedBox(height: 20),
                    CustomButton(
                      label: 'Đăng nhập',
                      icon: Icons.login,
                      isLoading: _isSubmitting,

                      /// Khi bấm nút, chạy submit login.
                      onPressed: _submit,
                    ),
                    TextButton(
                      /// Chưa có tài khoản thì quay sang màn đăng ký.
                      onPressed: () => context.go('/register'),
                      child: const Text('Chưa có tài khoản? Đăng ký'),
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
