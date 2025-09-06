class PaymentConfig {
  // CloudPayments publicId for TEST mode. Replace in production.
  static const String cloudPaymentsPublicId = 'test_api_00000000000000000000002';

  // Service commission percent (e.g., 0.10 = 10%)
  static const double serviceFeePercent = 0.10;

  // Enable a simulation shortcut button for tests
  static const bool enablePaymentSimulation = true;

  // Minimum order total to require commission
  static const double minTotalForCommission = 300.0;
}
