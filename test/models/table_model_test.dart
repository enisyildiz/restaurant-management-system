import 'package:flutter_test/flutter_test.dart';
import 'package:restaurant_management_app/models/table_model.dart';
import 'package:restaurant_management_app/models/product.dart';
import 'package:restaurant_management_app/models/order_item.dart';
import 'package:restaurant_management_app/models/order_group.dart';
import 'package:restaurant_management_app/models/payment_record.dart';

void main() {
  group('TableModel Functionality Tests', () {
    test('Calculates totals, payments, and discounts correctly', () {
      final table = TableModel(
        id: 1,
        code: 'T1',
        name: 'Masa 1',
        area: 'Salon',
      );

      final product1 = Product(id: 1, name: 'Çay', price: 15.0, category: 'İçecek');
      final product2 = Product(id: 2, name: 'Tatlı', price: 100.0, category: 'Yiyecek');

      // Siparişleri ekle
      table.orderGroups = [
        OrderGroup(items: [
          OrderItem(product: product1, quantity: 2, orderTime: DateTime.now()), // 30 TL
          OrderItem(product: product2, quantity: 1, orderTime: DateTime.now()), // 100 TL
        ])
      ];

      expect(table.currentTotal, 130.0);
      expect(table.remainingAmount, 130.0);

      // 50 TL Nakit ödeme al
      table.payments.add(PaymentRecord(amount: 50.0, method: PaymentMethod.cash, paidAt: DateTime.now()));
      
      expect(table.totalPaid, 50.0);
      expect(table.totalCashPaid, 50.0);
      expect(table.totalCardPaid, 0.0);
      expect(table.remainingAmount, 80.0);

      // 30 TL Kart ödeme al
      table.payments.add(PaymentRecord(amount: 30.0, method: PaymentMethod.creditCard, paidAt: DateTime.now()));
      
      expect(table.totalPaid, 80.0);
      expect(table.totalCardPaid, 30.0);
      expect(table.remainingAmount, 50.0);

      // Kalan 50 TL'yi İndirim (Discount) yap
      table.payments.add(PaymentRecord(amount: 50.0, method: PaymentMethod.discount, paidAt: DateTime.now()));
      
      expect(table.totalDiscount, 50.0);
      expect(table.totalPaid, 130.0); // Ödenenler (Nakit + Kart + İndirim)
      expect(table.remainingAmount, 0.0);
    });

    test('Custom prices override default product prices', () {
      final table = TableModel(
        id: 2,
        code: 'T2',
        name: 'Masa 2',
        area: 'Salon',
      );

      final product = Product(id: 1, name: 'Çay', price: 15.0, category: 'İçecek');

      table.orderGroups = [
        OrderGroup(items: [
          OrderItem(product: product, quantity: 2, orderTime: DateTime.now()), // Normalde 30 TL
        ])
      ];

      expect(table.currentTotal, 30.0);

      // Çayın fiyatını bu masaya özel 10 TL yap
      table.customPrices = {1: 10.0};

      expect(table.currentTotal, 20.0);
    });
  });
}
