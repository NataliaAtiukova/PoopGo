import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

/// PaymentPlaceholderScreen
///
/// A simple, user-friendly placeholder screen shown instead of a real
/// payment gateway. It explains in RU and EN that online payment will be
/// available later and provides a button to return.
///
/// TODO(payment): Replace this screen with real payment gateway integration
/// (e.g., Robokassa or another provider). The navigation entry points
/// currently push this screen instead of launching a real gateway.
class PaymentPlaceholderScreen extends StatelessWidget {
  const PaymentPlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l.paymentSummary),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.lock_outline,
                    size: 48,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Оплата через платёжный шлюз будет доступна позже. Пока что сервис работает в демо-режиме.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                Text(
                  'Payment gateway integration is coming soon. The service is currently running in demo mode.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white70),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(Icons.arrow_back),
                    label: Text(l.ok),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

