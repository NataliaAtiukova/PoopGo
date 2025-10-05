import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart' hide Order;

import '../../models/order.dart';
import '../../routes.dart';
import '../../services/firebase_service.dart';
import '../../widgets/payment_method_display.dart';
import '../../widgets/price_display.dart';
import '../../widgets/provider_acceptance_dialog.dart';
import '../../widgets/service_fee_notice.dart';
import '../../utils/order_status_display.dart';
import '../shared/chat_screen.dart';
import '../shared/profile_settings_screen.dart';
import 'provider_job_history_screen.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../utils/l10n.dart';

class ProviderHomeScreen extends StatefulWidget {
  const ProviderHomeScreen({super.key});

  @override
  State<ProviderHomeScreen> createState() => _ProviderHomeScreenState();
}

class _ProviderHomeScreenState extends State<ProviderHomeScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.providerAppTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
            },
          ),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: const [
          _AvailableJobsTab(),
          _MyJobsTab(),
          _HistoryTab(),
          _ProfileTab(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.work),
            label: AppLocalizations.of(context)!.navAvailable,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.assignment),
            label: AppLocalizations.of(context)!.navMyJobs,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.history),
            label: AppLocalizations.of(context)!.navHistory,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.person),
            label: AppLocalizations.of(context)!.navProfile,
          ),
        ],
      ),
    );
  }
}

class _AvailableJobsTab extends StatelessWidget {
  const _AvailableJobsTab();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Order>>(
      stream: FirebaseService.getPendingOrders(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
                '${AppLocalizations.of(context)!.error}: ${snapshot.error}'),
          );
        }

        final orders = snapshot.data ?? [];

        if (orders.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.work_off,
                  size: 80,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  AppLocalizations.of(context)!.noAvailableJobs,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  AppLocalizations.of(context)!.newRequestsAppearHere,
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: orders.length,
          itemBuilder: (context, index) {
            final order = orders[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildOrderCard(context, order),
            );
          },
        );
      },
    );
  }

  Widget _buildOrderCard(BuildContext context, Order order) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: const BoxDecoration(
                    color: Colors.orange,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    order.address,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    PriceDisplay(price: order.total, showLabel: false),
                    const SizedBox(height: 4),
                    PaymentMethodDisplay(
                      paymentMethod: order.paymentMethod,
                      showLabel: false,
                      iconSize: 14,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${AppLocalizations.of(context)!.date}: ${_formatDate(order.requestedDate)}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            if (order.notes != null && order.notes!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                '${AppLocalizations.of(context)!.notes}: ${order.notes}',
                style: Theme.of(context).textTheme.bodyMedium,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 12),
            ServiceFeeNotice(
              onTap: () => Navigator.pushNamed(context, Routes.servicesPayment),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _rejectOrder(context, order),
                    child: Text(AppLocalizations.of(context)!.reject),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _acceptOrder(context, order),
                    child: Text(AppLocalizations.of(context)!.accept),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _acceptOrder(BuildContext context, Order order) async {
    final agreed = await showProviderAgreementDialog(
      context,
      driverAmount: order.price,
    );
    if (!agreed) return;
    try {
      await FirebaseService.updateOrderStatus(
        order.id,
        OrderStatus.assigned,
        providerId: FirebaseAuth.instance.currentUser!.uid,
      );

      // Send notification to customer
      if (!context.mounted) return;
      final l = AppLocalizations.of(context)!;
      await FirebaseService.sendNotificationToUser(
        order.customerId,
        l.notifOrderAcceptedTitle,
        l.notifOrderAcceptedBody,
      );

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l.orderAcceptedSuccess),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      final l = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${l.error}: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _rejectOrder(BuildContext context, Order order) async {
    // For now, we'll just show a message
    // In a real app, you might want to track rejections
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.orderRejected),
        ),
      );
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} at ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}

