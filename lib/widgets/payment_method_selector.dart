import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

enum PaymentMethod {
  yoomoney,
  sberpay,
  tinkoff,
  cash,
}

class PaymentMethodSelector extends StatefulWidget {
  final PaymentMethod? selectedMethod;
  final ValueChanged<PaymentMethod?>? onChanged;

  const PaymentMethodSelector({
    super.key,
    this.selectedMethod,
    this.onChanged,
  });

  @override
  State<PaymentMethodSelector> createState() => _PaymentMethodSelectorState();
}

class _PaymentMethodSelectorState extends State<PaymentMethodSelector> {
  PaymentMethod? _selectedMethod;

  @override
  void initState() {
    super.initState();
    _selectedMethod = widget.selectedMethod;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.choosePaymentMethod,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ...PaymentMethod.values.map((method) => _buildPaymentMethodTile(method)),
      ],
    );
  }

  Widget _buildPaymentMethodTile(PaymentMethod method) {
    final isSelected = _selectedMethod == method;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: isSelected 
          ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.1)
          : null,
      child: ListTile(
        leading: _getPaymentIcon(method),
        title: Text(_getPaymentName(method)),
        subtitle: Text(_getPaymentDescription(method)),
        trailing: isSelected 
            ? Icon(
                Icons.check_circle,
                color: Theme.of(context).colorScheme.primary,
              )
            : null,
        onTap: () {
          setState(() {
            _selectedMethod = method;
          });
          widget.onChanged?.call(method);
        },
      ),
    );
  }

  Widget _getPaymentIcon(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.yoomoney:
        return Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.purple,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.account_balance_wallet,
            color: Colors.white,
            size: 20,
          ),
        );
      case PaymentMethod.sberpay:
        return Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.green,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.credit_card,
            color: Colors.white,
            size: 20,
          ),
        );
      case PaymentMethod.tinkoff:
        return Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.yellow[700],
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.payment,
            color: Colors.white,
            size: 20,
          ),
        );
      case PaymentMethod.cash:
        return Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.orange,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.money,
            color: Colors.white,
            size: 20,
          ),
        );
    }
  }

  String _getPaymentName(PaymentMethod method) {
    final l = AppLocalizations.of(context)!;
    switch (method) {
      case PaymentMethod.yoomoney:
        return l.yoomoney;
      case PaymentMethod.sberpay:
        return l.sberpay;
      case PaymentMethod.tinkoff:
        return l.tinkoff;
      case PaymentMethod.cash:
        return l.cashPayment;
    }
  }

  String _getPaymentDescription(PaymentMethod method) {
    final l = AppLocalizations.of(context)!;
    switch (method) {
      case PaymentMethod.yoomoney:
        return l.payWithYooMoney;
      case PaymentMethod.sberpay:
        return l.payWithSber;
      case PaymentMethod.tinkoff:
        return l.payWithTinkoff;
      case PaymentMethod.cash:
        return l.payInCash;
    }
  }
}

class PaymentConfirmationDialog extends StatelessWidget {
  final double amount;
  final PaymentMethod paymentMethod;
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;

  const PaymentConfirmationDialog({
    super.key,
    required this.amount,
    required this.paymentMethod,
    this.onConfirm,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(l.confirmPayment),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${l.amount}: ${amount.toStringAsFixed(0)} ₽'),
          const SizedBox(height: 8),
          Text('${l.methodLabel}: ${_getPaymentName(context, paymentMethod)}'),
          const SizedBox(height: 16),
          Text(
            l.paymentIntegrationPlaceholder,
            style: const TextStyle(fontStyle: FontStyle.italic),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: onCancel,
          child: Text(l.cancel),
        ),
        ElevatedButton(
          onPressed: onConfirm,
          child: Text(l.confirmPayment),
        ),
      ],
    );
  }

  String _getPaymentName(BuildContext context, PaymentMethod method) {
    final l = AppLocalizations.of(context)!;
    switch (method) {
      case PaymentMethod.yoomoney:
        return l.yoomoney;
      case PaymentMethod.sberpay:
        return l.sberpay;
      case PaymentMethod.tinkoff:
        return l.tinkoff;
      case PaymentMethod.cash:
        return l.cashPayment;
    }
  }
}
