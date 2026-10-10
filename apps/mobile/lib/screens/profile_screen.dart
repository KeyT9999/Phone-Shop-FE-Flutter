import 'package:flutter/material.dart';

import '../models/customer.dart';
import '../services/medusa_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_components.dart';
import 'address_book_screen.dart';
import 'login_screen.dart';
import 'order_history_screen.dart';
import 'register_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, this.service});

  final MedusaService? service;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final MedusaService _service;
  late Future<Customer?> _customerFuture;
  bool _isLoggingOut = false;

  @override
  void initState() {
    super.initState();
    _service = widget.service ?? MedusaService.instance;
    _customerFuture = _service.getCurrentCustomer();
  }

  void _reloadCustomer() {
    setState(() {
      _customerFuture = _service.getCurrentCustomer();
    });
  }

  Future<void> _openLogin() async {
    final signedIn = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => LoginScreen(service: _service)),
    );
    if (signedIn == true && mounted) _reloadCustomer();
  }

  Future<void> _openRegistration() async {
    final registered = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => RegisterScreen(service: _service)),
    );
    if (registered == true && mounted) _reloadCustomer();
  }

  Future<void> _logout() async {
    setState(() => _isLoggingOut = true);
    try {
      await _service.logoutCustomer();
      if (mounted) _reloadCustomer();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Không thể đăng xuất: $error')));
      }
    } finally {
      if (mounted) setState(() => _isLoggingOut = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Tài khoản')),
    body: FutureBuilder<Customer?>(
      future: _customerFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const AppStateView(
            title: 'Đang tải tài khoản',
            icon: Icons.person_outline,
            isLoading: true,
          );
        }
        if (snapshot.hasError) return _buildError(snapshot.error);
        final customer = snapshot.data;
        return customer == null
            ? _buildGuestState()
            : _buildCustomerState(customer);
      },
    ),
  );

  Widget _buildError(Object? error) => AppStateView(
    title: 'Chưa tải được tài khoản',
    description: '$error',
    icon: Icons.cloud_off_outlined,
    actionLabel: 'Thử lại',
    onAction: _reloadCustomer,
  );

  Widget _buildGuestState() => Center(
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: AppSurface(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const AppPageHeading(
                eyebrow: 'DTC Phone Store',
                title: 'Quản lý tài khoản',
                subtitle: 'Đăng nhập để lưu địa chỉ và theo dõi đơn hàng.',
                crossAxisAlignment: CrossAxisAlignment.center,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xl),
              FilledButton(
                onPressed: _openLogin,
                child: const Text('Đăng nhập'),
              ),
              const SizedBox(height: AppSpacing.xs),
              OutlinedButton(
                onPressed: _openRegistration,
                child: const Text('Tạo tài khoản'),
              ),
            ],
          ),
        ),
      ),
    ),
  );

  Widget _buildCustomerState(Customer customer) => Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 640),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
        children: [
          Center(
            child: CircleAvatar(
              radius: 38,
              backgroundColor: AppColors.primarySoft,
              child: Text(
                _initials(customer),
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            customer.fullName,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            customer.email,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textMuted),
          ),
          const SizedBox(height: AppSpacing.xl),
          const Text(
            'THÔNG TIN CÁ NHÂN',
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.person_outline),
                  title: const Text('Họ và tên'),
                  subtitle: Text(customer.fullName),
                ),
                const Divider(height: 1, indent: 56),
                ListTile(
                  leading: const Icon(Icons.mail_outline),
                  title: const Text('Email'),
                  subtitle: Text(customer.email),
                ),
                if (customer.phone?.isNotEmpty == true) ...[
                  const Divider(height: 1, indent: 56),
                  ListTile(
                    leading: const Icon(Icons.phone_outlined),
                    title: const Text('Số điện thoại'),
                    subtitle: Text(customer.phone!),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.location_on_outlined),
                  title: const Text('Sổ địa chỉ'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.push<void>(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AddressBookScreen(service: _service),
                    ),
                  ),
                ),
                const Divider(height: 1, indent: 56),
                ListTile(
                  leading: const Icon(Icons.receipt_long_outlined),
                  title: const Text('Đơn hàng của tôi'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.push<void>(
                    context,
                    MaterialPageRoute(
                      builder: (_) => OrderHistoryScreen(service: _service),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: _isLoggingOut ? null : _logout,
            icon: _isLoggingOut
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.logout),
            label: const Text('Đăng xuất'),
          ),
        ],
      ),
    ),
  );

  String _initials(Customer customer) {
    final parts = customer.fullName
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.characters.first.toUpperCase();
    return '${parts.first.characters.first}${parts.last.characters.first}'
        .toUpperCase();
  }
}
