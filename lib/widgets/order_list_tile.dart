import 'package:flutter/material.dart';
import '../models/order.dart';
import 'package:intl/intl.dart';

class OrderListTile extends StatelessWidget {
  final Order order;
  final VoidCallback? onTap;
  const OrderListTile({super.key, required this.order, this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(order.address ?? 'Unnamed location'),
      subtitle: Text('${DateFormat.yMMMd().add_jm().format(order.scheduledAt)} • ${order.volumeLiters} L'),
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

