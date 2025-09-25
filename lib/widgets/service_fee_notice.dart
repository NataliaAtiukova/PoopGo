import 'package:flutter/material.dart';

class ServiceFeeNotice extends StatelessWidget {
  final VoidCallback onTap;
  final EdgeInsetsGeometry? padding;

  const ServiceFeeNotice({super.key, required this.onTap, this.padding});

  @override
  Widget build(BuildContext context) {
    final infoStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Colors.grey[600],
        ) ??
        TextStyle(
          color: Colors.grey[600],
          fontSize: 12,
        );
    final linkStyle = infoStyle.copyWith(
      color: Theme.of(context).colorScheme.primary,
      decoration: TextDecoration.underline,
      fontWeight: FontWeight.w600,
    );

    final content = Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          'Сервисный сбор составляет 10% за размещение заказа. ',
          style: infoStyle,
        ),
        GestureDetector(
          onTap: onTap,
          child: Text('Подробнее…', style: linkStyle),
        ),
      ],
    );

    if (padding != null) {
      return Padding(
        padding: padding!,
        child: content,
      );
    }
    return content;
  }
}
