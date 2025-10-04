import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'payment_fail_screen.dart';
import 'payment_success_screen.dart';

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
  bool _isNavigatingAway = false;
  bool _isPaymentChecked = false;

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
      if (_isNavigatingAway) return NavigationDecision.prevent;
      _isNavigatingAway = true;
      _isPaymentChecked = true;
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => PaymentSuccessScreen(orderId: widget.orderId),
          ),
        );
      }
      return NavigationDecision.prevent;
    }
    if (url.contains('payment-fail.html')) {
      if (_isNavigatingAway) return NavigationDecision.prevent;
      _isNavigatingAway = true;
      try {
        await FirebaseFirestore.instance
            .collection('orders')
            .doc(widget.orderId)
            .update({
          'status': 'failed',
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Не удалось обновить статус оплаты: $e')),
          );
        }
      }
      _isPaymentChecked = true;
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const PaymentFailScreen(),
          ),
        );
      }
      return NavigationDecision.prevent;
    }
    return NavigationDecision.navigate;
  }

  Future<bool> _handleExitNavigation() async {
    if (_isNavigatingAway || _isPaymentChecked) return false;
    _isNavigatingAway = true;

    try {
      final orderSnapshot = await FirebaseFirestore.instance
          .collection('orders')
          .doc(widget.orderId)
          .get();
      if (!mounted) return false;
      final data = orderSnapshot.data();
      if (orderSnapshot.exists && data?['status'] == 'paid') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => PaymentSuccessScreen(orderId: widget.orderId),
          ),
        );
      } else {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
      }
    }

    return false;
  }

  Future<void> _markProcessing() async {
    try {
      await FirebaseFirestore.instance
          .collection('orders')
          .doc(widget.orderId)
          .update({
        'status': 'processing',
        'isPaid': false,
        'serviceFeePaid': false,
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
    return WillPopScope(
      onWillPop: _handleExitNavigation,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Оплата сервисного сбора'),
          leading: BackButton(
            onPressed: () {
              _handleExitNavigation();
            },
          ),
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
      ),
    );
  }
}
