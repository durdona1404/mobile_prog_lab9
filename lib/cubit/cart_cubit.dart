import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/cart.dart';
import '../services/checkout_api.dart';

class CartCubit extends Cubit<CartState> {
  CartCubit(this._api) : super(const CartState());

  final CheckoutApi _api;
  final List<CartState> _history = [];

  void _mutate(CartState next) {
    if (next == state) return;
    _history.add(state);
    emit(next.copyWith(canUndo: true));
  }

  void add(Product p) => _mutate(state.copyWith(lines: state.lines.withProduct(p)));

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
    final previous = _history.removeLast();
    emit(previous.copyWith(canUndo: _history.isNotEmpty));
  }

  void dismissBanner() =>
      emit(state.copyWith(status: CheckoutStatus.idle, checkoutError: null));

  Future<void> checkout() async {
    if (state.lines.isEmpty || state.status == CheckoutStatus.submitting) return;
    final total = state.total;
    emit(state.copyWith(
      status: CheckoutStatus.submitting,
      orderId: null,
      checkoutError: null,
    ));
    try {
      final id = await _api.submit(total);
      if (isClosed) return;
      emit(state.copyWith(
        lines: const [],
        coupon: null,
        couponError: null,
        status: CheckoutStatus.success,
        orderId: id,
      ));
    } on CheckoutException catch (e) {
      if (isClosed) return;
      emit(state.copyWith(status: CheckoutStatus.failure, checkoutError: e.message));
    }
  }
}