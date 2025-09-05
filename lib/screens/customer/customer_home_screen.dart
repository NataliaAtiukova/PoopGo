import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../models/order.dart';
import '../../widgets/order_list_tile.dart';
import '../../routes.dart';

class CustomerHomeScreen extends StatelessWidget {
  const CustomerHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthService>();
    final firestore = context.read<FirestoreService>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('PoopGo - Customer'),
        actions: [
          IconButton(
            onPressed: () async {
              await auth.signOut();
              if (context.mounted) Navigator.pushNamedAndRemoveUntil(context, Routes.roleSelect, (_) => false);
            },
            icon: const Icon(Icons.logout),
          )
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(context, Routes.orderForm),
        label: const Text('Request Sewage Pickup'),
        icon: const Icon(Icons.add),
      ),
      body: StreamBuilder<List<Order>>(
        stream: firestore.streamCustomerOrders(auth.currentUser!.uid),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final orders = snapshot.data!;
          if (orders.isEmpty) {
            return const Center(child: Text('No orders yet. Tap + to request.'));
          }
          return ListView.builder(
            itemCount: orders.length,
            itemBuilder: (context, i) => OrderListTile(
              order: orders[i],
              onTap: () => Navigator.pushNamed(context, Routes.orderStatus, arguments: orders[i].id),
            ),
          );
        },
      ),
    );
  }
}

