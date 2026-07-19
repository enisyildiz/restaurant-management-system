import 'order_group.dart';
import 'order_item.dart';
import 'payment_record.dart';
import 'product.dart';

enum TableStatus { empty, occupied }

class TableModel {
  final int id;
  final String code;
  final String name;
  final String area;
  TableStatus status;
  List<OrderGroup> orderGroups;
  List<PaymentRecord> payments;

  int? activeSessionId;
  DateTime? seatedAt;
  Map<int, double> customPrices;

  TableModel({
  required this.id,
  required this.code,
  required this.name,
  required this.area,
  this.status = TableStatus.empty,
  List<OrderGroup>? orderGroups,
  List<PaymentRecord>? payments,
  this.activeSessionId,
  this.seatedAt,
  Map<int, double>? customPrices,
}) : orderGroups = orderGroups ?? [],
      payments = payments ?? [],
      customPrices = customPrices ?? {};

  List<OrderItem> get orders {
    final List<OrderItem> list = [];
    for (final group in orderGroups) {
      for (final item in group.items) {
        final effectivePrice = customPrices[item.product.id] ?? item.product.price;
        final effectiveProduct = Product(
          id: item.product.id,
          name: item.product.name,
          price: effectivePrice,
          category: item.product.category,
        );
        list.add(OrderItem(
          id: item.id,
          product: effectiveProduct,
          quantity: item.quantity,
          orderTime: item.orderTime,
        ));
      }
    }
    return list;
  }

  double get currentTotal {
    double total = 0;
    for (final group in orderGroups) {
      for (final item in group.items) {
        final price = customPrices[item.product.id] ?? item.product.price;
        total += price * item.quantity;
      }
    }
    return total;
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

  double get totalDiscount => payments
        .where((p) => p.method == PaymentMethod.discount)
        .fold(0.0, (sum, p) => sum + p.amount);

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'name': name,
      'area': area,
      'status': status.toString(),
      'orderGroups': orderGroups.map((o) => o.toJson()).toList(),
      'payments': payments.map((e) => e.toJson()).toList(),
      'activeSessionId': activeSessionId,
      'seatedAt': seatedAt?.toIso8601String(),
      'customPrices': customPrices.map((key, value) => MapEntry(key.toString(), value)),
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
      orderGroups: (json['orderGroups'] as List<dynamic>?)
              ?.map((o) => OrderGroup.fromJson(o as Map<String, dynamic>))
              .toList() ??
          [],
      payments: (json['payments'] as List<dynamic>?)
              ?.map((e) => PaymentRecord.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      activeSessionId: json['activeSessionId'] as int?,
      seatedAt: json['seatedAt'] == null
          ? null
          : DateTime.parse(json['seatedAt'] as String),
      customPrices: json['customPrices'] == null
          ? {}
          : (json['customPrices'] as Map<String, dynamic>).map(
              (key, value) => MapEntry(int.parse(key), (value as num).toDouble()),
            ),
    );
  }
}