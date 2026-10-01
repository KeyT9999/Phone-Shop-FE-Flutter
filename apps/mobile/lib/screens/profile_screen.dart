import 'package:flutter/material.dart';

import '../models/customer.dart';
import '../services/medusa_service.dart';
import 'login_screen.dart';
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
    backgroundColor: const Color(0xFFF6F7FB),
    appBar: AppBar(
      title: const Text('Tài khoản'),
      backgroundColor: const Color(0xFFF6F7FB),
    ),
    body: FutureBuilder<Customer?>(
      future: _customerFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) return _buildError(snapshot.error);
        final customer = snapshot.data;
        return customer == null
            ? _buildGuestState()
            : _buildCustomerState(customer);
      },
    ),
  );

  Widget _buildError(Object? error) => Center(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off_outlined, size: 44),
          const SizedBox(height: 12),
          const Text(
            'Chưa tải được tài khoản',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
          ),
          const SizedBox(height: 8),
          Text('$error', textAlign: TextAlign.center),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _reloadCustomer,
            icon: const Icon(Icons.refresh),
            label: const Text('Thử lại'),
          ),
        ],
      ),
    ),
  );

  Widget _buildGuestState() => Center(
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(
              Icons.account_circle_outlined,
              size: 72,
              color: Color(0xFF52648B),
            ),
            const SizedBox(height: 16),
            const Text(
              'Đăng nhập để quản lý tài khoản',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            const Text(
              'Lưu thông tin cá nhân và theo dõi đơn hàng của bạn.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF777D8A)),
            ),
            const SizedBox(height: 22),
            FilledButton(onPressed: _openLogin, child: const Text('Đăng nhập')),
            const SizedBox(height: 10),
            OutlinedButton(
              onPressed: _openRegistration,
              child: const Text('Tạo tài khoản'),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _buildCustomerState(Customer customer) => ListView(
    padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
    children: [
      Center(
        child: CircleAvatar(
          radius: 38,
          backgroundColor: const Color(0xFFE4EAF7),
          child: Text(
            _initials(customer),
            style: const TextStyle(
              color: Color(0xFF1E3A8A),
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
        style: const TextStyle(color: Color(0xFF777D8A)),
      ),
      const SizedBox(height: 28),
      const Text(
        'THÔNG TIN CÁ NHÂN',
        style: TextStyle(
          color: Color(0xFF777D8A),
          fontSize: 12,
          fontWeight: FontWeight.w800,
          letterSpacing: 1,
        ),
      ),
      const SizedBox(height: 10),
      Card(
        margin: EdgeInsets.zero,
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: Color(0xFFE8EAF0)),
        ),
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
