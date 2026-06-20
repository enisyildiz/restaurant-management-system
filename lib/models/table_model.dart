import 'order_item.dart';
import 'payment_record.dart';

enum TableStatus { empty, occupied }

class TableModel {
  final int id;
  final String code;
  final String name;
  final String area;
  TableStatus status;
  List<OrderItem> orders;
  List<PaymentRecord> payments;

  TableModel({
    required this.id,
    required this.code,
    required this.name,
    required this.area,
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

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'name': name,
      'area': area,
      'status': status.toString(),
      'orders': orders.map((e) => e.toJson()).toList(),
      'payments': payments.map((e) => e.toJson()).toList(),
    };
  }

  factory TableModel.fromJson(Map<String, dynamic> json) {
    return TableModel(
      id: json['id'] as int,
      code: json['code'] ?? json['name'],
      name: json['name'] as String,
      area: json['area'] ?? 'Genel',
      status: TableStatus.values.firstWhere(
        (e) => e.toString() == json['status'],
        orElse: () => TableStatus.empty,
      ),
      orders: (json['orders'] as List<dynamic>?)
              ?.map((e) => OrderItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      payments: (json['payments'] as List<dynamic>?)
              ?.map((e) => PaymentRecord.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}