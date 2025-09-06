import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../models/order.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../widgets/order_list_tile.dart';

class OpenRequestsScreen extends StatelessWidget {
  const OpenRequestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final firestore = context.read<FirestoreService>();
    final auth = context.read<AuthService>();
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.openRequests)),
      body: StreamBuilder<List<Order>>(
        stream: firestore.streamOpenOrders(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final orders = snapshot.data!;
          if (orders.isEmpty) {
            return Center(child: Text(AppLocalizations.of(context)!.noAvailableJobs));
          }
          return ListView.builder(
            itemCount: orders.length,
            itemBuilder: (context, i) {
              final order = orders[i];
              return Card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    OrderListTile(order: order),
                    OverflowBar(
                      children: [
                        TextButton(
                          onPressed: () async {
                            await firestore.acceptOrder(orderId: order.id, providerId: auth.currentUser!.uid);
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.orderAcceptedSuccess)));
                          },
                          child: Text(AppLocalizations.of(context)!.accept),
                        ),
                        TextButton(
                          onPressed: () => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.orderRejected))),
                          child: Text(AppLocalizations.of(context)!.reject),
                        ),
                      ],
                    )
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
