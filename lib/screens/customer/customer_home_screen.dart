import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart' hide Order;

import '../../models/order.dart';
import '../../routes.dart';
import '../../services/firebase_service.dart';
import '../../widgets/price_display.dart';
import 'booking_form_screen.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'order_status_screen.dart';
import '../../utils/order_status_display.dart';
import '../shared/profile_settings_screen.dart';

class CustomerHomeScreen extends StatefulWidget {
  const CustomerHomeScreen({super.key});

  @override
  State<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends State<CustomerHomeScreen> {
  int _selectedIndex = 0;

  void setTab(int index) => setState(() => _selectedIndex = index);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.appTitle),
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
          _HomeTab(),
          _OrdersTab(),
          _ProfileTab(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.home),
            label: AppLocalizations.of(context)!.navHome,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.history),
            label: AppLocalizations.of(context)!.navOrders,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.person),
            label: AppLocalizations.of(context)!.navProfile,
          ),
        ],
      ),
      floatingActionButton: _selectedIndex == 0
          ? FloatingActionButton.extended(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const BookingFormScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.add),
              label: Text(AppLocalizations.of(context)!.requestPickup),
            )
          : null,
    );
  }
}

class _HomeTab extends StatelessWidget {
  const _HomeTab();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.of(context)!.welcomeTitle,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    AppLocalizations.of(context)!.welcomeSubtitle,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Quick Actions
          Text(
            AppLocalizations.of(context)!.quickActions,
            style: Theme.of(context).textTheme.titleLarge,
          ),

          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: _buildActionCard(
                  context,
                  AppLocalizations.of(context)!.requestPickup,
                  Icons.local_shipping,
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const BookingFormScreen(),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildActionCard(
                  context,
                  AppLocalizations.of(context)!.trackOrders,
                  Icons.track_changes,
                  () {
                    context
                        .findAncestorStateOfType<_CustomerHomeScreenState>()
                        ?.setTab(1);
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Recent Orders
          Text(
            AppLocalizations.of(context)!.recentOrders,
            style: Theme.of(context).textTheme.titleLarge,
          ),

          const SizedBox(height: 16),

          StreamBuilder<List<Order>>(
            stream: FirebaseService.getOrdersForCustomer(
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
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Icon(
                          Icons.inbox_outlined,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          AppLocalizations.of(context)!.noOrdersYet,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          AppLocalizations.of(context)!.firstOrderHint,
                          style: Theme.of(context).textTheme.bodyMedium,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              }

              return Column(
                children: orders.take(3).map((order) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildOrderCard(context, order),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(
    BuildContext context,
    String title,
    IconData icon,
    VoidCallback onTap,
  ) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Icon(
                icon,
                size: 32,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOrderCard(BuildContext context, Order order) {
    return Card(
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => OrderStatusScreen(orderId: order.id),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!order.isPaid)
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.orange.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _paymentReminderText(context),
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: Colors.orange[700]),
                        ),
                      ),
                    Text(
                      order.address,
                      style: Theme.of(context).textTheme.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    // Prevent horizontal overflow of meta row
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          Text(
                            '${order.volume}L • ${_formatDate(order.requestedDate)}',
                            style: Theme.of(context).textTheme.bodyMedium,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            softWrap: false,
                          ),
                         const SizedBox(width: 8),
                          PriceDisplay(price: order.total, showLabel: false),
                          const SizedBox(width: 8),
                          if (order.serviceFeePaid)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.green.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                AppLocalizations.of(context)!.commissionPaid,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: Colors.green,
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  customerStatusLabel(context, order.status),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  softWrap: false,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: _getStatusColor(order.status),
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
            ],
          ),
        ),
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

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _paymentReminderText(BuildContext context) {
    final locale = Localizations.localeOf(context);
    return locale.languageCode == 'ru'
        ? 'Для активации заказа оплатите сервисный сбор (10 %).'
        : 'Pay the 10% service fee to activate your order.';
  }
}

class _OrdersTab extends StatelessWidget {
  const _OrdersTab();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Order>>(
      stream: FirebaseService.getOrdersForCustomer(
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
                  Icons.inbox_outlined,
                  size: 80,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  AppLocalizations.of(context)!.noOrdersYet,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  AppLocalizations.of(context)!.firstOrderHint,
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
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => OrderStatusScreen(orderId: order.id),
            ),
          );
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
                    customerStatusLabel(context, order.status),
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
              if (order.notes != null && order.notes!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  '${AppLocalizations.of(context)!.notes}: ${order.notes}',
                  style: Theme.of(context).textTheme.bodyMedium,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
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

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
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
                      user?.email?.substring(0, 1).toUpperCase() ?? 'U',
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
                    AppLocalizations.of(context)!.roleCustomer,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                  ),
                  const SizedBox(height: 12),
                  FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                    future: FirebaseFirestore.instance
                        .collection('users')
                        .doc(user?.uid)
                        .get(),
                    builder: (context, snap) {
                      if (snap.connectionState != ConnectionState.done) {
                        return const SizedBox.shrink();
                      }
                      final data = snap.data?.data() ?? {};
                      final fullName =
                          (data['fullName'] ?? data['name'] ?? '').toString();
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
                            const ProfileSettingsScreen(role: 'customer'),
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
