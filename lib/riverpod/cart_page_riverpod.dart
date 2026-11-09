import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/cart.dart';
import '../widgets/cart_body.dart';
import '../widgets/coupon_field.dart';
import 'cart_notifier.dart';
import 'cart_summary.dart';

class RiverpodCartPage extends ConsumerWidget {
  const RiverpodCartPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(cartProvider.select((s) => s.status), (prev, next) {
      if (next == CheckoutStatus.success) {
        final id = ref.read(cartProvider).orderId;
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Order $id placed')));
      }
    });

    final state = ref.watch(cartProvider);
    final canUndo = ref.watch(canUndoProvider);
    final cart = ref.read(cartProvider.notifier);
    final submitting = state.status == CheckoutStatus.submitting;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cart · Riverpod'),
        actions: [
          IconButton(
            icon: const Icon(Icons.undo),
            tooltip: 'Undo',
            onPressed: canUndo ? cart.undo : null,
          ),
        ],
      ),
      body: Column(
        children: [
          if (state.status == CheckoutStatus.failure)
            MaterialBanner(
              content: Text(state.checkoutError ?? 'Checkout failed'),
              actions: [
                TextButton(
                  onPressed: cart.dismissBanner,
                  child: const Text('Dismiss'),
                ),
              ],
            ),
          Expanded(
            child: CartBody(
              lines: state.lines,
              onAdd: cart.add,
              onQtyChanged: cart.changeQty,
            ),
          ),
          CouponField(error: state.couponError, onApply: cart.applyCoupon),
          const CartSummary(),
          Padding(
            padding: const EdgeInsets.all(12),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: submitting || state.lines.isEmpty
                    ? null
                    : cart.checkout,
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
