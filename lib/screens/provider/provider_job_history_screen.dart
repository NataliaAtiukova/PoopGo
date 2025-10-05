import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../models/order.dart';
import '../../services/firebase_service.dart';
import '../../widgets/price_display.dart';

class ProviderJobHistoryScreen extends StatelessWidget {
  const ProviderJobHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.navHistory)),
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
          return Center(child: Text('${AppLocalizations.of(context)!.error}: ${snapshot.error}'));
        }
        final orders = snapshot.data ?? [];
        if (orders.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inbox_outlined, size: 64, color: Colors.grey[500]),
                const SizedBox(height: 12),
                Text(AppLocalizations.of(context)!.noOrdersYet),
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
    final l = AppLocalizations.of(context)!;
    final completedDate = order.completedAt ?? order.updatedAt ?? order.createdAt;
    final serviceFeePaidText = order.serviceFeePaid
        ? l.driverHistoryServiceFeePaid
        : l.driverHistoryServiceFeeUnpaid;

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
            Text(
              AppLocalizations.of(context)!
                  .completedOn(_formatDate(completedDate)),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 6),
            Text(
              l.driverHistoryVolumePrice(
                order.volume.toStringAsFixed(0),
                order.price.toStringAsFixed(2),
              ),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 6),
            Text(
              l.driverHistoryPayout(order.price.toStringAsFixed(2)),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 6),
            Text(
              l.driverHistoryServiceFee(order.serviceFee.toStringAsFixed(2)),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 6),
            Text(
              serviceFeePaidText,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: order.serviceFeePaid ? Colors.green : Colors.orange,
                  ),
            ),
            if (order.displayStatus != null) ...[
              const SizedBox(height: 6),
              Text(
                order.displayStatus!,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: Colors.grey[600]),
              ),
            ],
            const SizedBox(height: 12),
            FutureBuilder<Map<String, dynamic>?>(
              future: FirebaseService.getUserContact(order.customerId),
              builder: (context, snapshot) {
                final contact = snapshot.data;
                final name = contact?['fullName'] ?? contact?['name'] ?? '-';
                final phone = contact?['phone'] ?? '-';
                final email = contact?['email'] ?? '-';
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l.driverHistoryCustomerContact,
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Text(name, style: Theme.of(context).textTheme.bodyMedium),
                    Text(l.driverHistoryContactPhone(phone),
                        style: Theme.of(context).textTheme.bodySmall),
                    Text(l.driverHistoryContactEmail(email),
                        style: Theme.of(context).textTheme.bodySmall),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) => '${date.day}/${date.month}/${date.year}';
}
