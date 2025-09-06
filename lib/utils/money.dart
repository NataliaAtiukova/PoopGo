import '../services/payment_config.dart';

/// Rounds a numeric value to 2 decimal places in a stable way.
double roundToTwo(num value) => (value * 100).roundToDouble() / 100.0;

/// Calculates the service fee (10% by default) for the given total price.
double calculateServiceFee(double totalPrice, {double? percent}) {
  final p = percent ?? PaymentConfig.serviceFeePercent;
  return roundToTwo(totalPrice * p);
}

/// Formats a monetary amount with 2 decimal places and a ₽ sign.
String formatRub(double amount) => '₽${amount.toStringAsFixed(2)}';

