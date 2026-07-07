import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/localization/app_strings.dart';
import '../../../core/utils/app_snackbar.dart';
import '../../../core/utils/validators.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../shared/widgets/custom_checkbox_field.dart';
import '../../../shared/widgets/custom_checkbox_group_field.dart';
import '../../../shared/widgets/custom_date_field.dart';
import '../../../shared/widgets/custom_dropdown_field.dart';
import '../../../shared/widgets/custom_radio_group_field.dart';
import '../../../shared/widgets/custom_text_field.dart';
import '../models/user_model.dart';
import '../providers/auth_provider.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  /// GlobalKey dùng để gọi validate() cho toàn bộ Form.
  /// Nếu bất kỳ TextFormField nào trả lỗi, validate() sẽ trả false.
  final _formKey = GlobalKey<FormState>();

  /// Controller quản lý dữ liệu nhập của từng ô input.
  /// Khi submit, lấy text từ controller để tạo UserModel.
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final _genderOptions = const ['Nam', 'Nữ', 'Khác'];
  final _hobbyOptions = const ['Đọc sách', 'Thể thao', 'Âm nhạc', 'Du lịch'];
  final _cityOptions = const [
    'Hà Nội',
    'Đà Nẵng',
    'TP. Hồ Chí Minh',
    'Cần Thơ',
  ];

  String? _selectedGender;
  final Set<String> _selectedHobbies = {};
  DateTime? _selectedBirthDate;
  String? _selectedCity;
  bool _acceptedTerms = false;

  /// Biến loading để disable nút đăng ký và hiển thị progress khi đang xử lý.
  bool _isSubmitting = false;

  @override
  void dispose() {
    /// Dispose controller để tránh rò rỉ bộ nhớ khi màn hình bị hủy.
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    /// Bước 1: chạy toàn bộ validate của form.
    /// Nếu có lỗi thì dừng lại, Flutter tự hiển thị lỗi dưới từng input.
    if (!_formKey.currentState!.validate()) return;

    /// Bước 2: bật loading để người dùng biết app đang xử lý.
    setState(() => _isSubmitting = true);

    /// Bước 3: gom dữ liệu từ form thành UserModel.
    /// trim() dùng để bỏ khoảng trắng thừa ở đầu/cuối.
    final user = UserModel(
      fullName: _fullNameController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text,
      gender: _selectedGender!,
      hobbies: _selectedHobbies.toList(),
      birthDate: _selectedBirthDate!,
      city: _selectedCity!,
      acceptedTerms: _acceptedTerms,
    );

    try {
      /// Bước 4: gọi global authProvider để đăng ký.
      /// AuthProvider sẽ gọi AuthService và lưu user vào local storage.
      await ref.read(authProvider.notifier).register(user);
      if (!mounted) return;

      /// Bước 5: báo thành công và điều hướng sang màn đăng nhập.
      AppSnackbar.show(context, ref.read(appStringsProvider).registerSuccess);
      context.go('/login');
    } catch (error) {
      /// Nếu có lỗi bất ngờ, hiển thị toast lỗi cho người dùng.
      if (!mounted) return;
      AppSnackbar.show(context, error.toString(), isError: true);
    } finally {
      /// Tắt loading ở finally để dù thành công hay thất bại UI cũng trở lại bình thường.
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
                /// Form gom các input lại để validate cùng lúc.
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Tạo tài khoản',
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    const Text('Demo form, validate và lưu tài khoản local.'),
                    const SizedBox(height: 24),
                    CustomTextField(
                      controller: _fullNameController,
                      label: 'Họ tên',
                      prefixIcon: Icons.person_outline,

                      /// Validate trường bắt buộc nhập.
                      validator: (value) =>
                          Validators.required(value, 'Họ tên'),
                    ),
                    const SizedBox(height: 14),
                    CustomTextField(
                      controller: _emailController,
                      label: 'Email',
                      keyboardType: TextInputType.emailAddress,
                      prefixIcon: Icons.email_outlined,

                      /// Validate email: không trống và đúng định dạng.
                      validator: Validators.email,
                    ),
                    const SizedBox(height: 14),
                    CustomTextField(
                      controller: _passwordController,
                      label: 'Mật khẩu',
                      obscureText: true,
                      prefixIcon: Icons.lock_outline,

                      /// Validate password: không trống và tối thiểu 6 ký tự.
                      validator: Validators.password,
                    ),
                    const SizedBox(height: 14),
                    CustomTextField(
                      controller: _confirmPasswordController,
                      label: 'Xác nhận mật khẩu',
                      obscureText: true,
                      prefixIcon: Icons.verified_user_outlined,
                      validator: (value) {
                        /// Validate xác nhận mật khẩu:
                        /// 1. Không được trống.
                        /// 2. Phải giống mật khẩu đã nhập.
                        final error = Validators.required(
                          value,
                          'Xác nhận mật khẩu',
                        );
                        if (error != null) return error;
                        if (value != _passwordController.text) {
                          return 'Xác nhận mật khẩu không trùng khớp';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    CustomRadioGroupField<String>(
                      label: 'Giới tính',
                      options: _genderOptions,
                      value: _selectedGender,
                      optionLabelBuilder: (gender) => gender,
                      onChanged: (value) {
                        setState(() => _selectedGender = value);
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Vui lòng chọn giới tính';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    CustomCheckboxGroupField<String>(
                      label: 'Sở thích',
                      options: _hobbyOptions,
                      selectedValues: _selectedHobbies,
                      optionLabelBuilder: (hobby) => hobby,
                      onChanged: (values) {
                        setState(() {
                          _selectedHobbies
                            ..clear()
                            ..addAll(values);
                        });
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Vui lòng chọn ít nhất một sở thích';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    CustomDateField(
                      label: 'Ngày sinh',
                      value: _selectedBirthDate,
                      hintText: 'Chọn ngày sinh',
                      prefixIcon: Icons.calendar_today_outlined,
                      firstDate: DateTime(1900),
                      lastDate: DateTime.now(),
                      initialDate: DateTime(DateTime.now().year - 18),
                      onChanged: (value) {
                        setState(() => _selectedBirthDate = value);
                      },
                      validator: (value) {
                        if (value == null) {
                          return 'Ngày sinh không được để trống';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    CustomDropdownField<String>(
                      label: 'Thành phố',
                      options: _cityOptions,
                      value: _selectedCity,
                      optionLabelBuilder: (city) => city,
                      prefixIcon: Icons.location_city_outlined,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Vui lòng chọn thành phố';
                        }
                        return null;
                      },
                      onChanged: (value) {
                        setState(() => _selectedCity = value);
                      },
                    ),
                    const SizedBox(height: 14),
                    CustomCheckboxField(
                      label: 'Tôi đồng ý với điều khoản',
                      value: _acceptedTerms,
                      onChanged: (value) {
                        setState(() => _acceptedTerms = value);
                      },
                      validator: (value) {
                        if (value != true) {
                          return 'Bạn cần đồng ý với điều khoản';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    CustomButton(
                      label: 'Đăng ký',
                      icon: Icons.person_add_alt_1,
                      isLoading: _isSubmitting,

                      /// Khi bấm nút, gọi _submit để validate và lưu user.
                      onPressed: _submit,
                    ),
                    TextButton(
                      /// Cho phép chuyển sang login nếu đã có tài khoản.
                      onPressed: () => context.go('/login'),
                      child: const Text('Đã có tài khoản? Đăng nhập'),
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
