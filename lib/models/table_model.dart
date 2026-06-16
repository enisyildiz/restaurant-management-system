import 'order_item.dart';
import 'payment_record.dart';

enum TableStatus { empty, occupied }

class TableModel {
  final int id;
  final String name;
  TableStatus status;
  List<OrderItem> orders;
  List<PaymentRecord> payments;

  TableModel({
    required this.id,
    required this.name,
    this.status = TableStatus.empty,
    List<OrderItem>? orders,
    List<PaymentRecord>? payments,
  }) : orders = orders ?? [],
        payments = payments ?? [];

  double get currentTotal {
    return orders.fold(0, (sum, item) => sum + item.totalPrice);
  }

  double get totalPaid => payments.fold(
        0.0,
        (sum, payment) => sum + payment.amount,
      );

  double get remainingAmount => currentTotal - totalPaid;

  double get totalCashPaid => payments
        .where((p) => p.method == PaymentMethod.cash)
        .fold(0.0, (sum, p) => sum + p.amount);

  double get totalCardPaid => payments
        .where((p) => p.method == PaymentMethod.creditCard) // Sende enum adı neyse
        .fold(0.0, (sum, p) => sum + p.amount);
}