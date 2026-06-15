class OrderItem {
  final String productId;
  final String name;
  final double unitPrice;
  int quantity;

  OrderItem({
    required this.productId,
    required this.name,
    required this.unitPrice,
    this.quantity = 1,
  });

  double get totalPrice => unitPrice * quantity;
}