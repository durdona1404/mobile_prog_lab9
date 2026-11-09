import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/cart.dart';
import '../services/checkout_api.dart';

final checkoutApiProvider = Provider<CheckoutApi>((ref) => CheckoutApi());

class CartNotifier extends Notifier<CartState> {
  final List<CartState> _history = [];

  @override
  CartState build() => const CartState();

  bool get canUndo => _history.isNotEmpty;

  void _mutate(CartState next) {
    if (next == state) return;
    _history.add(state);
    state = next;
  }

  void add(Product p) =>
      _mutate(state.copyWith(lines: state.lines.withProduct(p)));

  void changeQty(String id, int delta) =>
      _mutate(state.copyWith(lines: state.lines.changeQty(id, delta)));

  void applyCoupon(String code) {
    final c = code.trim().toUpperCase();
    if (c == 'SAVE10') {
      _mutate(state.copyWith(coupon: c, couponError: null));
    } else {
      _mutate(state.copyWith(couponError: 'Invalid coupon code'));
    }
  }

  void undo() {
    if (_history.isEmpty || state.status == CheckoutStatus.submitting) return;
    state = _history.removeLast();
  }

  void dismissBanner() {
    state = state.copyWith(status: CheckoutStatus.idle, checkoutError: null);
  }

  Future<void> checkout() async {
    if (state.lines.isEmpty || state.status == CheckoutStatus.submitting) {
      return;
    }
    final total = state.total;
    state = state.copyWith(
      status: CheckoutStatus.submitting,
      orderId: null,
      checkoutError: null,
    );
    try {
      final id = await ref.read(checkoutApiProvider).submit(total);
      state = state.copyWith(
        lines: const [],
        coupon: null,
        couponError: null,
        status: CheckoutStatus.success,
        orderId: id,
      );
    } on CheckoutException catch (e) {
      state = state.copyWith(
        status: CheckoutStatus.failure,
        checkoutError: e.message,
      );
    }
  }
}

final cartProvider = NotifierProvider<CartNotifier, CartState>(
  CartNotifier.new,
);

final canUndoProvider = Provider<bool>((ref) {
  ref.watch(cartProvider);
  return ref.read(cartProvider.notifier).canUndo;
});
