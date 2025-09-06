import 'package:flutter/material.dart';

class PaymentMethodDisplay extends StatelessWidget {
  final String? paymentMethod;
  final bool showLabel;
  final double iconSize;

  const PaymentMethodDisplay({
    super.key,
    this.paymentMethod,
    this.showLabel = true,
    this.iconSize = 16,
  });

  @override
  Widget build(BuildContext context) {
    if (paymentMethod == null || paymentMethod!.isEmpty) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.help_outline,
            size: iconSize,
            color: Colors.grey[400],
          ),
          if (showLabel) ...[
            const SizedBox(width: 4),
            Text(
              'No method specified',
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 12,
              ),
            ),
          ],
        ],
      );
    }

    final methodData = _getPaymentMethodData(paymentMethod!);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          methodData.icon,
          size: iconSize,
          color: methodData.color,
        ),
        if (showLabel) ...[
          const SizedBox(width: 4),
          Text(
            paymentMethod!,
            style: TextStyle(
              color: methodData.color,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }

  PaymentMethodData _getPaymentMethodData(String method) {
    switch (method.toLowerCase()) {
      case 'cash':
        return PaymentMethodData(
          icon: Icons.money,
          color: Colors.green,
        );
      case 'bank transfer':
        return PaymentMethodData(
          icon: Icons.account_balance,
          color: Colors.grey,
        );
      case 'card on completion':
        return PaymentMethodData(
          icon: Icons.credit_card,
          color: Colors.blue,
        );
      default:
        return PaymentMethodData(
          icon: Icons.payment,
          color: Colors.orange,
        );
    }
  }
}

class PaymentMethodData {
  final IconData icon;
  final Color color;

  PaymentMethodData({
    required this.icon,
    required this.color,
  });
}


