import 'package:flutter/material.dart';

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
          'Choose Payment Method',
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
          ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
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
    switch (method) {
      case PaymentMethod.yoomoney:
        return 'YooMoney';
      case PaymentMethod.sberpay:
        return 'SberPay';
      case PaymentMethod.tinkoff:
        return 'Tinkoff';
      case PaymentMethod.cash:
        return 'Cash Payment';
    }
  }

  String _getPaymentDescription(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.yoomoney:
        return 'Pay with YooMoney wallet';
      case PaymentMethod.sberpay:
        return 'Pay with Sberbank card';
      case PaymentMethod.tinkoff:
        return 'Pay with Tinkoff card';
      case PaymentMethod.cash:
        return 'Pay in cash to provider';
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
    return AlertDialog(
      title: const Text('Confirm Payment'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Amount: ${amount.toStringAsFixed(0)} ₽'),
          const SizedBox(height: 8),
          Text('Method: ${_getPaymentName(paymentMethod)}'),
          const SizedBox(height: 16),
          const Text(
            'This is a placeholder for future payment integration. In a real implementation, this would redirect to the payment gateway.',
            style: TextStyle(fontStyle: FontStyle.italic),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: onCancel,
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: onConfirm,
          child: const Text('Confirm Payment'),
        ),
      ],
    );
  }

  String _getPaymentName(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.yoomoney:
        return 'YooMoney';
      case PaymentMethod.sberpay:
        return 'SberPay';
      case PaymentMethod.tinkoff:
        return 'Tinkoff';
      case PaymentMethod.cash:
        return 'Cash Payment';
    }
  }
}
