import 'package:flutter/material.dart';
import '../models/order.dart';
import '../logic/order_status_handler.dart';
import '../services/firebase_service.dart';
import '../widgets/service_fee_modal.dart';
import '../utils/money.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../screens/shared/chat_screen.dart';

class ContactUnlockWidget extends StatefulWidget {
  final Order order;
  final VoidCallback? onUnlocked;

  const ContactUnlockWidget({super.key, required this.order, this.onUnlocked});

  @override
  State<ContactUnlockWidget> createState() => _ContactUnlockWidgetState();
}

class _ContactUnlockWidgetState extends State<ContactUnlockWidget> {
  late Order _order;

  @override
  void initState() {
    super.initState();
    _order = widget.order;
  }

  Future<void> _refreshOrder() async {
    final o = await FirebaseService.getOrderById(_order.id);
    if (mounted && o != null) setState(() => _order = o);
  }

  @override
  Widget build(BuildContext context) {
    final locked = !OrderStatusHandler.canAccessContact(_order);

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      child: locked ? _lockedCard(context) : _contactCard(context),
    );
  }

  Widget _lockedCard(BuildContext context) {
    return Card(
      key: const ValueKey('locked'),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const CircleAvatar(radius: 22, child: Icon(Icons.lock)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    AppLocalizations.of(context)!.unlockContactMessage,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Show a quick summary of amounts so it's clear before payment
            Row(
              children: [
                Expanded(
                  child: Text(
                  '${AppLocalizations.of(context)!.totalPrice}: ${_order.price.toStringAsFixed(2)} ₽',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              Text(
                  '${AppLocalizations.of(context)!.serviceFee10}: ${calculateServiceFee(_order.price).toStringAsFixed(2)} ₽',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (OrderStatusHandler.shouldPromptServiceFee(_order))
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    await showServiceFeeModal(context, _order);
                    await _refreshOrder();
                    if (mounted && OrderStatusHandler.canAccessContact(_order)) {
                      widget.onUnlocked?.call();
                    }
                  },
                  child: Text(AppLocalizations.of(context)!.payNow),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _contactCard(BuildContext context) {
    if (_order.providerId == null) {
      return const SizedBox.shrink();
    }
    return FutureBuilder<Map<String, dynamic>?>(
      key: const ValueKey('contact'),
      future: FirebaseService.getProviderProfile(_order.providerId!),
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Card(child: Padding(padding: EdgeInsets.all(16), child: LinearProgressIndicator()));
        }
        final data = snap.data ?? {};
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const CircleAvatar(radius: 22, child: Icon(Icons.person)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(data['fullName'] ?? AppLocalizations.of(context)!.provider, style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 4),
                      Text(data['phone'] ?? '-', style: Theme.of(context).textTheme.bodyMedium),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chat),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => ChatScreen(orderId: _order.id)),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
