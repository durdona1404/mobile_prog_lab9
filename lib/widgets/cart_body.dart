import 'package:flutter/material.dart';

import '../models/cart.dart';

class CartBody extends StatelessWidget {
  const CartBody({
    super.key,
    required this.lines,
    required this.onAdd,
    required this.onQtyChanged,
  });

  final List<CartLine> lines;
  final void Function(Product) onAdd;
  final void Function(String productId, int delta) onQtyChanged;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Padding(
        padding: const EdgeInsets.all(12),
        child: Wrap(
          spacing: 8,
          children: [
            for (final p in catalog)
              ActionChip(
                label: Text('${p.name} · ${p.price.toStringAsFixed(0)}'),
                onPressed: () => onAdd(p),
              ),
          ],
        ),
      ),
      Expanded(
        child: lines.isEmpty
            ? const Center(child: Text('Cart is empty'))
            : ListView(
                children: [
                  for (final l in lines)
                    ListTile(
                      key: ValueKey(l.product.id),
                      title: Text(l.product.name),
                      subtitle: Text('× ${l.qty}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline),
                            onPressed: () => onQtyChanged(l.product.id, -1),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add_circle_outline),
                            onPressed: () => onQtyChanged(l.product.id, 1),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
      ),
    ],
  );
}
