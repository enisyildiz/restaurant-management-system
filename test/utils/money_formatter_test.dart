import 'package:flutter_test/flutter_test.dart';
import 'package:restaurant_management_app/utils/money_formatter.dart';

void main() {
  group('MoneyFormatter Tests', () {
    test('Formats zero correctly', () {
      expect(MoneyFormatter.formatTl(0), '0,00 ₺');
    });

    test('Formats thousands and decimal places correctly', () {
      expect(MoneyFormatter.formatTl(1250.5), '1.250,50 ₺');
    });

    test('Formats large numbers correctly', () {
      expect(MoneyFormatter.formatTl(1000000.99), '1.000.000,99 ₺');
    });
    
    test('Rounds properly', () {
      expect(MoneyFormatter.formatTl(15.556), '15,56 ₺');
      expect(MoneyFormatter.formatTl(15.554), '15,55 ₺');
    });
  });
}
