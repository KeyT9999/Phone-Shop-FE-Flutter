import 'package:flutter/material.dart';

import '../services/medusa_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_components.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, this.service});

  final MedusaService? service;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
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
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      await _service.loginCustomer(
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

  Future<void> _openRegistration() async {
    final registered = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => RegisterScreen(service: _service)),
    );
    if (registered == true && mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Đăng nhập')),
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
                        eyebrow: 'DTC Phone Store',
                        title: 'Chào mừng bạn trở lại',
                        subtitle: 'Đăng nhập để tiếp tục mua sắm.',
                        crossAxisAlignment: CrossAxisAlignment.center,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      TextFormField(
                        key: const Key('login-email'),
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.email],
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
                      const SizedBox(height: AppSpacing.md),
                      TextFormField(
                        key: const Key('login-password'),
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        textInputAction: TextInputAction.done,
                        autofillHints: const [AutofillHints.password],
                        onFieldSubmitted: (_) => _submit(),
                        decoration: InputDecoration(
                          labelText: 'Mật khẩu',
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
                        validator: (value) => value == null || value.isEmpty
                            ? 'Vui lòng nhập mật khẩu.'
                            : null,
                      ),
                      if (_errorMessage != null) ...[
                        const SizedBox(height: AppSpacing.sm),
                        _AuthError(message: _errorMessage!),
                      ],
                      const SizedBox(height: AppSpacing.lg),
                      FilledButton(
                        key: const Key('login-submit'),
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
                            : const Text('Đăng nhập'),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      TextButton(
                        onPressed: _isSubmitting ? null : _openRegistration,
                        child: const Text('Chưa có tài khoản? Tạo tài khoản'),
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

class _AuthError extends StatelessWidget {
  const _AuthError({required this.message});

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
