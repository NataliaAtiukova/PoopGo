import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../models/order.dart';
import '../../services/firebase_service.dart';
import '../../widgets/price_display.dart';

class ProviderJobHistoryScreen extends StatelessWidget {
  const ProviderJobHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    return Scaffold(
      appBar: AppBar(title: const Text('Completed Jobs')),
      body: ProviderJobHistoryList(providerId: uid),
    );
  }
}

/// Reusable list widget for completed jobs for current provider.
class ProviderJobHistoryList extends StatelessWidget {
  final String? providerId;
  const ProviderJobHistoryList({super.key, this.providerId});

  @override
  Widget build(BuildContext context) {
    final uid = providerId ?? FirebaseAuth.instance.currentUser!.uid;
    return StreamBuilder<List<Order>>(
      stream: FirebaseService.getCompletedOrdersForProvider(uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        final orders = snapshot.data ?? [];
        if (orders.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inbox_outlined, size: 64, color: Colors.grey[500]),
                const SizedBox(height: 12),
                const Text('No completed jobs yet'),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: orders.length,
          itemBuilder: (context, index) => _CompletedOrderTile(order: orders[index]),
        );
      },
    );
  }
}

class _CompletedOrderTile extends StatelessWidget {
  final Order order;
  const _CompletedOrderTile({required this.order});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.done_all, color: Colors.green),
                const SizedBox(width: 8),
                Expanded(child: Text(order.address, style: Theme.of(context).textTheme.titleMedium)),
                PriceDisplay(price: order.price, showLabel: false),
              ],
            ),
            const SizedBox(height: 6),
            Text('Completed on ${_formatDate(order.updatedAt ?? order.createdAt)}', style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 6),
            Text('Volume: ${order.volume}L', style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) => '${date.day}/${date.month}/${date.year}';
}