class _MyJobsTab extends StatelessWidget {
  const _MyJobsTab();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Order>>(
      stream: FirebaseService.getActiveOrdersForProvider(
        FirebaseAuth.instance.currentUser!.uid,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
                '${AppLocalizations.of(context)!.error}: ${snapshot.error}'),
          );
        }

        final orders = snapshot.data ?? [];

        if (orders.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.assignment_outlined,
                  size: 80,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  AppLocalizations.of(context)!.noJobsYet,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  AppLocalizations.of(context)!.acceptedJobsAppearHere,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: orders.length,
          itemBuilder: (context, index) {
            final order = orders[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildOrderCard(context, order),
            );
          },
        );
      },
    );
  }

  Widget _buildOrderCard(BuildContext context, Order order) {
    return Card(
      child: InkWell(
        onTap: () {
          // Navigate to order details
          _showOrderDetails(context, order);
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: _getStatusColor(order.status),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      order.address,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  Text(
                    orderStatusText(context, order.status),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: _getStatusColor(order.status),
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '${AppLocalizations.of(context)!.volume}: ${order.volume}L',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Text(
                    '${AppLocalizations.of(context)!.date}: ${_formatDate(order.requestedDate)}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(width: 8),
                  PriceDisplay(price: order.total, showLabel: false),
                ],
              ),
              const SizedBox(height: 6),
              if (order.serviceFeePaid)
                FutureBuilder<Map<String, dynamic>?>(
                  future: FirebaseService.getUserContact(order.customerId),
                  builder: (context, snap) {
                    if (snap.connectionState != ConnectionState.done) {
                      return const SizedBox.shrink();
                    }
                    final data = snap.data ?? {};
                    final name = data['fullName'] ?? data['name'] ?? 'Customer';
                    final phone = data['phone'] ?? '-';
                    return Text(
                      '${AppLocalizations.of(context)!.customer}: $name, $phone',
                      style: Theme.of(context).textTheme.bodyMedium,
                    );
                  },
                ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Text(
                    '${AppLocalizations.of(context)!.method}: ',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  PaymentMethodDisplay(
                    paymentMethod: order.paymentMethod,
                    showLabel: true,
                    iconSize: 14,
                  ),
                ],
              ),
              if (order.notes != null && order.notes!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  '${AppLocalizations.of(context)!.notes}: ${order.notes}',
                  style: Theme.of(context).textTheme.bodyMedium,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 8),
              ServiceFeeNotice(
                onTap: () =>
                    Navigator.pushNamed(context, Routes.servicesPayment),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        final canChat = order.serviceFeePaid &&
                            (order.status == OrderStatus.assigned ||
                                order.status == OrderStatus.inProgress ||
                                order.status == OrderStatus.completed);
                        if (!canChat) {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: Text(AppLocalizations.of(context)!
                                  .chatLockedTitle),
                              content: Text(AppLocalizations.of(context)!
                                  .chatLockedMessage),
                            ),
                          );
                          return;
                        }
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ChatScreen(orderId: order.id),
                          ),
                        );
                      },
                      icon: const Icon(Icons.chat),
                      label: Text(AppLocalizations.of(context)!.chat),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: order.status == OrderStatus.assigned
                          ? () => _updateStatus(
                              context, order, OrderStatus.inProgress)
                          : order.status == OrderStatus.inProgress
                              ? () => _updateStatus(
                                  context, order, OrderStatus.completed)
                              : null,
                      icon: Icon(order.status == OrderStatus.inProgress
                          ? Icons.check_circle
                          : Icons.play_arrow),
                      label: Text(order.status == OrderStatus.inProgress
                          ? AppLocalizations.of(context)!.complete
                          : AppLocalizations.of(context)!.start),
                    ),
                  ),
                ],
              ),
              if (order.status == OrderStatus.assigned) ...[
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () => _cancelOrder(context, order),
                    icon: const Icon(Icons.undo),
                    label: Text(AppLocalizations.of(context)!.cancel),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _updateStatus(
      BuildContext context, Order order, OrderStatus newStatus) async {
    try {
      // Refresh current order to ensure up-to-date status/payment
      final current = await FirebaseService.getOrderById(order.id) ?? order;

      if (!context.mounted) return;
      final l = AppLocalizations.of(context)!;

      // Enforce linear flow and commission requirement
      if (newStatus == OrderStatus.inProgress) {
        if (current.status != OrderStatus.assigned) {
          await _showAlert(
            context,
            l.invalidStatus,
            l.mustAcceptBeforeStart,
          );
          return;
        }
        if (current.serviceFeePaid == false) {
          await _showAlert(
            context,
            l.paymentRequired,
            l.waitForCommission,
          );
          return;
        }
      }
      if (newStatus == OrderStatus.completed) {
        if (current.status != OrderStatus.inProgress) {
          await _showAlert(
            context,
            l.invalidStatus,
            l.completeFlowHint,
          );
          return;
        }
      }

      await FirebaseService.updateOrderStatus(current.id, newStatus);

      // Send notification to customer
      if (!context.mounted) return;
      String? title;
      String? body;

      switch (newStatus) {
        case OrderStatus.inProgress:
          title = l.notifOnTheWayTitle;
          body = l.notifOnTheWayBody;
          break;
        case OrderStatus.completed:
          title = l.notifCompletedTitle;
          body = l.notifCompletedBody;
          break;
        default:
          title = null;
          body = null;
      }

      if (title != null && body != null) {
        await FirebaseService.sendNotificationToUser(
            order.customerId, title, body);
      }

      if (!context.mounted) return;
      final statusText = orderStatusText(context, newStatus);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l.statusUpdatedTo(statusText)),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      final l = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${l.error}: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _showAlert(
      BuildContext context, String title, String message) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.ok),
          ),
        ],
      ),
    );
  }

  void _showOrderDetails(BuildContext context, Order order) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(16),
          child: StreamBuilder<Order?>(
            stream: FirebaseService.streamOrderById(order.id),
            builder: (context, snap) {
              final o = snap.data ?? order;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    AppLocalizations.of(context)!.orderDetails,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: SingleChildScrollView(
                      controller: scrollController,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildDetailRow(
                              context,
                              AppLocalizations.of(context)!.address,
                              o.address,
                              Icons.location_on),
                          _buildDetailRow(
                              context,
                              AppLocalizations.of(context)!.volume,
                              '${o.volume}L',
                              Icons.water_drop),
                          _buildDetailRow(
                              context,
                              AppLocalizations.of(context)!.date,
                              _formatDate(o.requestedDate),
                              Icons.calendar_today),
                          _buildDetailRow(
                              context,
                              AppLocalizations.of(context)!.orderStatus,
                              orderStatusText(context, o.status),
                              Icons.info),
                          _buildDetailRow(
                              context,
                              AppLocalizations.of(context)!.totalPrice,
                              '${o.price.toStringAsFixed(0)} ₽',
                              Icons.currency_ruble),
                          _buildDetailRow(
                              context,
                              AppLocalizations.of(context)!.paymentStatus,
                              o.isPaid
                                  ? AppLocalizations.of(context)!.paid
                                  : AppLocalizations.of(context)!.pending,
                              Icons.verified),
                          _buildDetailRow(
                              context,
                              AppLocalizations.of(context)!.method,
                              _paymentMethodText(context, o.paymentMethod),
                              Icons.payment),
                          if (o.notes != null && o.notes!.isNotEmpty)
                            _buildDetailRow(
                                context,
                                AppLocalizations.of(context)!.notes,
                                o.notes!,
                                Icons.note),
                          const SizedBox(height: 12),
                          if (o.serviceFeePaid)
                            FutureBuilder<Map<String, dynamic>?>(
                              future:
                                  FirebaseService.getUserContact(o.customerId),
                              builder: (context, contactSnap) {
                                if (contactSnap.connectionState !=
                                    ConnectionState.done) {
                                  return const SizedBox.shrink();
                                }
                                final data = contactSnap.data ?? {};
                                final name =
                                    data['fullName'] ?? data['name'] ?? '-';
                                final phone = data['phone'] ?? '-';
                                return Card(
                                  child: ListTile(
                                    leading: const Icon(Icons.person),
                                    title: Text(name),
                                    subtitle: Text(phone),
                                    trailing: const Icon(Icons.phone),
                                  ),
                                );
                              },
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(
      BuildContext context, String label, String value, IconData icon) {
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

  String _paymentMethodText(BuildContext context, String? method) {
    if (method == null || method.isEmpty) return '-';
    switch (method.toLowerCase()) {
      case 'cash':
        return AppLocalizations.of(context)!.cashPayment;
      case 'card':
        return _cardPaymentLabel(context);
      case 'bank transfer':
        return AppLocalizations.of(context)!.bankTransfer;
      case 'card on completion':
        return AppLocalizations.of(context)!.cardOnCompletion;
      default:
        return method;
    }
  }

  String _cardPaymentLabel(BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;
    return locale == 'ru'
        ? 'Оплата картой онлайн'
        : 'Online card payment';
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

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} at ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _cancelOrder(BuildContext context, Order order) async {
    try {
      await FirebaseFirestore.instance.collection('orders').doc(order.id).update({
        'status': OrderStatus.paid.firestoreValue,
        'displayStatus':
            displayStatusFromRaw(OrderStatus.paid.firestoreValue),
        'providerId': null,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.driverOrderReturned),
          backgroundColor: Colors.orange,
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      final l = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${l.error}: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

class _ProfileTab extends StatelessWidget {
  const _ProfileTab();

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    child: Text(
                      user?.email?.substring(0, 1).toUpperCase() ?? 'P',
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    user?.email ?? AppLocalizations.of(context)!.unknown,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    AppLocalizations.of(context)!.roleProvider,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                  ),
                  const SizedBox(height: 12),
                  FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                    future: FirebaseFirestore.instance
                        .collection('providers')
                        .doc(user?.uid)
                        .get(),
                    builder: (context, snap) {
                      if (snap.connectionState != ConnectionState.done) {
                        return const SizedBox.shrink();
                      }
                      final data = snap.data?.data() ?? {};
                      final fullName = (data['fullName'] ?? '').toString();
                      final phone = (data['phone'] ?? '').toString();
                      if (fullName.isEmpty && phone.isEmpty) {
                        return const SizedBox.shrink();
                      }
                      return Column(
                        children: [
                          if (fullName.isNotEmpty)
                            Text(fullName,
                                style: Theme.of(context).textTheme.titleMedium),
                          if (phone.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(phone,
                                style: Theme.of(context).textTheme.bodyMedium),
                          ],
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.settings),
                  title: Text(AppLocalizations.of(context)!.settings),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            const ProfileSettingsScreen(role: 'provider'),
                      ),
                    );
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.help),
                  title: Text(AppLocalizations.of(context)!.helpSupport),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    // TODO: Implement help
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.payments_outlined),
                  title: const Text('Услуги и оплата'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    Navigator.pushNamed(context, Routes.servicesPayment);
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.description_outlined),
                  title: const Text('Публичная оферта'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    Navigator.pushNamed(context, Routes.publicOffer);
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.gavel_outlined),
                  title: const Text('Пользовательское соглашение'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    Navigator.pushNamed(context, Routes.userAgreement);
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.logout),
                  title: Text(AppLocalizations.of(context)!.signOut),
                  onTap: () async {
                    await FirebaseAuth.instance.signOut();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryTab extends StatelessWidget {
  const _HistoryTab();

  @override
  Widget build(BuildContext context) {
    // Reuse the history list used by the standalone screen
    return const ProviderJobHistoryList();
  }
}
