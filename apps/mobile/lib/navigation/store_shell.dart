import 'package:flutter/material.dart';

import '../screens/cart_screen.dart';
import '../screens/home_screen.dart';
import '../screens/order_history_screen.dart';
import '../screens/profile_screen.dart';
import '../services/cart_storage.dart';
import '../services/medusa_service.dart';

class StoreShell extends StatefulWidget {
  const StoreShell({super.key, this.service, this.storage});

  final MedusaService? service;
  final CartStorage? storage;

  @override
  State<StoreShell> createState() => _StoreShellState();
}

class _StoreShellState extends State<StoreShell> {
  late final MedusaService _service;
  late final CartStorage _cartStorage;
  int _selectedIndex = 0;
  int _cartRevision = 0;
  String? _cartId;

  @override
  void initState() {
    super.initState();
    _service = widget.service ?? MedusaService.instance;
    _cartStorage = widget.storage ?? CartStorage.instance;
    _restoreCartId();
  }

  Future<void> _restoreCartId() async {
    try {
      final cartId = await _cartStorage.readCartId();
      if (mounted) _updateCartId(cartId);
    } catch (_) {
      // The cart screen can still recover through its own retry state.
    }
  }

  void _updateCartId(String? cartId) {
    if (_cartId == cartId) return;
    setState(() => _cartId = cartId);
  }

  void _refreshCart(String cartId) {
    setState(() {
      _cartId = cartId;
      _cartRevision++;
    });
  }

  void _selectTab(int index) {
    if (index == _selectedIndex) return;
    setState(() => _selectedIndex = index);
  }

  List<Widget> get _pages => [
    HomeScreen(
      service: _service,
      storage: _cartStorage,
      onOpenCart: () => _selectTab(1),
      onOpenProfile: () => _selectTab(3),
      onCartIdChanged: _updateCartId,
      onCartContentsChanged: _refreshCart,
    ),
    CartScreen(
      cartId: _cartId,
      cartRevision: _cartRevision,
      service: _service,
      storage: _cartStorage,
      onCartIdChanged: _updateCartId,
      onContinueShopping: () => _selectTab(0),
    ),
    OrderHistoryScreen(service: _service),
    ProfileScreen(service: _service),
  ];

  @override
  Widget build(BuildContext context) {
    final destinations = const [
      NavigationDestination(
        icon: Icon(Icons.explore_outlined),
        selectedIcon: Icon(Icons.explore),
        label: 'Khám phá',
      ),
      NavigationDestination(
        icon: Icon(Icons.shopping_bag_outlined),
        selectedIcon: Icon(Icons.shopping_bag),
        label: 'Giỏ hàng',
      ),
      NavigationDestination(
        icon: Icon(Icons.receipt_long_outlined),
        selectedIcon: Icon(Icons.receipt_long),
        label: 'Đơn hàng',
      ),
      NavigationDestination(
        icon: Icon(Icons.person_outline),
        selectedIcon: Icon(Icons.person),
        label: 'Tài khoản',
      ),
    ];
    final pages = _pages;

    return LayoutBuilder(
      builder: (context, constraints) {
        final useRail = constraints.maxWidth >= 900;
        final content = IndexedStack(index: _selectedIndex, children: pages);
        if (!useRail) {
          return Scaffold(
            body: content,
            bottomNavigationBar: NavigationBar(
              selectedIndex: _selectedIndex,
              onDestinationSelected: _selectTab,
              destinations: destinations,
            ),
          );
        }

        return Scaffold(
          body: Row(
            children: [
              NavigationRail(
                selectedIndex: _selectedIndex,
                onDestinationSelected: _selectTab,
                labelType: NavigationRailLabelType.all,
                destinations: const [
                  NavigationRailDestination(
                    icon: Icon(Icons.explore_outlined),
                    selectedIcon: Icon(Icons.explore),
                    label: Text('Khám phá'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.shopping_bag_outlined),
                    selectedIcon: Icon(Icons.shopping_bag),
                    label: Text('Giỏ hàng'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.receipt_long_outlined),
                    selectedIcon: Icon(Icons.receipt_long),
                    label: Text('Đơn hàng'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.person_outline),
                    selectedIcon: Icon(Icons.person),
                    label: Text('Tài khoản'),
                  ),
                ],
              ),
              const VerticalDivider(width: 1),
              Expanded(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1440),
                    child: content,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
