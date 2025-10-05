import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../services/payment_config.dart';

class CloudPaymentsWebView extends StatefulWidget {
  final String orderId;
  final double amount;
  final String? customerAccountId;
  final String? description;

  const CloudPaymentsWebView({
    super.key,
    required this.orderId,
    required this.amount,
    this.customerAccountId,
    this.description,
  });

  @override
  State<CloudPaymentsWebView> createState() => _CloudPaymentsWebViewState();
}

class _CloudPaymentsWebViewState extends State<CloudPaymentsWebView> {
  late final WebViewController _controller;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..addJavaScriptChannel(
        'CP',
        onMessageReceived: (message) {
          final data = message.message;
          if (data == 'success') {
            Navigator.of(context).pop(true);
          } else {
            Navigator.of(context).pop(false);
          }
        },
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) => setState(() => _loading = false),
        ),
      );

    _loadDynamicHtml();
  }

  void _loadDynamicHtml() {
    final l = AppLocalizations.of(context)!;
    const publicId = PaymentConfig.cloudPaymentsPublicId;
    final amount = widget.amount.toStringAsFixed(2);
    final description = widget.description ?? l.serviceCommissionForOrder(widget.orderId);
    final invoiceId = widget.orderId;
    final accountId = widget.customerAccountId ?? 'customer';

    final html = '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1" />
  <title>${l.cloudPaymentsTitle}</title>
  <script src="https://widget.cloudpayments.ru/bundles/cloudpayments.js"></script>
  <style>
    html, body { background:#0f1115; color:#e6e6e6; margin:0; padding:0; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, Cantarell, 'Open Sans', 'Helvetica Neue', sans-serif; }
    .wrap { min-height:100vh; display:flex; flex-direction:column; align-items:center; justify-content:center; padding:24px; }
    .title { font-size:18px; margin-bottom:8px; text-align:center; }
    .amount { font-size:22px; font-weight:bold; margin-bottom:16px; color:#9ecbff; }
    .btn { background:#1976d2; color:#fff; padding:12px 16px; border-radius:10px; border:none; font-size:16px; }
  </style>
  <script>
    function pay() {
      try {
        const widget = new cp.CloudPayments();
        widget.pay('charge', {
          publicId: '%PUBLIC_ID%',
          description: '%DESCRIPTION%',
          amount: %AMOUNT%,
          currency: 'RUB',
          invoiceId: '%INVOICE_ID%',
          accountId: '%ACCOUNT_ID%'
        }, {
          onSuccess: function(options) { if (window.CP) CP.postMessage('success'); },
          onFail: function(reason, options) { if (window.CP) CP.postMessage('fail'); },
          onComplete: function(paymentResult, options) { }
        });
      } catch (e) {
        if (window.CP) CP.postMessage('fail');
      }
    }
    window.onload = function() { setTimeout(pay, 200); };
  </script>
  </head>
  <body>
    <div class="wrap">
      <div class="title">${l.cpProcessingTitle}</div>
      <div class="amount">₽%AMOUNT_TEXT%</div>
      <button class="btn" onclick="pay()">${l.cpRetry}</button>
    </div>
  </body>
  </html>
'''
        .replaceAll('%PUBLIC_ID%', publicId)
        .replaceAll('%DESCRIPTION%', htmlEscape.convert(description))
        .replaceAll('%AMOUNT%', amount)
        .replaceAll('%AMOUNT_TEXT%', amount)
        .replaceAll('%INVOICE_ID%', htmlEscape.convert(invoiceId))
        .replaceAll('%ACCOUNT_ID%', htmlEscape.convert(accountId));

    _controller.loadHtmlString(html);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.cloudPaymentsTitle),
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_loading)
            const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }
}
