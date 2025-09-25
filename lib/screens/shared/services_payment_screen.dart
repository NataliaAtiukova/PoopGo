import 'package:flutter/material.dart';

class ServicesPaymentScreen extends StatelessWidget {
  const ServicesPaymentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Услуги и оплата'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Как работает оплата в PoopGo',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          _buildBullet(
            context,
            'За использование приложения взимается сервисный сбор 10%.',
          ),
          _buildBullet(
            context,
            'Оплата комиссии проводится онлайн через платёжный шлюз (ЮKassa).',
          ),
          _buildBullet(
            context,
            'Заказчик и исполнитель рассчитываются напрямую между собой.',
          ),
        ],
      ),
    );
  }

  Widget _buildBullet(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 6, right: 8),
            child: Icon(
              Icons.circle,
              size: 8,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
        ],
      ),
    );
  }
}
