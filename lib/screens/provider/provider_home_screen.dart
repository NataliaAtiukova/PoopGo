import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../models/order.dart';
import '../../widgets/order_list_tile.dart';
import '../../routes.dart';

class ProviderHomeScreen extends StatelessWidget {
  const ProviderHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthService>();
    final firestore = context.read<FirestoreService>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('PoopGo - Provider'),
        actions: [
          IconButton(
            onPressed: () => Navigator.pushNamed(context, Routes.providerProfile),
            icon: const Icon(Icons.person),
          ),
          IconButton(
            onPressed: () async {
              await auth.signOut();
              if (context.mounted) Navigator.pushNamedAndRemoveUntil(context, Routes.roleSelect, (_) => false);
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: Column(
        children: [
          ListTile(
            title: const Text('Open Requests'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.pushNamed(context, Routes.openRequests),
          ),
          const Divider(height: 0),
          Expanded(
            child: StreamBuilder<List<Order>>(
              stream: firestore.streamProviderOrders(auth.currentUser!.uid),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final orders = snapshot.data!;
                if (orders.isEmpty) {
                  return const Center(child: Text('No assigned jobs yet.'));
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
          )
        ],
      ),
    );
  }
}

