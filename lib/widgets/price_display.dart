import 'package:flutter/material.dart';

class PriceDisplay extends StatelessWidget {
  final double price;
  final bool showLabel;
  final TextStyle? textStyle;

  const PriceDisplay({
    super.key,
    required this.price,
    this.showLabel = true,
    this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.attach_money,
          size: 16,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(width: 2),
        Text(
          showLabel ? '₽${price.toStringAsFixed(0)}' : '${price.toStringAsFixed(0)} ₽',
          style: textStyle ?? Theme.of(context).textTheme.titleSmall?.copyWith(
            color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
