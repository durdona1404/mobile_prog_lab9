import 'package:flutter/material.dart';

class SummaryCard extends StatelessWidget {
  const SummaryCard({
    super.key,
    required this.itemCount,
    required this.subtotal,
    required this.discount,
    required this.total,
  });

  final int itemCount;
  final double subtotal;
  final double discount;
  final double total;

  Widget _row(String label, String value, {bool bold = false}) {
    final style = bold ? const TextStyle(fontWeight: FontWeight.bold) : null;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: style),
          Text(value, style: style),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          _row('Items', '$itemCount'),
          _row('Subtotal', subtotal.toStringAsFixed(2)),
          _row(
            'Discount',
            discount > 0 ? '-${discount.toStringAsFixed(2)}' : '0.00',
          ),
          _row('Total', total.toStringAsFixed(2), bold: true),
        ],
      ),
    ),
  );
}
