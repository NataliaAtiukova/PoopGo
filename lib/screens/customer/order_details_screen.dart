import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class OrderDetailsScreen extends StatelessWidget {
  const OrderDetailsScreen({super.key, required this.orderId});

  final String orderId;

  @override
  Widget build(BuildContext context) {
    final orderRef =
        FirebaseFirestore.instance.collection('orders').doc(orderId);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Детали заказа'),
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: orderRef.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('Заказ не найден'));
          }

          final data = snapshot.data!.data()!;
          final status = (data['status'] as String?) ?? 'pending';
          final amount = data['amount'];
          final createdAt = _formatTimestamp(data['createdAt']);
          final paidAt = _formatTimestamp(data['paidAt']);
          final executorName =
              (data['executorName'] ?? data['providerName']) as String?;
          final executorPhone =
              (data['executorPhone'] ?? data['providerPhone']) as String?;
          final executorEmail =
              (data['executorEmail'] ?? data['providerEmail']) as String?;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInfoRow('ID заказа', orderId),
                      const SizedBox(height: 12),
                      _buildInfoRow(
                          'Сумма', amount != null ? '$amount ₽' : '-'),
                      const SizedBox(height: 12),
                      _buildInfoRow('Статус', status),
                      const SizedBox(height: 12),
                      _buildInfoRow('Создан', createdAt),
                      const SizedBox(height: 12),
                      _buildInfoRow('Оплачен', paidAt),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (status == 'paid') ...[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Контакты исполнителя',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 12),
                        _buildInfoRow('Имя', executorName ?? 'Не указано'),
                        const SizedBox(height: 8),
                        _buildInfoRow('Телефон', executorPhone ?? 'Не указан'),
                        const SizedBox(height: 8),
                        _buildInfoRow('Email', executorEmail ?? 'Не указан'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pushNamed(
                        context,
                        '/customer/order-status',
                        arguments: orderId,
                      );
                    },
                    child: const Text('Перейти к заказу'),
                  ),
                ),
              ] else ...[
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pushNamed(
                        context,
                        '/payment',
                        arguments: orderId,
                      );
                    },
                    child: const Text('Оплатить сервисный сбор'),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 3,
          child: Text(value),
        ),
      ],
    );
  }

  String _formatTimestamp(dynamic value) {
    if (value is Timestamp) {
      return _formatDateTime(value.toDate());
    }
    if (value is DateTime) {
      return _formatDateTime(value);
    }
    return '-';
  }

  String _formatDateTime(DateTime dateTime) {
    final local = dateTime.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    final year = local.year.toString();
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '$day.$month.$year $hour:$minute';
  }
}
