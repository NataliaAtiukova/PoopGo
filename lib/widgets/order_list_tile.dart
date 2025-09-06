import 'package:flutter/material.dart';
import '../models/order.dart';
import 'package:intl/intl.dart';
import 'payment_method_display.dart';

class OrderListTile extends StatelessWidget {
  final Order order;
  final VoidCallback? onTap;
  const OrderListTile({super.key, required this.order, this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(order.address),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${DateFormat.yMMMd().add_jm().format(order.requestedDate)} • ${order.volume}L'),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(
                Icons.attach_money,
                size: 16,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 4),
              Text(
                '${order.price.toStringAsFixed(0)} ₽',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              PaymentMethodDisplay(
                paymentMethod: order.paymentMethod,
                showLabel: false,
                iconSize: 14,
              ),
            ],
          ),
        ],
      ),
      trailing: _StatusChip(status: order.status),
      onTap: onTap,
    );
  }
}

class _StatusChip extends StatelessWidget {
  final OrderStatus status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      OrderStatus.pending => Colors.orange,
      OrderStatus.accepted => Colors.blue,
      OrderStatus.onTheWay => Colors.purple,
      OrderStatus.completed => Colors.green,
    };
    return Chip(
      label: Text(status.name),
      backgroundColor: color.withOpacity(.15),
      labelStyle: TextStyle(color: color),
    );
  }
}

