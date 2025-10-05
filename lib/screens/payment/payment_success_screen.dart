import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../models/order.dart';
import '../../utils/order_status_display.dart';
import '../customer/order_status_screen.dart';

class PaymentSuccessScreen extends StatefulWidget {
  final String orderId;
  const PaymentSuccessScreen({super.key, required this.orderId});

  @override
  State<PaymentSuccessScreen> createState() => _PaymentSuccessScreenState();
}

class _PaymentSuccessScreenState extends State<PaymentSuccessScreen> {
  bool _isUpdating = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _markPaid();
  }

  Future<void> _markPaid() async {
    try {
      await FirebaseFirestore.instance.collection('orders').doc(widget.orderId).update({
        'isPaid': true,
        'serviceFeePaid': true,
        'status': OrderStatus.paid.firestoreValue,
        'paidAt': FieldValue.serverTimestamp(),
        'displayStatus':
            displayStatusFromRaw(OrderStatus.paid.firestoreValue),
      });
      if (!mounted) return;
      setState(() {
        _isUpdating = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isUpdating = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Оплата сервисного сбора'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _error == null ? '✅' : '⚠️',
                style: const TextStyle(fontSize: 64),
              ),
              const SizedBox(height: 16),
              if (_isUpdating) ...[
                const CircularProgressIndicator(),
                const SizedBox(height: 12),
                Text(
                  _localized(context,
                      ru: 'Подтверждаем оплату...',
                      en: 'Finalising payment...'),
                  textAlign: TextAlign.center,
                ),
              ] else if (_error != null) ...[
                Text(
                  _localized(context,
                      ru: 'Не удалось обновить статус заказа.',
                      en: 'Failed to update order status.'),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(color: Colors.redAccent),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _isUpdating = true;
                      _error = null;
                    });
                    _markPaid();
                  },
                  child: Text(_localized(context,
                      ru: 'Повторить попытку', en: 'Try again')),
                ),
              ] else ...[
                Text(
                  _localized(context,
                      ru: 'Спасибо! Сервисный сбор оплачен.',
                      en: 'Thank you! The service fee has been paid.'),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  _localized(context,
                      ru: 'Заказ доступен исполнителям. Мы уже уведомили водителей.',
                      en: 'Your order is now visible to drivers.'),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) => OrderStatusScreen(orderId: widget.orderId),
                        ),
                      );
                    },
                    child: Text(_localized(context,
                        ru: 'Перейти к заказу', en: 'Go to order')),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

String _localized(BuildContext context, {required String ru, required String en}) {
  final locale = Localizations.localeOf(context);
  return locale.languageCode == 'ru' ? ru : en;
}
