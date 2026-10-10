import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

import 'package:flutter/services.dart';

import '../models/customer_address.dart';
import '../services/medusa_service.dart';
import '../widgets/app_components.dart';

class AddressFormScreen extends StatefulWidget {
  const AddressFormScreen({super.key, required this.service, this.address});

  final MedusaService service;
  final CustomerAddress? address;

  @override
  State<AddressFormScreen> createState() => _AddressFormScreenState();
}

class _AddressFormScreenState extends State<AddressFormScreen> {
  static const _fieldLimits = {
    'addressName': 50,
    'firstName': 100,
    'lastName': 100,
    'phone': 20,
    'province': 100,
    'district': 100,
    'ward': 100,
    'addressLine': 255,
    'postalCode': 6,
  };

  final _formKey = GlobalKey<FormState>();
  late final Map<String, TextEditingController> _controllers;
  final Map<String, String> _errors = {};
  bool _isSaving = false;
  bool _isDefaultShipping = false;
  String? _formError;

  @override
  void initState() {
    super.initState();
    final address = widget.address;
    _controllers = {
      'addressName': TextEditingController(text: address?.addressName ?? ''),
      'firstName': TextEditingController(text: address?.firstName ?? ''),
      'lastName': TextEditingController(text: address?.lastName ?? ''),
      'phone': TextEditingController(text: address?.phone ?? ''),
      'province': TextEditingController(text: address?.province ?? ''),
      'district': TextEditingController(text: address?.district ?? ''),
      'ward': TextEditingController(text: address?.ward ?? ''),
      'addressLine': TextEditingController(text: address?.addressLine ?? ''),
      'postalCode': TextEditingController(text: address?.postalCode ?? ''),
    };
    _isDefaultShipping = address?.isDefaultShipping ?? false;
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  CustomerAddress _buildAddress() {
    final original = widget.address;
    return CustomerAddress(
      id: original?.id,
      addressName: _controllers['addressName']!.text,
      firstName: _controllers['firstName']!.text,
      lastName: _controllers['lastName']!.text,
      phone: _controllers['phone']!.text,
      province: _controllers['province']!.text,
      district: _controllers['district']!.text,
      ward: _controllers['ward']!.text,
      addressLine: _controllers['addressLine']!.text,
      postalCode: _controllers['postalCode']!.text,
      isDefaultShipping: _isDefaultShipping,
      isDefaultBilling: original?.isDefaultBilling ?? false,
    );
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    final address = _buildAddress();
    final errors = address.validate();
    if (errors.isNotEmpty) {
      setState(() {
        _errors
          ..clear()
          ..addAll(errors);
        _formError = null;
      });
      return;
    }
    setState(() {
      _isSaving = true;
      _formError = null;
    });
    try {
      final saved = address.id == null
          ? await widget.service.createCustomerAddress(address)
          : await widget.service.updateCustomerAddress(address);
      if (mounted) Navigator.pop(context, saved);
    } catch (error) {
      if (mounted) setState(() => _formError = error.toString());
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.address != null;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.canvas,
        title: Text(editing ? 'Sửa địa chỉ' : 'Thêm địa chỉ'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
          children: [
            AppPageHeading(
              eyebrow: editing ? 'Sổ địa chỉ' : 'Thông tin giao hàng',
              title: editing ? 'Cập nhật địa chỉ' : 'Thêm địa chỉ mới',
              subtitle: 'Nhập địa chỉ nhận hàng tại Việt Nam.',
            ),
            const SizedBox(height: AppSpacing.xl),
            const Text(
              'THÔNG TIN NGƯỜI NHẬN',
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 12),
            _field('addressName', 'Nhãn địa chỉ (tùy chọn)', hint: 'Nhà riêng'),
            Row(
              children: [
                Expanded(child: _field('firstName', 'Tên')),
                const SizedBox(width: 12),
                Expanded(child: _field('lastName', 'Họ')),
              ],
            ),
            _field(
              'phone',
              'Số điện thoại',
              keyboardType: TextInputType.phone,
              hint: '0912345678',
            ),
            const SizedBox(height: 18),
            const Text(
              'ĐỊA CHỈ TẠI VIỆT NAM',
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 12),
            _field('province', 'Tỉnh / thành phố'),
            _field('district', 'Quận / huyện'),
            _field('ward', 'Phường / xã'),
            _field('addressLine', 'Số nhà, tên đường'),
            _field(
              'postalCode',
              'Mã bưu chính (tùy chọn)',
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 8),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              value: _isDefaultShipping,
              title: const Text('Đặt làm địa chỉ giao hàng mặc định'),
              onChanged: _isSaving
                  ? null
                  : (value) => setState(() => _isDefaultShipping = value),
            ),
            if (_formError != null) ...[
              const SizedBox(height: 8),
              Text(_formError!, style: const TextStyle(color: AppColors.error)),
            ],
            const SizedBox(height: 16),
            SizedBox(
              height: 52,
              child: FilledButton(
                onPressed: _isSaving ? null : _save,
                child: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(editing ? 'Lưu thay đổi' : 'Lưu địa chỉ'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(
    String key,
    String label, {
    String? hint,
    TextInputType? keyboardType,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextField(
      controller: _controllers[key],
      enabled: !_isSaving,
      keyboardType: keyboardType,
      inputFormatters: [LengthLimitingTextInputFormatter(_fieldLimits[key]!)],
      textCapitalization: TextCapitalization.words,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        errorText: _errors[key],
        filled: true,
        fillColor: Colors.white,
      ),
      onChanged: (_) {
        if (_errors.containsKey(key) || _formError != null) {
          setState(() {
            _errors.remove(key);
            _formError = null;
          });
        }
      },
    ),
  );
}
