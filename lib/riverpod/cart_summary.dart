import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../widgets/summary_card.dart';
import 'cart_notifier.dart';

class CartSummary extends ConsumerWidget {
  const CartSummary({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    debugPrint('CartSummary rebuilt');
    final v = ref.watch(
      cartProvider.select(
        (s) => (s.itemCount, s.subtotal, s.discount, s.total),
      ),
    );
    return SummaryCard(
      itemCount: v.$1,
      subtotal: v.$2,
      discount: v.$3,
      total: v.$4,
    );
  }
}
