import 'dart:math';
import 'product.dart';

String _generateId() {
  final random = Random();
  return List.generate(16, (_) => random.nextInt(16).toRadixString(16)).join();
}

class OrderItem {
  final String id;
  final Product product;
  double quantity;
  final DateTime orderTime;

  OrderItem({
    String? id,
    required this.product,
    this.quantity = 1,
    required this.orderTime,
  }) : id = id ?? _generateId();

  double get totalPrice => product.price * quantity;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product': product.toJson(),
      'quantity': quantity,
      'orderTime': orderTime.toIso8601String(),
    };
  }

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      id: json['id'] as String?,
      product: Product.fromJson(json['product']),
      quantity: (json['quantity'] as num).toDouble(),
      orderTime: DateTime.parse(json['orderTime'] as String),
    );
  }
}