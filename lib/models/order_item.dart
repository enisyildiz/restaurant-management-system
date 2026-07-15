import 'product.dart';

class OrderItem {
  final Product product;
  double quantity;
  final DateTime orderTime;

  OrderItem({
    required this.product,
    this.quantity = 1,
    required this.orderTime,
  });

  double get totalPrice => product.price * quantity;

  Map<String, dynamic> toJson() {
    return {
      'product': product.toJson(),
      'quantity': quantity,
      'orderTime': orderTime.toIso8601String(),
    };
  }

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      product: Product.fromJson(json['product']),
      quantity: (json['quantity'] as num).toDouble(),
      orderTime: DateTime.parse(json['orderTime'] as String),
    );
  }
}