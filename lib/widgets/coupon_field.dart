import 'package:flutter/material.dart';

class CouponField extends StatefulWidget {
  const CouponField({super.key, required this.onApply, this.error});

  final void Function(String code) onApply;
  final String? error;

  @override
  State<CouponField> createState() => _CouponFieldState();
}

class _CouponFieldState extends State<CouponField> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: TextField(
            controller: _controller,
            decoration: InputDecoration(
              labelText: 'Coupon code',
              errorText: widget.error,
              isDense: true,
            ),
          ),
        ),
        const SizedBox(width: 8),
        FilledButton(
          onPressed: () => widget.onApply(_controller.text),
          child: const Text('Apply'),
        ),
      ],
    ),
  );
}
