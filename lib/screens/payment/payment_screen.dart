import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../models/order.dart';
import '../../utils/order_status_display.dart';

/// Экран оплаты через WebView. Загружает платёжную страницу и отслеживает
/// редиректы для определения успешной либо неуспешной оплаты.
class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key, required this.orderId});

  final String orderId;

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;
  bool _paymentFinished = false;

  @override
  void initState() {
    super.initState();
    _markProcessing();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFFFFFFFF))
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) => setState(() => _isLoading = true),
          onPageFinished: (_) => setState(() => _isLoading = false),
          onNavigationRequest: _onNavigationRequest,
        ),
      )
      ..loadRequest(Uri.parse('https://poopgo.payform.ru/'));
  }

  Future<NavigationDecision> _onNavigationRequest(
      NavigationRequest request) async {
    final url = request.url;
    if (url.contains('payment-success.html')) {
      if (_paymentFinished) return NavigationDecision.prevent;
      setState(() => _paymentFinished = true);
      try {
        await FirebaseFirestore.instance
            .collection('orders')
            .doc(widget.orderId)
            .update({
          'status': OrderStatus.paid.firestoreValue,
          'isPaid': true,
          'serviceFeePaid': true,
          'paidAt': FieldValue.serverTimestamp(),
          'displayStatus':
              displayStatusFromRaw(OrderStatus.paid.firestoreValue),
        });
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Не удалось обновить статус оплаты: $e')),
          );
        }
      }
      if (mounted) {
        Navigator.pushReplacementNamed(
          context,
          '/payment-success',
          arguments: widget.orderId,
        );
      }
      return NavigationDecision.prevent;
    }
    if (url.contains('payment-fail.html')) {
      if (_paymentFinished) return NavigationDecision.prevent;
      setState(() => _paymentFinished = true);
      try {
        await FirebaseFirestore.instance
            .collection('orders')
            .doc(widget.orderId)
            .update({
          'status': 'failed',
          'displayStatus': displayStatusFromRaw('failed'),
        });
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Не удалось обновить статус оплаты: $e')),
          );
        }
      }
      if (mounted) {
        Navigator.pushReplacementNamed(
          context,
          '/payment-fail',
        );
      }
      return NavigationDecision.prevent;
    }
    return NavigationDecision.navigate;
  }

  Future<void> _markProcessing() async {
    try {
        await FirebaseFirestore.instance
            .collection('orders')
            .doc(widget.orderId)
            .update({
          'status': OrderStatus.processing.firestoreValue,
          'isPaid': false,
          'serviceFeePaid': false,
          'displayStatus':
              displayStatusFromRaw(OrderStatus.processing.firestoreValue),
          'updatedAt': FieldValue.serverTimestamp(),
        });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Не удалось обновить статус оплаты: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _paymentFinished,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (!mounted || _paymentFinished) return;
        await showDialog<void>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Оплата не завершена'),
            content: const Text('Пожалуйста, завершите платёж перед выходом.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Остаться'),
              ),
            ],
          ),
        );
      },
      child: Scaffold(
        body: Stack(
          children: [
            Positioned.fill(
              child: WebViewWidget(controller: _controller),
            ),
            if (_isLoading)
              const ColoredBox(
                color: Colors.black26,
                child: Center(child: CircularProgressIndicator()),
              ),
          ],
        ),
      ),
    );
  }
}
