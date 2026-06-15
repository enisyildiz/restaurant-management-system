enum PaymentMethod {
  cash,
  creditCard,
}

class PaymentRecord {
  final double amount;
  final PaymentMethod method;
  final DateTime paidAt;

  PaymentRecord({
    required this.amount,
    required this.method,
    required this.paidAt,
  });
}

extension PaymentMethodLabel on PaymentMethod {
  String get label {
    switch (this) {
      case PaymentMethod.cash:
        return 'Cash';
      case PaymentMethod.creditCard:
        return 'Credit Card';
    }
  }
}