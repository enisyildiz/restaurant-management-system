enum PaymentMethod {
  cash,
  creditCard,
  discount,
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

  Map<String, dynamic> toJson() {
    return {
      'amount': amount,
      'method': method.toString(),
      'paidAt': paidAt.toIso8601String(),
    };
  }

  factory PaymentRecord.fromJson(Map<String, dynamic> json) {
    return PaymentRecord(
      amount: (json['amount'] as num).toDouble(),
      method: PaymentMethod.values.firstWhere(
        (e) => e.toString() == json['method'],
        orElse: () => PaymentMethod.cash,
      ),
      paidAt: DateTime.parse(json['paidAt']),
    );
  }
}

extension PaymentMethodLabel on PaymentMethod {
  String get label {
    switch (this) {
      case PaymentMethod.cash:
        return 'Cash';
      case PaymentMethod.creditCard:
        return 'Credit Card';
      case PaymentMethod.discount:
        return 'Discount';
    }
  }
}