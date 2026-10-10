import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/customer.dart';
import '../models/customer_address.dart';
import '../models/customer_order.dart';
import '../models/payment_provider.dart';
import '../models/shipping_option.dart';
import '../services/cart_storage.dart';
import '../services/medusa_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_components.dart';
import 'address_book_screen.dart';
import 'login_screen.dart';
import 'order_history_screen.dart';
import 'order_success_screen.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({
    super.key,
    required this.cartId,
    this.service,
    this.storage,
    this.onCartIdChanged,
  });

  final String cartId;
  final MedusaService? service;
  final CartStorage? storage;
  final ValueChanged<String?>? onCartIdChanged;

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  late final MedusaService _service;
  late final CartStorage _storage;
  Map<String, dynamic>? _cart;
  Customer? _customer;
  List<CustomerAddress> _addresses = const [];
  List<ShippingOption> _shippingOptions = const [];
  CustomerAddress? _selectedAddress;
  String? _selectedShippingId;
  PaymentProvider? _codProvider;
  bool _isLoading = true;
  bool _isLoadingAddresses = false;
  bool _isLoadingShipping = false;
  bool _isUpdatingShipping = false;
  bool _isSubmitting = false;
  bool _completionUncertain = false;
  String? _error;
  String? _addressError;
  String? _shippingError;
  String? _paymentError;

  List<Map<String, dynamic>> get _items {
    final raw = _cart?['items'];
    if (raw is! List) return const [];
    return raw.whereType<Map>().map(Map<String, dynamic>.from).toList();
  }

  String get _currencyCode =>
      _cart?['currency_code']?.toString().toUpperCase() ?? 'VND';

  NumberFormat get _money => NumberFormat.currency(
    locale: 'vi_VN',
    name: _currencyCode,
    decimalDigits: _currencyCode == 'VND' ? 0 : null,
  );

  @override
  void initState() {
    super.initState();
    _service = widget.service ?? MedusaService.instance;
    _storage = widget.storage ?? CartStorage.instance;
    _loadCheckout();
  }

  Future<void> _loadCheckout() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final cart = await _service.getCart(widget.cartId);
      final customer = await _service.getCurrentCustomer();
      if (!mounted) return;
      setState(() {
        _cart = cart;
        _customer = customer;
        _isLoading = false;
      });
      if (customer == null) return;
      await _loadAddresses();
      if (!mounted) return;
      await _loadPaymentProvider(cart['region_id']?.toString());
      if (!mounted || _addresses.isEmpty) return;
      final cartAddress = cart['shipping_address'];
      CustomerAddress? matchingAddress;
      if (cartAddress is Map) {
        final saved = CustomerAddress.fromJson(
          Map<String, dynamic>.from(cartAddress),
        );
        for (final address in _addresses) {
          if (address.phone == saved.phone &&
              address.addressLine == saved.addressLine &&
              address.province == saved.province) {
            matchingAddress = address;
            break;
          }
        }
      }
      final address =
          matchingAddress ??
          _addresses.where((item) => item.isDefaultShipping).firstOrNull ??
          _addresses.first;
      await _applyAddress(address, showErrors: false);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadAddresses() async {
    setState(() {
      _isLoadingAddresses = true;
      _addressError = null;
    });
    try {
      final addresses = await _service.getCustomerAddresses();
      if (mounted) setState(() => _addresses = addresses);
    } catch (error) {
      if (mounted) setState(() => _addressError = error.toString());
    } finally {
      if (mounted) setState(() => _isLoadingAddresses = false);
    }
  }

  Future<void> _loadPaymentProvider(String? regionId) async {
    if (regionId == null || regionId.isEmpty) {
      setState(() => _paymentError = 'Giỏ hàng chưa có region.');
      return;
    }
    try {
      final providers = await _service.getPaymentProviders(regionId);
      final system = providers.where((provider) => provider.isSystem);
      if (mounted) {
        setState(() {
          _codProvider = system.isEmpty ? null : system.first;
          _paymentError = system.isEmpty
              ? 'Medusa chưa bật phương thức COD cho region này.'
              : null;
        });
      }
    } catch (error) {
      if (mounted) setState(() => _paymentError = error.toString());
    }
  }

  Future<void> _openLogin() async {
    final signedIn = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => LoginScreen(service: _service)),
    );
    if (signedIn == true && mounted) await _loadCheckout();
  }

  Future<void> _openAddressBook() async {
    final address = await Navigator.push<CustomerAddress>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            AddressBookScreen(service: _service, selectionMode: true),
      ),
    );
    if (address != null && mounted) await _applyAddress(address);
  }

  Future<void> _applyAddress(
    CustomerAddress address, {
    bool showErrors = true,
  }) async {
    final customer = _customer;
    if (customer == null) return;
    setState(() {
      _selectedAddress = address;
      _selectedShippingId = null;
      _shippingOptions = const [];
      _shippingError = null;
      _isLoadingShipping = true;
    });
    try {
      final cart = await _service.attachCustomerAddressToCart(
        cartId: widget.cartId,
        customer: customer,
        address: address,
      );
      final options = await _service.getShippingOptions(
        widget.cartId,
        currencyCode: cart['currency_code']?.toString(),
      );
      if (!mounted) return;
      setState(() {
        _cart = cart;
        _shippingOptions = options;
        _isLoadingShipping = false;
        _shippingError = options.isEmpty
            ? 'Không có phương thức giao hàng cho địa chỉ này.'
            : null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _shippingError = error.toString();
        _isLoadingShipping = false;
      });
      if (showErrors) _showMessage('Không thể cập nhật địa chỉ: $error');
    }
  }

  Future<void> _chooseShipping(ShippingOption option) async {
    if (_isUpdatingShipping || !option.hasPrice) return;
    setState(() {
      _isUpdatingShipping = true;
      _shippingError = null;
    });
    try {
      final cart = await _service.addShippingMethod(
        cartId: widget.cartId,
        option: option,
      );
      if (mounted) {
        setState(() {
          _cart = cart;
          _selectedShippingId = option.id;
        });
      }
    } catch (error) {
      if (mounted) setState(() => _shippingError = error.toString());
    } finally {
      if (mounted) setState(() => _isUpdatingShipping = false);
    }
  }

  Future<void> _placeOrder() async {
    final provider = _codProvider;
    if (!_canPlaceOrder || provider == null) return;
    setState(() {
      _isSubmitting = true;
      _error = null;
    });
    var completionStarted = false;
    try {
      final latestCart = await _service.getCart(widget.cartId);
      if (!mounted) return;
      setState(() => _cart = latestCart);
      final collectionId = await _service.createPaymentCollection(
        widget.cartId,
      );
      await _service.createPaymentSession(
        collectionId: collectionId,
        providerId: provider.id,
      );
      completionStarted = true;
      final result = await _service.completeCart(widget.cartId);
      if (result['type'] == 'cart') {
        final rawCart = result['cart'];
        final errorData = result['error'];
        final message = errorData is Map
            ? errorData['message']?.toString()
            : null;
        if (mounted) {
          setState(() {
            if (rawCart is Map) _cart = Map<String, dynamic>.from(rawCart);
            _isSubmitting = false;
            _error = message ?? 'Medusa chưa thể hoàn tất giỏ hàng.';
          });
        }
        return;
      }
      final rawOrder = result['order'];
      if (result['type'] != 'order' || rawOrder is! Map) {
        if (mounted) {
          setState(() {
            _completionUncertain = true;
            _isSubmitting = false;
            _error = 'Medusa trả về kết quả chưa xác định. Kiểm tra lịch sử đơn hàng trước khi thử lại.';
          });
        }
        return;
      }
      final order = CustomerOrder.fromJson(Map<String, dynamic>.from(rawOrder));
      if (order.id.isEmpty) {
        if (mounted) {
          setState(() {
            _completionUncertain = true;
            _isSubmitting = false;
            _error = 'Medusa đã báo tạo đơn nhưng thiếu mã đơn. Hãy kiểm tra lịch sử đơn hàng.';
          });
        }
        return;
      }
      String? storageNotice;
      try {
        await _storage.clearCartId();
      } catch (_) {
        storageNotice = 'Đơn đã được Medusa tạo, nhưng thiết bị chưa xóa được mã giỏ hàng cũ.';
      }
      widget.onCartIdChanged?.call(null);
      if (!mounted) return;
      await Navigator.pushReplacement<void, void>(
        context,
        MaterialPageRoute(
          builder: (_) => OrderSuccessScreen(
            order: order,
            service: _service,
            storageNotice: storageNotice,
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      final apiError = error is MedusaApiException ? error : null;
      final unauthorized = apiError?.statusCode == 401;
      final rejected =
          apiError != null &&
          apiError.statusCode != null &&
          apiError.statusCode! >= 400 &&
          apiError.statusCode! < 500 &&
          apiError.statusCode != 409;
      final uncertain = completionStarted && !unauthorized && !rejected;
      setState(() {
        if (unauthorized) _customer = null;
        _completionUncertain = uncertain;
        _isSubmitting = false;
        _error = unauthorized
            ? 'Phiên đăng nhập đã hết hạn. Đăng nhập lại để tiếp tục.'
            : uncertain
            ? 'Chưa xác nhận được kết quả đặt hàng. Hãy kiểm tra lịch sử đơn hàng trước khi thử lại.'
            : error.toString();
      });
    } finally {
      if (mounted && _isSubmitting) setState(() => _isSubmitting = false);
    }
  }

  bool get _canPlaceOrder =>
      _customer != null &&
      _selectedAddress != null &&
      _selectedShippingId != null &&
      _codProvider != null &&
      _items.isNotEmpty &&
      !_isSubmitting &&
      !_completionUncertain;

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Xác nhận đơn hàng')),
    body: _isLoading
        ? const Center(child: CircularProgressIndicator())
        : _error != null && _cart == null
        ? _errorState()
        : _customer == null
        ? _loginRequired()
        : _checkoutBody(),
    bottomNavigationBar: !_isLoading && _cart != null && _customer != null
        ? _checkoutFooter()
        : null,
  );

  Widget _checkoutBody() => RefreshIndicator(
    onRefresh: _loadCheckout,
    child: ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        _CheckoutProgress(
          activeStep: _selectedAddress == null
              ? 0
              : _selectedShippingId == null
              ? 1
              : 2,
        ),
        const SizedBox(height: AppSpacing.md),
        _sectionCard(
          title: 'Địa chỉ nhận hàng',
          icon: Icons.location_on_outlined,
          trailing: TextButton(
            onPressed: _isLoadingAddresses ? null : _openAddressBook,
            child: Text(_selectedAddress == null ? 'Thêm / chọn' : 'Thay đổi'),
          ),
          child: _addressSection(),
        ),
        const SizedBox(height: 12),
        _sectionCard(
          title: 'Phương thức giao hàng',
          icon: Icons.local_shipping_outlined,
          child: _shippingSection(),
        ),
        const SizedBox(height: 12),
        _sectionCard(
          title: 'Thanh toán',
          icon: Icons.payments_outlined,
          child: _paymentSection(),
        ),
        const SizedBox(height: 12),
        _sectionCard(
          title: 'Sản phẩm',
          icon: Icons.shopping_bag_outlined,
          child: _itemsSection(),
        ),
        const SizedBox(height: 12),
        _sectionCard(
          title: 'Tổng đơn hàng',
          icon: Icons.receipt_long_outlined,
          child: _totalsSection(),
        ),
        if (_error != null) ...[
          const SizedBox(height: 12),
          _inlineError(_error!),
          if (_completionUncertain)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: _openOrderHistory,
                icon: const Icon(Icons.receipt_long_outlined),
                label: const Text('Kiểm tra đơn hàng'),
              ),
            ),
        ],
      ],
    ),
  );

  Widget _addressSection() {
    if (_isLoadingAddresses) {
      return const LinearProgressIndicator();
    }
    if (_addressError != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _inlineError(_addressError!),
          TextButton(onPressed: _loadAddresses, child: const Text('Tải lại')),
        ],
      );
    }
    final address = _selectedAddress;
    if (address == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Chọn một địa chỉ đã lưu để tiếp tục.'),
          if (_addresses.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 6),
              child: Text(
                'Bạn chưa lưu địa chỉ nào.',
                style: TextStyle(color: AppColors.textMuted),
              ),
            ),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          address.fullName,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 4),
        Text(address.phone),
        const SizedBox(height: 4),
        Text(address.formattedAddress, style: const TextStyle(height: 1.35)),
      ],
    );
  }

  Widget _shippingSection() {
    if (_selectedAddress == null) return const Text('Chọn địa chỉ trước.');
    if (_isLoadingShipping || _isUpdatingShipping) {
      return const LinearProgressIndicator();
    }
    if (_shippingError != null && _shippingOptions.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _inlineError(_shippingError!),
          TextButton(
            onPressed: () => _selectedAddress == null
                ? null
                : _applyAddress(_selectedAddress!),
            child: const Text('Tải lại phương thức'),
          ),
        ],
      );
    }
    if (_shippingOptions.isEmpty) {
      return const Text('Chưa có phương thức giao hàng.');
    }
    return Column(
      children: [
        for (final option in _shippingOptions)
          Semantics(
            button: option.hasPrice,
            selected: _selectedShippingId == option.id,
            label:
                '${option.name}, ${option.hasPrice ? _money.format(option.amount) : 'Chưa có giá'}',
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: option.hasPrice ? () => _chooseShipping(option) : null,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 9),
                child: Row(
                  children: [
                    Icon(
                      _selectedShippingId == option.id
                          ? Icons.radio_button_checked
                          : Icons.radio_button_unchecked,
                      color: option.hasPrice
                          ? AppColors.primary
                          : AppColors.textMuted,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            option.name,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          if (option.description != null)
                            Text(
                              option.description!,
                              style: const TextStyle(
                                color: AppColors.textMuted,
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      option.hasPrice
                          ? _money.format(option.amount)
                          : 'Chưa có giá',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
            ),
          ),
        if (_shippingError != null) _inlineError(_shippingError!),
      ],
    );
  }

  Widget _paymentSection() {
    if (_codProvider == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _inlineError(_paymentError ?? 'COD chưa khả dụng.'),
          const Text(
            'Đơn hàng chưa được gửi đi. Bật system provider trong region demo để tiếp tục.',
            style: TextStyle(color: AppColors.textMuted),
          ),
        ],
      );
    }
    return const ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(Icons.payments_outlined, color: AppColors.primary),
      title: Text('Thanh toán khi nhận hàng (COD)'),
      subtitle: Text('Trạng thái thanh toán do Medusa trả về.'),
    );
  }

  Widget _itemsSection() => Column(
    children: [
      for (final item in _items)
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  '${item['title'] ?? 'Sản phẩm'} × ${_int(item['quantity'])}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(width: 12),
              Text(_money.format(_amount(item['total'] ?? item['subtotal']))),
            ],
          ),
        ),
      if (_items.isEmpty) const Text('Giỏ hàng đang trống.'),
    ],
  );

  Widget _totalsSection() => Column(
    children: [
      _totalRow('Tạm tính', _cart?['subtotal']),
      if (_amount(_cart?['discount_total']) > 0)
        _totalRow('Ưu đãi', _cart?['discount_total'], negative: true),
      _totalRow('Vận chuyển', _cart?['shipping_total']),
      const Divider(height: 18),
      Row(
        children: [
          const Expanded(
            child: Text(
              'Tổng thanh toán',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
          Text(
            _money.format(_amount(_cart?['total'])),
            style: const TextStyle(
              color: AppColors.price,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
      const SizedBox(height: 7),
      const Align(
        alignment: Alignment.centerLeft,
        child: Text(
          'Tổng tiền lấy từ giỏ hàng Medusa.',
          style: TextStyle(color: AppColors.textMuted, fontSize: 12),
        ),
      ),
      if (_selectedAddress != null && _selectedShippingId == null) ...[
        const SizedBox(height: 7),
        const Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Chọn phương thức giao hàng để cập nhật phí và tổng theo địa chỉ này.',
            style: TextStyle(color: AppColors.warning, fontSize: 12),
          ),
        ),
      ],
    ],
  );

  Widget _totalRow(String label, Object? value, {bool negative = false}) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 7),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(color: AppColors.textMuted),
              ),
            ),
            Text('${negative ? '-' : ''}${_money.format(_amount(value))}'),
          ],
        ),
      );

  Widget _sectionCard({
    required String title,
    required IconData icon,
    Widget? trailing,
    required Widget child,
  }) => AppSurface(
    padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: AppColors.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: Theme.of(context).textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
            ),
            ?trailing,
          ],
        ),
        const Divider(height: 12),
        child,
      ],
    ),
  );

  Widget _checkoutFooter() => Container(
    padding: const EdgeInsets.fromLTRB(18, 12, 18, 12),
    decoration: const BoxDecoration(
      color: AppColors.surface,
      border: Border(top: BorderSide(color: AppColors.border)),
    ),
    child: SafeArea(
      top: false,
      child: AppPrimaryAction(
        onPressed: _canPlaceOrder ? _placeOrder : null,
        isLoading: _isSubmitting,
        label: _completionUncertain ? 'Đang chờ xác minh đơn' : 'Đặt hàng COD',
      ),
    ),
  );

  Widget _loginRequired() => Center(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.lock_outline, size: 50, color: AppColors.primary),
          const SizedBox(height: 14),
          const Text(
            'Đăng nhập để tiếp tục checkout',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          const Text(
            'Địa chỉ và đơn hàng sẽ được lưu trong tài khoản của bạn.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textMuted),
          ),
          const SizedBox(height: 18),
          FilledButton(onPressed: _openLogin, child: const Text('Đăng nhập')),
        ],
      ),
    ),
  );

  Widget _errorState() => Center(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off_outlined, size: 50),
          const SizedBox(height: 12),
          const Text('Chưa tải được checkout'),
          const SizedBox(height: 8),
          Text(_error!, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _loadCheckout,
            icon: const Icon(Icons.refresh),
            label: const Text('Thử lại'),
          ),
        ],
      ),
    ),
  );

  Widget _inlineError(String message) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(11),
    decoration: BoxDecoration(
      color: AppColors.errorSurface,
      borderRadius: BorderRadius.circular(10),
    ),
    child: Text(message, style: const TextStyle(color: AppColors.error)),
  );

  Future<void> _openOrderHistory() async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute(builder: (_) => OrderHistoryScreen(service: _service)),
    );
  }

  int _int(Object? value) =>
      value is num ? value.toInt() : int.tryParse(value?.toString() ?? '') ?? 0;

  num _amount(Object? value) =>
      value is num ? value : num.tryParse(value?.toString() ?? '') ?? 0;
}

class _CheckoutProgress extends StatelessWidget {
  const _CheckoutProgress({required this.activeStep});

  static const _steps = ['Địa chỉ', 'Giao hàng', 'Thanh toán'];

  final int activeStep;

  @override
  Widget build(BuildContext context) => AppSurface(
    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
    child: Row(
      children: [
        for (var index = 0; index < _steps.length; index++)
          Expanded(
            child: Semantics(
              label: 'Bước ${index + 1}: ${_steps[index]}',
              selected: index == activeStep,
              child: Column(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: index <= activeStep
                          ? AppColors.primary
                          : AppColors.imageSurface,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: index < activeStep
                        ? const Icon(
                            Icons.check,
                            size: 16,
                            color: AppColors.surface,
                          )
                        : Text(
                            '${index + 1}',
                            style: TextStyle(
                              color: index == activeStep
                                  ? AppColors.surface
                                  : AppColors.textMuted,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _steps[index],
                    style: TextStyle(
                      color: index == activeStep
                          ? AppColors.primary
                          : AppColors.textMuted,
                      fontSize: 12,
                      fontWeight: index == activeStep
                          ? FontWeight.w700
                          : FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    ),
  );
}
