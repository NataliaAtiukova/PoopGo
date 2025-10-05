import 'package:flutter/material.dart';

import '../../models/order.dart';
import '../../services/firebase_service.dart';
import '../shared/chat_screen.dart';
import 'order_edit_screen.dart';
import '../../widgets/payment_method_display.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../utils/order_status_display.dart';
import '../../utils/format.dart' as fmt;
import '../../widgets/service_fee_modal.dart';
import '../payment/payment_info_screen.dart';

class OrderStatusScreen extends StatefulWidget {
  final String orderId;

  const OrderStatusScreen({super.key, required this.orderId});

  @override
  State<OrderStatusScreen> createState() => _OrderStatusScreenState();
}

class _OrderStatusScreenState extends State<OrderStatusScreen> {
  Order? _order;
  bool _promptedCommission = false;

  @override
  void initState() {
    super.initState();
    _loadOrder();
  }

  Future<void> _loadOrder() async {
    final order = await FirebaseService.getOrderById(widget.orderId);
    if (mounted) setState(() => _order = order);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.orderStatus),
        actions: [
          if (_order!.isEditable)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => OrderEditScreen(order: _order!),
                  ),
                ).then((_) => _loadOrder()); // Refresh order after editing
              },
            ),
          if (_order!.providerId != null)
            IconButton(
              icon: Icon(
                Icons.chat,
                color: _isContactLocked() ? Colors.grey : null,
              ),
              onPressed: () async {
                if (_isContactLocked()) {
                  if (_shouldPromptCommission()) {
                    await showServiceFeeModal(context, _order!);
                    final refreshed =
                        await FirebaseService.getOrderById(widget.orderId);
                    if (mounted) setState(() => _order = refreshed);
                  } else {
                    if (mounted) {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title:
                              Text(AppLocalizations.of(context)!.contactLocked),
                          content: Text(
                              AppLocalizations.of(context)!.contactLockedMsg),
                        ),
                      );
                    }
                  }
                  return;
                }
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChatScreen(orderId: widget.orderId),
                  ),
                );
              },
            ),
        ],
      ),
      body: StreamBuilder<Order?>(
        stream: FirebaseService.streamOrderById(widget.orderId),
        builder: (context, snap) {
          final order = snap.data ?? _order;
          if (order == null) {
            return const Center(child: CircularProgressIndicator());
          }
          _order = order; // keep local reference for helpers

          // Prompt commission once when accepted & unpaid
          if (_shouldPromptCommission() && !_promptedCommission) {
            _promptedCommission = true;
            final currentContext = context;
            Future.microtask(() async {
              if (!mounted || !currentContext.mounted) return;
              await showServiceFeeModal(currentContext, _order!);
              if (!mounted || !currentContext.mounted) return;
              final refreshed =
                  await FirebaseService.getOrderById(widget.orderId);
              if (mounted) setState(() => _order = refreshed);
            });
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        _buildStatusIndicator(),
                        const SizedBox(height: 16),
                        Text(
                          AppLocalizations.of(context)!.orderStatusTitle,
                          textAlign: TextAlign.center,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          customerStatusLabel(context, _order!.status),
                          style: Theme.of(context).textTheme.headlineSmall,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _getStatusDescription(_order!.status),
                          style: Theme.of(context).textTheme.bodyMedium,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Order Details
                Text(
                  AppLocalizations.of(context)!.orderDetails,
                  style: Theme.of(context).textTheme.titleLarge,
                ),

                const SizedBox(height: 16),

                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _buildDetailRow(
                            'ID заказа', _order!.orderId, Icons.tag),
                        const Divider(),
                        _buildDetailRow(AppLocalizations.of(context)!.address,
                            _order!.address, Icons.location_on),
                        const Divider(),
                        _buildDetailRow(AppLocalizations.of(context)!.volume,
                            '${_order!.volume}L', Icons.water_drop),
                        const Divider(),
                        _buildDetailRow(
                            AppLocalizations.of(context)!.date,
                            _formatDateTime(_order!.requestedDate),
                            Icons.calendar_today),
                        const Divider(),
                        _buildDetailRow(
                            AppLocalizations.of(context)!.totalPrice,
                          '${_order!.total.toStringAsFixed(0)} ₽',
                            Icons.currency_ruble),
                        const Divider(),
                        _buildDetailWidgetRow(
                          AppLocalizations.of(context)!.method,
                          PaymentMethodDisplay(
                              paymentMethod: _order!.paymentMethod,
                              showLabel: true,
                              iconSize: 16),
                          Icons.payment,
                        ),
                        const Divider(),
                        _buildPaymentStatus(),
                        if (_order!.notes != null &&
                            _order!.notes!.isNotEmpty) ...[
                          const Divider(),
                          _buildDetailRow(AppLocalizations.of(context)!.notes,
                              _order!.notes!, Icons.note),
                        ],
                      ],
                    ),
                  ),
                ),

                // Images
                if (_order!.imageUrls.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  Text(
                    AppLocalizations.of(context)!.photos,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                        ),
                        itemCount: _order!.imageUrls.length,
                        itemBuilder: (context, index) {
                          return ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              _order!.imageUrls[index],
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: Colors.grey[300],
                                  child: const Icon(Icons.image),
                                );
                              },
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],

                // Provider Info with commission gating
                if (_order!.providerId != null) ...[
                  const SizedBox(height: 24),
                  Text(
                    AppLocalizations.of(context)!.provider,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: _buildProviderCard(),
                  ),
                ],

                // Service Commission card (only while awaiting payment)
                if (_order!.status == OrderStatus.processing) ...[
                  const SizedBox(height: 24),
                  Text(
                    AppLocalizations.of(context)!.paymentSummary,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          _buildPaymentRow(
                              AppLocalizations.of(context)!.totalPrice,
                              '${_order!.total.toStringAsFixed(2)} ₽',
                              Icons.currency_ruble),
                          const Divider(),
                          _buildPaymentRow(
                              AppLocalizations.of(context)!.serviceFee10,
                              _feeText(),
                              Icons.business),
                          const Divider(),
                          _buildPaymentStatus(),
                          const SizedBox(height: 8),
                          _buildServiceFeeStatus(),
                          if (_shouldPromptCommission()) ...[
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => PaymentInfoScreen(
                                          orderId: _order!.id),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.payment),
                                label: const Text('Оплатить сервисный сбор'),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatusIndicator() {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: _getStatusColor(_order!.status).withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(
        _getStatusIcon(_order!.status),
        size: 40,
        color: _getStatusColor(_order!.status),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(
            icon,
            color: Colors.grey[400],
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[400],
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.processing:
        return Colors.orange;
      case OrderStatus.paid:
        return Colors.teal;
      case OrderStatus.assigned:
        return Colors.blue;
      case OrderStatus.inProgress:
        return Colors.purple;
      case OrderStatus.completed:
        return Colors.green;
      case OrderStatus.cancelled:
        return Colors.red;
    }
  }

  IconData _getStatusIcon(OrderStatus status) {
    switch (status) {
      case OrderStatus.processing:
        return Icons.watch_later;
      case OrderStatus.paid:
        return Icons.verified_user;
      case OrderStatus.assigned:
        return Icons.emoji_transportation;
      case OrderStatus.inProgress:
        return Icons.local_shipping;
      case OrderStatus.completed:
        return Icons.done_all;
      case OrderStatus.cancelled:
        return Icons.cancel;
    }
  }

  String _getStatusDescription(OrderStatus status) {
    final l = AppLocalizations.of(context)!;
    switch (status) {
      case OrderStatus.processing:
        return l.statusMessageProcessing;
      case OrderStatus.paid:
        return l.statusMessagePaid;
      case OrderStatus.assigned:
        return l.statusMessageAssigned;
      case OrderStatus.inProgress:
        return l.statusMessageInProgress;
      case OrderStatus.completed:
        return l.statusMessageCompleted;
      case OrderStatus.cancelled:
        return l.statusMessageCancelled;
    }
  }

  String _formatDateTime(DateTime dateTime) =>
      fmt.formatDateTime(context, dateTime);

  bool _isContactLocked() {
    if (_order == null) return false;
    // Contact info remains hidden until the service fee is paid
    return _order!.serviceFeePaid == false;
  }

  bool _shouldPromptCommission() {
    if (_order == null) return false;
    return _order!.status == OrderStatus.processing &&
        _order!.serviceFeePaid == false;
  }

  Widget _buildPaymentRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(
            icon,
            color: Colors.grey[400],
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[400],
                  ),
            ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentStatus() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(
            _order!.isPaid ? Icons.check_circle : Icons.pending,
            color: _order!.isPaid ? Colors.green : Colors.orange,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              AppLocalizations.of(context)!.paymentStatus,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[400],
                  ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: _order!.isPaid
                  ? Colors.green.withValues(alpha: 0.1)
                  : Colors.orange.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _order!.isPaid
                  ? AppLocalizations.of(context)!.paid
                  : AppLocalizations.of(context)!.pending,
              style: TextStyle(
                color: _order!.isPaid ? Colors.green : Colors.orange,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailWidgetRow(String label, Widget value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey[400], size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: Colors.grey[400]),
            ),
          ),
          Flexible(child: value),
        ],
      ),
    );
  }

  Widget _buildProviderCard() {
    // Locked state
    if (_isContactLocked()) {
      return Card(
        key: const ValueKey('lockedCard'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const CircleAvatar(radius: 24, child: Icon(Icons.lock)),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(AppLocalizations.of(context)!.contactLocked,
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text(
                      AppLocalizations.of(context)!.contactLockedMsg,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              if (_shouldPromptCommission())
                ElevatedButton(
                  onPressed: () async {
                    await showServiceFeeModal(context, _order!);
                    final refreshed =
                        await FirebaseService.getOrderById(widget.orderId);
                    if (mounted) setState(() => _order = refreshed);
                  },
                  child: Text(AppLocalizations.of(context)!.payNow),
                ),
            ],
          ),
        ),
      );
    }

    // Otherwise, show provider contact. Only query providers when allowed.
    if (_isContactLocked()) {
      // Fallback minimal card
      return Card(
        key: const ValueKey('assignedCard'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const CircleAvatar(radius: 24, child: Icon(Icons.person)),
              const SizedBox(width: 16),
              Expanded(
                  child: Text(AppLocalizations.of(context)!.providerAssigned,
                      style: Theme.of(context).textTheme.titleMedium)),
              IconButton(
                  icon: const Icon(Icons.chat, color: Colors.grey),
                  onPressed: () {}),
            ],
          ),
        ),
      );
    }

    return FutureBuilder<Map<String, dynamic>?>(
      key: const ValueKey('contactCard'),
      future: FirebaseService.getProviderProfile(_order!.providerId!),
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Card(
              child: Padding(
                  padding: EdgeInsets.all(16),
                  child: LinearProgressIndicator()));
        }
        final data = snap.data;
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const CircleAvatar(radius: 24, child: Icon(Icons.person)),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                          data?['fullName'] ??
                              AppLocalizations.of(context)!.provider,
                          style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 4),
                      Text(data?['phone'] ?? '-',
                          style: Theme.of(context).textTheme.bodyMedium),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chat),
                  onPressed: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) =>
                                ChatScreen(orderId: widget.orderId)));
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildServiceFeeStatus() {
    final paid = _order!.serviceFeePaid;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(
            paid ? Icons.verified : Icons.lock_clock,
            color: paid ? Colors.green : Colors.orange,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              AppLocalizations.of(context)!.serviceFee10,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[400],
                  ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: paid
                  ? Colors.green.withValues(alpha: 0.1)
                  : Colors.orange.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              paid
                  ? AppLocalizations.of(context)!.paid
                  : AppLocalizations.of(context)!.pending,
              style: TextStyle(
                color: paid ? Colors.green : Colors.orange,
                fontWeight: FontWeight.bold,
              ),
            ),
          )
        ],
      ),
    );
  }

  String _feeText() => '${_order!.serviceFee.toStringAsFixed(2)} ₽';

  // Payment dialog flows for test/manual payment were removed in favor of
  // unified Service Fee modal and CloudPayments flow.
}
