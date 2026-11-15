import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/cart.dart';
import '../widgets/summary_card.dart';
import 'cart_bloc.dart';

class BlocSummary extends StatelessWidget {
  const BlocSummary({super.key});

  @override
  Widget build(BuildContext context) {
    debugPrint('BlocSummary rebuilt');
    return BlocSelector<CartBloc, CartState, (int, double, double, double)>(
      selector: (s) => (s.itemCount, s.subtotal, s.discount, s.total),
      builder: (context, v) =>
          SummaryCard(itemCount: v.$1, subtotal: v.$2, discount: v.$3, total: v.$4),
    );
  }
}