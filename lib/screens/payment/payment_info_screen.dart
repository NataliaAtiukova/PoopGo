import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'payment_screen.dart';

class PaymentInfoScreen extends StatelessWidget {
  final String orderId;
  const PaymentInfoScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context) {
    final docRef =
        FirebaseFirestore.instance.collection('orders').doc(orderId);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Оплата сервисного сбора'),
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: docRef.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('Заказ не найден'));
          }
          final data = snapshot.data!.data()!;
          final serviceFee = (data['serviceFee'] is num)
              ? (data['serviceFee'] as num).toDouble()
              : 0.0;
          final price = (data['price'] is num)
              ? (data['price'] as num).toDouble()
              : 0.0;
          final l = AppLocalizations.of(context)!;

          return Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _OrderIdRow(orderId: orderId),
                const SizedBox(height: 12),
                _InfoRow(
                  label: _localized(context,
                      ru: 'Сервисный сбор (10%)', en: 'Service fee (10%)'),
                  value: '${serviceFee.toStringAsFixed(2)} ₽',
                ),
                const SizedBox(height: 12),
                Text(
                  l.paymentInfoServiceFeeMessage(
                    serviceFee.toStringAsFixed(2),
                    price.toStringAsFixed(2),
                  ),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PaymentScreen(orderId: orderId),
                        ),
                      );
                    },
                    icon: const Icon(Icons.payment),
                    label: Text(l.proceedToServiceFeePayment),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(color: Colors.grey[600]),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ],
    );
  }
}

class _OrderIdRow extends StatelessWidget {
  final String orderId;
  const _OrderIdRow({required this.orderId});

  @override
  Widget build(BuildContext context) {
    final label = _localized(context, ru: 'Номер заказа:', en: 'Order ID:');
    final copied = _localized(context,
        ru: 'Номер заказа скопирован', en: 'Order number copied');
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Flexible(
          child: Text(
            '$label $orderId',
            style: Theme.of(context)
                .textTheme
                .bodyLarge
                ?.copyWith(fontWeight: FontWeight.w600),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          icon: const Icon(Icons.copy, size: 18, color: Colors.blueAccent),
          tooltip: _localized(context, ru: 'Скопировать', en: 'Copy'),
          onPressed: () async {
            await Clipboard.setData(ClipboardData(text: orderId));
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(copied),
                duration: const Duration(seconds: 2),
              ),
            );
          },
        ),
      ],
    );
  }
}

String _localized(BuildContext context, {required String ru, required String en}) {
  final locale = Localizations.localeOf(context);
  return locale.languageCode == 'ru' ? ru : en;
}
