import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/cart.dart';
import '../services/checkout_api.dart';
import 'cart_event.dart';

bool isUndoable(CartEvent event) => switch (event) {
      CartProductAdded() || CartQtyChanged() || CartCouponApplied() => true,
      CartCheckoutRequested() || CartUndone() || CartBannerDismissed() => false,
    };

class CartBloc extends Bloc<CartEvent, CartState> {
  CartBloc(this._api) : super(const CartState()) {
    on<CartProductAdded>(
      (event, emit) => _mutate(emit, state.copyWith(lines: state.lines.withProduct(event.product))),
    );
    on<CartQtyChanged>(
      (event, emit) =>
          _mutate(emit, state.copyWith(lines: state.lines.changeQty(event.productId, event.delta))),
    );
    on<CartCouponApplied>(_onCoupon);
    on<CartUndone>(_onUndo);
    on<CartBannerDismissed>(
      (event, emit) => emit(state.copyWith(status: CheckoutStatus.idle, checkoutError: null)),
    );
    on<CartCheckoutRequested>(_onCheckout, transformer: droppable());
  }

  final CheckoutApi _api;

  void _mutate(Emitter<CartState> emit, CartState next) {
    if (next == state) return;
    final snapshot = state.copyWith(history: const []);
    emit(next.copyWith(history: [...state.history, snapshot]));
  }

  void _onCoupon(CartCouponApplied event, Emitter<CartState> emit) {
    final c = event.code.trim().toUpperCase();
    if (c == 'SAVE10') {
      _mutate(emit, state.copyWith(coupon: c, couponError: null));
    } else {
      _mutate(emit, state.copyWith(couponError: 'Invalid coupon code'));
    }
  }

  void _onUndo(CartUndone event, Emitter<CartState> emit) {
    if (state.history.isEmpty || state.status == CheckoutStatus.submitting) return;
    final previous = state.history.last;
    emit(previous.copyWith(history: state.history.sublist(0, state.history.length - 1)));
  }

  Future<void> _onCheckout(CartCheckoutRequested event, Emitter<CartState> emit) async {
    if (state.lines.isEmpty) return;
    final total = state.total;
    emit(state.copyWith(
      status: CheckoutStatus.submitting,
      orderId: null,
      checkoutError: null,
    ));
    try {
      final id = await _api.submit(total);
      if (emit.isDone) return;
      emit(state.copyWith(
        lines: const [],
        coupon: null,
        couponError: null,
        status: CheckoutStatus.success,
        orderId: id,
      ));
    } on CheckoutException catch (ex) {
      if (emit.isDone) return;
      emit(state.copyWith(status: CheckoutStatus.failure, checkoutError: ex.message));
    }
  }
}