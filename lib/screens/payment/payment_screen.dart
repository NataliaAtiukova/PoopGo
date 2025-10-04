import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

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
  bool _resultHandled = false;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFFFFFFFF))
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) => setState(() => _isLoading = true),
          onPageFinished: (_) => setState(() => _isLoading = false),
          onNavigationRequest: (request) => _handleNavigation(request.url),
        ),
      )
      ..loadRequest(Uri.parse('https://poopgo.payform.ru/'));
  }

  NavigationDecision _handleNavigation(String url) {
    if (url.contains('nataliaatiukova.github.io/payment-success.html')) {
      _handlePaymentResult(success: true);
      return NavigationDecision.prevent;
    }
    if (url.contains('nataliaatiukova.github.io/payment-fail.html')) {
      _handlePaymentResult(success: false);
      return NavigationDecision.prevent;
    }
    return NavigationDecision.navigate;
  }

  Future<void> _handlePaymentResult({required bool success}) async {
    if (_resultHandled) return;
    _resultHandled = true;

    try {
      final update = <String, dynamic>{
        'status': success ? 'paid' : 'failed',
        if (success) 'paidAt': FieldValue.serverTimestamp(),
        'serviceFeePaid': success,
      };

      await FirebaseFirestore.instance
          .collection('orders')
          .doc(widget.orderId)
          .update(update);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Не удалось обновить статус оплаты: $e')),
        );
      }
    } finally {
      if (!mounted) return;
      Navigator.pushReplacementNamed(
        context,
        success ? '/payment-success' : '/payment-fail',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Оплата сервисного сбора'),
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(),
            ),
        ],
      ),
    );
  }
}
