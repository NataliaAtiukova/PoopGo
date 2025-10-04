import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import 'package:flutter/material.dart';

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
          final paymentMethod = (data['paymentMethod'] as String?) ?? 'card';
          final total = (data['total'] is num)
              ? (data['total'] as num).toDouble()
              : 0.0;

          if (paymentMethod == 'cash') {
            return Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _InfoRow(
                    label: _localized(context, ru: 'Номер заказа', en: 'Order ID'),
                    value: orderId,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _localized(
                      context,
                      ru: 'Оплата сервисного сбора будет произведена при расчёте с исполнителем.',
                      en: 'The service fee will be paid directly to the driver upon completion.',
                    ),
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ),
            );
          }

          return Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _InfoRow(
                  label: _localized(context, ru: 'Номер заказа', en: 'Order ID'),
                  value: orderId,
                ),
                const SizedBox(height: 12),
                _InfoRow(
                  label: _localized(context,
                      ru: 'Итоговая сумма с комиссией',
                      en: 'Total amount with service fee'),
                  value: '${total.toStringAsFixed(2)} ₽',
                ),
                const SizedBox(height: 12),
                Text(
                  _localized(context,
                      ru: 'Сервисный сбор 10 % включён.',
                      en: 'A 10% service fee is included.'),
                  style: const TextStyle(fontSize: 16),
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
                    label: Text(
                      _localized(context,
                          ru: 'Перейти к оплате', en: 'Proceed to payment'),
                    ),
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

String _localized(BuildContext context, {required String ru, required String en}) {
  final locale = Localizations.localeOf(context);
  return locale.languageCode == 'ru' ? ru : en;
}
