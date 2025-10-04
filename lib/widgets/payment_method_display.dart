import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

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
              AppLocalizations.of(context)!.method,
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
    final localizedLabel = _localizedMethodLabel(context, paymentMethod!);

    return LayoutBuilder(
      builder: (context, constraints) {
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
              // Constrain and ellipsize long labels like "Картой по завершении"
              ConstrainedBox(
                constraints: BoxConstraints(
                    maxWidth:
                        math.max(0.0, constraints.maxWidth - iconSize - 8)),
                child: Text(
                  localizedLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  softWrap: false,
                  style: TextStyle(
                    color: methodData.color,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  PaymentMethodData _getPaymentMethodData(String method) {
    switch (method.toLowerCase()) {
      case 'cash':
        return PaymentMethodData(
          icon: Icons.money,
          color: Colors.green,
        );
      case 'card':
        return PaymentMethodData(
          icon: Icons.credit_card,
          color: Colors.blue,
        );
      // Bank transfer removed from available options
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

  String _localizedMethodLabel(BuildContext context, String method) {
    final l = AppLocalizations.of(context)!;
    switch (method.toLowerCase()) {
      case 'cash':
        return l.cashPayment;
      case 'card':
        return _cardPaymentLabel(context);
      case 'bank transfer':
        return l.bankTransfer;
      case 'card on completion':
        return l.cardOnCompletion;
      default:
        return method;
    }
  }

  String _cardPaymentLabel(BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;
    return locale == 'ru'
        ? 'Оплата картой онлайн'
        : 'Online card payment';
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
