import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../models/order.dart';
import '../shared/chat_screen.dart';

class OrderStatusScreen extends StatelessWidget {
  const OrderStatusScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final orderId = ModalRoute.of(context)!.settings.arguments as String?;
    final firestore = context.read<FirestoreService>();
    if (orderId == null) {
      return const Scaffold(body: Center(child: Text('Order not found')));
    }
    return StreamBuilder<Order>(
      stream: firestore.orders.doc(orderId).snapshots().map((d) => Order.fromMap(d.data() as Map<String, dynamic>)),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        final order = snapshot.data!;
        final auth = context.read<AuthService>();
        final isProviderForThisOrder = order.providerId == auth.currentUser?.uid;
        return Scaffold(
          appBar: AppBar(title: const Text('Order Status')),
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Address: ${order.address ?? 'N/A'}'),
                const SizedBox(height: 8),
                Text('Scheduled: ${order.scheduledAt}'),
                const SizedBox(height: 8),
                Text('Volume: ${order.volumeLiters} L'),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Text('Status: '),
                    Chip(label: Text(order.status.name)),
                  ],
                ),
                const Spacer(),
                if (isProviderForThisOrder) ...[
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: order.status == OrderStatus.accepted
                              ? () => firestore.updateOrderStatus(order.id, OrderStatus.onTheWay)
                              : null,
                          child: const Text('On the way'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: (order.status == OrderStatus.onTheWay || order.status == OrderStatus.accepted)
                              ? () => firestore.updateOrderStatus(order.id, OrderStatus.completed)
                              : null,
                          child: const Text('Mark Completed'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
                if (order.providerId != null)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.chat),
                      label: const Text('Chat with Provider'),
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ChatScreen(orderId: order.id),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
