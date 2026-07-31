import 'package:flutter_test/flutter_test.dart';
import 'package:restaurant_management_app/models/product.dart';
import 'package:restaurant_management_app/models/order_item.dart';

void main() {
  group('OrderItem Mathematical Tests', () {
    test('Calculates total price correctly for multiple quantities', () {
      final product = Product(id: 1, name: 'Çay', price: 15.0, category: 'İçecek');
      final item = OrderItem(product: product, quantity: 3, orderTime: DateTime.now());
      
      expect(item.totalPrice, 45.0);
    });

    test('Calculates total price correctly after quantity update', () {
      final product = Product(id: 2, name: 'Pizza', price: 120.0, category: 'Yiyecek');
      final item = OrderItem(product: product, quantity: 1, orderTime: DateTime.now());
      
      expect(item.totalPrice, 120.0);
      
      item.quantity = 4;
      expect(item.totalPrice, 480.0);
    });
    
    test('Handles zero quantity securely', () {
      final product = Product(id: 3, name: 'Su', price: 10.0, category: 'İçecek');
      final item = OrderItem(product: product, quantity: 0, orderTime: DateTime.now());
      
      expect(item.totalPrice, 0.0);
    });
  });
}
