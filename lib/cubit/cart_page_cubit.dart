import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/cart.dart';
import '../services/checkout_api.dart';
import '../widgets/cart_body.dart';
import '../widgets/coupon_field.dart';
import 'cart_cubit.dart';
import 'cart_summary.dart';

class CubitCartPage extends StatelessWidget {
  const CubitCartPage({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(
        create: (_) => CartCubit(CheckoutApi()),
        child: const _CartView(),
      );
}

class _CartView extends StatelessWidget {
  const _CartView();

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<CartCubit>();
    return BlocListener<CartCubit, CartState>(
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
          title: const Text('Cart · Cubit'),
          actions: [
            BlocSelector<CartCubit, CartState, bool>(
              selector: (s) => s.canUndo,
              builder: (context, canUndo) => IconButton(
                icon: const Icon(Icons.undo),
                tooltip: 'Undo',
                onPressed: canUndo ? cubit.undo : null,
              ),
            ),
          ],
        ),
        body: Column(children: [
          BlocBuilder<CartCubit, CartState>(
            buildWhen: (p, c) => p.status != c.status || p.checkoutError != c.checkoutError,
            builder: (context, state) => state.status == CheckoutStatus.failure
                ? MaterialBanner(
                    content: Text(state.checkoutError ?? 'Checkout failed'),
                    actions: [
                      TextButton(onPressed: cubit.dismissBanner, child: const Text('Dismiss')),
                    ],
                  )
                : const SizedBox.shrink(),
          ),
          Expanded(
            child: BlocSelector<CartCubit, CartState, List<CartLine>>(
              selector: (s) => s.lines,
              builder: (context, lines) =>
                  CartBody(lines: lines, onAdd: cubit.add, onQtyChanged: cubit.changeQty),
            ),
          ),
          BlocSelector<CartCubit, CartState, String?>(
            selector: (s) => s.couponError,
            builder: (context, error) =>
                CouponField(error: error, onApply: cubit.applyCoupon),
          ),
          const CubitSummary(),
          Padding(
            padding: const EdgeInsets.all(12),
            child: SizedBox(
              width: double.infinity,
              child: BlocSelector<CartCubit, CartState, (bool, bool)>(
                selector: (s) => (s.status == CheckoutStatus.submitting, s.lines.isEmpty),
                builder: (context, v) => FilledButton(
                  onPressed: v.$1 || v.$2 ? null : cubit.checkout,
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