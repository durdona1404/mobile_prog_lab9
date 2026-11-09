import 'package:flutter/material.dart';

import '../models/cart.dart';
import '../services/checkout_api.dart';
import '../widgets/cart_body.dart';
import '../widgets/coupon_field.dart';
import '../widgets/summary_card.dart';

class SetStateCartPage extends StatefulWidget {
  const SetStateCartPage({super.key});

  @override
  State<SetStateCartPage> createState() => _SetStateCartPageState();
}

class _SetStateCartPageState extends State<SetStateCartPage> {
  final _api = CheckoutApi();
  CartState _state = const CartState();
  final List<CartState> _history = [];

  void _mutate(CartState next) => setState(() {
    _history.add(_state);
    _state = next;
  });

  void _add(Product p) =>
      _mutate(_state.copyWith(lines: _state.lines.withProduct(p)));

  void _changeQty(String id, int delta) =>
      _mutate(_state.copyWith(lines: _state.lines.changeQty(id, delta)));

  void _applyCoupon(String code) {
    final c = code.trim().toUpperCase();
    if (c == 'SAVE10') {
      _mutate(_state.copyWith(coupon: c, couponError: null));
    } else {
      _mutate(_state.copyWith(couponError: 'Invalid coupon code'));
    }
  }

  void _undo() => setState(() => _state = _history.removeLast());

  void _dismissBanner() => setState(
    () => _state = _state.copyWith(
      status: CheckoutStatus.idle,
      checkoutError: null,
    ),
  );

  Future<void> _checkout() async {
    if (_state.lines.isEmpty || _state.status == CheckoutStatus.submitting) {
      return;
    }
    final total = _state.total;
    setState(
      () => _state = _state.copyWith(
        status: CheckoutStatus.submitting,
        orderId: null,
        checkoutError: null,
      ),
    );
    try {
      final id = await _api.submit(total);
      if (!mounted) return;
      setState(
        () => _state = _state.copyWith(
          lines: const [],
          coupon: null,
          couponError: null,
          status: CheckoutStatus.success,
          orderId: id,
        ),
      );
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Order $id placed')));
    } on CheckoutException catch (e) {
      if (!mounted) return;
      setState(
        () => _state = _state.copyWith(
          status: CheckoutStatus.failure,
          checkoutError: e.message,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final submitting = _state.status == CheckoutStatus.submitting;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cart · setState'),
        actions: [
          IconButton(
            icon: const Icon(Icons.undo),
            tooltip: 'Undo',
            onPressed: _history.isEmpty ? null : _undo,
          ),
        ],
      ),
      body: Column(
        children: [
          if (_state.status == CheckoutStatus.failure)
            MaterialBanner(
              content: Text(_state.checkoutError ?? 'Checkout failed'),
              actions: [
                TextButton(
                  onPressed: _dismissBanner,
                  child: const Text('Dismiss'),
                ),
              ],
            ),
          Expanded(
            child: CartBody(
              lines: _state.lines,
              onAdd: _add,
              onQtyChanged: _changeQty,
            ),
          ),
          CouponField(error: _state.couponError, onApply: _applyCoupon),
          SummaryCard(
            itemCount: _state.itemCount,
            subtotal: _state.subtotal,
            discount: _state.discount,
            total: _state.total,
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: submitting || _state.lines.isEmpty
                    ? null
                    : _checkout,
                child: submitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Checkout'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
