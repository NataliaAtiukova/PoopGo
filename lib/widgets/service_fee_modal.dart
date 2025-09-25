import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../models/order.dart';
import '../services/payment_config.dart';
import '../utils/money.dart';
import '../services/firebase_service.dart';
import '../screens/payment/payment_placeholder_screen.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../routes.dart';

class ServiceFeeModal extends StatefulWidget {
  final Order order;

  const ServiceFeeModal({super.key, required this.order});

  double _feeAmount() => calculateServiceFee(order.price);

  @override
  State<ServiceFeeModal> createState() => _ServiceFeeModalState();
}

class _ServiceFeeModalState extends State<ServiceFeeModal> {
  late final TapGestureRecognizer _agreementRecognizer;
  late final TapGestureRecognizer _offerRecognizer;

  @override
  void initState() {
    super.initState();
    _agreementRecognizer = TapGestureRecognizer()..onTap = _openAgreement;
    _offerRecognizer = TapGestureRecognizer()..onTap = _openOffer;
  }

  @override
  void dispose() {
    _agreementRecognizer.dispose();
    _offerRecognizer.dispose();
    super.dispose();
  }

  void _openAgreement() {
    Navigator.of(context).pushNamed(Routes.userAgreement);
  }

  void _openOffer() {
    Navigator.of(context).pushNamed(Routes.publicOffer);
  }

  @override
  Widget build(BuildContext context) {
    final amount = widget._feeAmount();
    final colorScheme = Theme.of(context).colorScheme;
    final bodySmall = Theme.of(context).textTheme.bodySmall;

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF0F1115),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.lock_outline, color: Colors.white70),
              const SizedBox(width: 8),
              Text(
                AppLocalizations.of(context)!.paymentSummary,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            AppLocalizations.of(context)!.serviceCommissionIntro,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white70),
          ),
          const SizedBox(height: 16),
          // Summary: total price
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF151923),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF1F2430)),
            ),
            child: Row(
              children: [
                Icon(Icons.receipt_long, color: Colors.lightBlue[300]),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    AppLocalizations.of(context)!.totalPrice,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white70),
                  ),
                ),
                Text(
                  formatRub(widget.order.price),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.lightBlue[300], fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          // Summary: service fee (10%)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF151923),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF1F2430)),
            ),
            child: Row(
              children: [
                Icon(Icons.currency_ruble, color: Colors.lightBlue[300]),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    AppLocalizations.of(context)!.serviceFee10,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white70),
                  ),
                ),
                Text(
                  formatRub(amount),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.lightBlue[300], fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (widget.order.status == OrderStatus.accepted && !widget.order.serviceFeePaid)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1976D2),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () async {
                  // TODO(payment): Replace with real gateway integration (e.g., Robokassa)
                  // Currently we navigate to a placeholder screen in demo mode.
                  Navigator.of(context).pop();
                  await Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const PaymentPlaceholderScreen()),
                  );
                },
                icon: const Icon(Icons.payment),
                label: Text(AppLocalizations.of(context)!.payNow),
              ),
            ),
          if (PaymentConfig.enablePaymentSimulation && widget.order.status == OrderStatus.accepted && !widget.order.serviceFeePaid) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () async {
                  final updated = widget.order.copyWith(serviceFeePaid: true, updatedAt: DateTime.now());
                  await FirebaseService.updateOrder(updated);
                  if (context.mounted) {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(AppLocalizations.of(context)!.serviceFeePaidSuccessfully), backgroundColor: Colors.green),
                    );
                  }
                },
                icon: const Icon(Icons.bug_report),
                label: Text(AppLocalizations.of(context)!.simulatePayment),
              ),
            ),
          ],
          const SizedBox(height: 12),
          RichText(
            text: TextSpan(
              style: bodySmall?.copyWith(
                    color: Colors.white70,
                  ) ??
                  const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
              children: [
                const TextSpan(text: 'Оплачивая сервисный сбор, вы соглашаетесь с '),
                TextSpan(
                  text: 'Публичной офертой',
                  style: TextStyle(
                    color: colorScheme.primary,
                    decoration: TextDecoration.underline,
                    fontWeight: FontWeight.w600,
                  ),
                  recognizer: _offerRecognizer,
                ),
                const TextSpan(text: ' и '),
                TextSpan(
                  text: 'Пользовательским соглашением',
                  style: TextStyle(
                    color: colorScheme.primary,
                    decoration: TextDecoration.underline,
                    fontWeight: FontWeight.w600,
                  ),
                  recognizer: _agreementRecognizer,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

Future<void> showServiceFeeModal(BuildContext context, Order order) async {
  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => ServiceFeeModal(order: order),
  );
}
