import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/cart.dart';
import '../services/checkout_api.dart';
import '../widgets/cart_body.dart';
import '../widgets/coupon_field.dart';
import 'cart_bloc.dart';
import 'cart_event.dart';
import 'cart_summary.dart';

class BlocCartPage extends StatelessWidget {
  const BlocCartPage({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(
        create: (_) => CartBloc(CheckoutApi()),
        child: const _CartView(),
      );
}

class _CartView extends StatelessWidget {
  const _CartView();

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<CartBloc>();
    return BlocListener<CartBloc, CartState>(
      listenWhen: (p, c) => p.status != c.status,
      listener: (context, state) {
        if (state.status == CheckoutStatus.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Order ${state.orderId} placed')),
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Cart · Bloc'),
          actions: [
            BlocSelector<CartBloc, CartState, bool>(
              selector: (s) => s.history.isNotEmpty,
              builder: (context, canUndo) => IconButton(
                icon: const Icon(Icons.undo),
                tooltip: 'Undo',
                onPressed: canUndo ? () => bloc.add(const CartUndone()) : null,
              ),
            ),
          ],
        ),
        body: Column(children: [
          BlocBuilder<CartBloc, CartState>(
            buildWhen: (p, c) => p.status != c.status || p.checkoutError != c.checkoutError,
            builder: (context, state) => state.status == CheckoutStatus.failure
                ? MaterialBanner(
                    content: Text(state.checkoutError ?? 'Checkout failed'),
                    actions: [
                      TextButton(
                        onPressed: () => bloc.add(const CartBannerDismissed()),
                        child: const Text('Dismiss'),
                      ),
                    ],
                  )
                : const SizedBox.shrink(),
          ),
          Expanded(
            child: BlocSelector<CartBloc, CartState, List<CartLine>>(
              selector: (s) => s.lines,
              builder: (context, lines) => CartBody(
                lines: lines,
                onAdd: (p) => bloc.add(CartProductAdded(p)),
                onQtyChanged: (id, delta) => bloc.add(CartQtyChanged(id, delta)),
              ),
            ),
          ),
          BlocSelector<CartBloc, CartState, String?>(
            selector: (s) => s.couponError,
            builder: (context, error) => CouponField(
              error: error,
              onApply: (code) => bloc.add(CartCouponApplied(code)),
            ),
          ),
          const BlocSummary(),
          Padding(
            padding: const EdgeInsets.all(12),
            child: SizedBox(
              width: double.infinity,
              child: BlocSelector<CartBloc, CartState, (bool, bool)>(
                selector: (s) => (s.status == CheckoutStatus.submitting, s.lines.isEmpty),
                builder: (context, v) => FilledButton(
                  onPressed: v.$1 || v.$2 ? null : () => bloc.add(const CartCheckoutRequested()),
                  child: v.$1
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Checkout'),
                ),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}