import 'package:flutter/material.dart';

import '../models/customer_address.dart';
import '../services/medusa_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_components.dart';
import 'address_form_screen.dart';

class AddressBookScreen extends StatefulWidget {
  const AddressBookScreen({
    super.key,
    required this.service,
    this.selectionMode = false,
  });

  final MedusaService service;
  final bool selectionMode;

  @override
  State<AddressBookScreen> createState() => _AddressBookScreenState();
}

class _AddressBookScreenState extends State<AddressBookScreen> {
  List<CustomerAddress> _addresses = const [];
  bool _isLoading = true;
  String? _error;
  String? _busyId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final addresses = await widget.service.getCustomerAddresses();
      if (mounted) setState(() => _addresses = addresses);
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _addAddress() async {
    final saved = await Navigator.push<CustomerAddress>(
      context,
      MaterialPageRoute(
        builder: (_) => AddressFormScreen(service: widget.service),
      ),
    );
    if (!mounted || saved == null) return;
    await _load();
    if (widget.selectionMode && mounted) Navigator.pop(context, saved);
  }

  Future<void> _editAddress(CustomerAddress address) async {
    final saved = await Navigator.push<CustomerAddress>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            AddressFormScreen(service: widget.service, address: address),
      ),
    );
    if (!mounted || saved == null) return;
    await _load();
    if (widget.selectionMode && mounted) Navigator.pop(context, saved);
  }

  Future<void> _deleteAddress(CustomerAddress address) async {
    final id = address.id;
    if (id == null || id.isEmpty) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa địa chỉ này?'),
        content: const Text('Địa chỉ sẽ bị xóa khỏi tài khoản của bạn.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _busyId = id);
    try {
      await widget.service.deleteCustomerAddress(id);
      await _load();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không thể xóa địa chỉ: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }

  void _select(CustomerAddress address) {
    if (widget.selectionMode) Navigator.pop(context, address);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(
        widget.selectionMode ? 'Chọn địa chỉ giao hàng' : 'Sổ địa chỉ',
      ),
    ),
    floatingActionButton: FloatingActionButton.extended(
      onPressed: _isLoading || _busyId != null ? null : _addAddress,
      icon: const Icon(Icons.add),
      label: const Text('Thêm địa chỉ'),
    ),
    body: _isLoading
        ? const AppStateView(
            title: 'Đang tải địa chỉ',
            icon: Icons.location_on_outlined,
            isLoading: true,
          )
        : _error != null
        ? _errorState()
        : _addresses.isEmpty
        ? _emptyState()
        : RefreshIndicator(
            onRefresh: _load,
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
              itemCount: _addresses.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) => _addressCard(_addresses[index]),
            ),
          ),
  );

  Widget _addressCard(CustomerAddress address) => Card(
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: () => _select(address),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 2),
              child: Icon(Icons.location_on_outlined, color: AppColors.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        address.fullName.isEmpty
                            ? 'Người nhận'
                            : address.fullName,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      if (address.isDefaultShipping)
                        const _AddressTag(label: 'Mặc định'),
                      if (address.addressName.isNotEmpty)
                        _AddressTag(label: address.addressName),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    address.phone,
                    style: const TextStyle(color: AppColors.textMuted),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    address.formattedAddress,
                    style: const TextStyle(height: 1.35),
                  ),
                ],
              ),
            ),
            PopupMenuButton<String>(
              enabled: _busyId == null,
              onSelected: (value) => value == 'edit'
                  ? _editAddress(address)
                  : _deleteAddress(address),
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'edit', child: Text('Sửa')),
                PopupMenuItem(value: 'delete', child: Text('Xóa')),
              ],
            ),
          ],
        ),
      ),
    ),
  );

  Widget _errorState() => AppStateView(
    title: 'Chưa tải được sổ địa chỉ',
    description: _error,
    icon: Icons.cloud_off_outlined,
    actionLabel: 'Thử lại',
    onAction: _load,
  );

  Widget _emptyState() => RefreshIndicator(
    onRefresh: _load,
    child: ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(28, 40, 28, 100),
      children: const [
        SizedBox(height: 90),
        Icon(Icons.location_off_outlined, size: 54, color: AppColors.textMuted),
        SizedBox(height: 14),
        Text(
          'Bạn chưa lưu địa chỉ nào',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
        SizedBox(height: 8),
        Text(
          'Thêm địa chỉ Việt Nam để dùng khi đặt hàng.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.textMuted),
        ),
      ],
    ),
  );
}

class _AddressTag extends StatelessWidget {
  const _AddressTag({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
    decoration: BoxDecoration(
      color: AppColors.primarySoft,
      borderRadius: BorderRadius.circular(7),
    ),
    child: Text(
      label,
      style: const TextStyle(
        color: AppColors.primary,
        fontSize: 11,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}
