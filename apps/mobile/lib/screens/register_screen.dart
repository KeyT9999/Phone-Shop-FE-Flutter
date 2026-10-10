import 'package:flutter/material.dart';

import '../services/medusa_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_components.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key, this.service});

  final MedusaService? service;

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  late final MedusaService _service;
  bool _isSubmitting = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _service = widget.service ?? MedusaService.instance;
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      await _service.registerCustomer(
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (mounted) setState(() => _errorMessage = error.toString());
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tạo tài khoản')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: AppSurface(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const AppPageHeading(
                        eyebrow: 'Tài khoản DTC',
                        title: 'Bắt đầu mua sắm',
                        subtitle: 'Tạo tài khoản để lưu địa chỉ và theo dõi đơn hàng.',
                        crossAxisAlignment: CrossAxisAlignment.center,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      TextFormField(
                        key: const Key('register-first-name'),
                        controller: _firstNameController,
                        textCapitalization: TextCapitalization.words,
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.givenName],
                        decoration: const InputDecoration(
                          labelText: 'Tên',
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                        validator: (value) => value?.trim().isNotEmpty == true
                            ? null
                            : 'Vui lòng nhập tên.',
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        key: const Key('register-last-name'),
                        controller: _lastNameController,
                        textCapitalization: TextCapitalization.words,
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.familyName],
                        decoration: const InputDecoration(
                          labelText: 'Họ',
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                        validator: (value) => value?.trim().isNotEmpty == true
                            ? null
                            : 'Vui lòng nhập họ.',
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        key: const Key('register-email'),
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.newUsername],
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          hintText: 'ban@example.com',
                          prefixIcon: Icon(Icons.mail_outline),
                        ),
                        validator: (value) {
                          final email = value?.trim() ?? '';
                          if (email.isEmpty) return 'Vui lòng nhập email.';
                          if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$')
                              .hasMatch(email)) {
                            return 'Email không hợp lệ.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        key: const Key('register-password'),
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.newPassword],
                        decoration: InputDecoration(
                          labelText: 'Mật khẩu',
                          helperText: 'Tối thiểu 8 ký tự.',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            tooltip: _obscurePassword
                                ? 'Hiện mật khẩu'
                                : 'Ẩn mật khẩu',
                            onPressed: () => setState(
                              () => _obscurePassword = !_obscurePassword,
                            ),
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                            ),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Vui lòng nhập mật khẩu.';
                          }
                          if (value.length < 8) {
                            return 'Mật khẩu cần ít nhất 8 ký tự.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        key: const Key('register-confirm-password'),
                        controller: _confirmPasswordController,
                        obscureText: _obscurePassword,
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _submit(),
                        decoration: const InputDecoration(
                          labelText: 'Nhập lại mật khẩu',
                          prefixIcon: Icon(Icons.lock_outline),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Vui lòng xác nhận mật khẩu.';
                          }
                          if (value != _passwordController.text) {
                            return 'Mật khẩu xác nhận không khớp.';
                          }
                          return null;
                        },
                      ),
                      if (_errorMessage != null) ...[
                        const SizedBox(height: AppSpacing.sm),
                        _RegisterError(message: _errorMessage!),
                      ],
                      const SizedBox(height: AppSpacing.lg),
                      FilledButton(
                        key: const Key('register-submit'),
                        onPressed: _isSubmitting ? null : _submit,
                        child: _isSubmitting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: AppColors.surface,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('Tạo tài khoản'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RegisterError extends StatelessWidget {
  const _RegisterError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: AppColors.errorSurface,
      borderRadius: BorderRadius.circular(AppRadii.md),
    ),
    child: Text(
      message,
      style: const TextStyle(color: AppColors.error),
      textAlign: TextAlign.center,
    ),
  );
}
