import 'order_item.dart';

enum TableStatus { empty, occupied }

class TableModel {
  final int id;
  final String name;
  TableStatus status;
  List<OrderItem> orders;

  TableModel({
    required this.id,
    required this.name,
    this.status = TableStatus.empty,
    List<OrderItem>? orders,
  }) : orders = orders ?? [];

  double get totalBill {
    return orders.fold(0, (sum, item) => sum + item.totalPrice);
  }
}