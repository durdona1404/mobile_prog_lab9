import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/cart.dart';
import '../widgets/summary_card.dart';
import 'cart_cubit.dart';

class CubitSummary extends StatelessWidget {
  const CubitSummary({super.key});

  @override
  Widget build(BuildContext context) {
    debugPrint('CubitSummary rebuilt');
    return BlocSelector<CartCubit, CartState, (int, double, double, double)>(
      selector: (s) => (s.itemCount, s.subtotal, s.discount, s.total),
      builder: (context, v) =>
          SummaryCard(itemCount: v.$1, subtotal: v.$2, discount: v.$3, total: v.$4),
    );
  }
}