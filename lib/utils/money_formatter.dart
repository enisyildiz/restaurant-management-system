class MoneyFormatter {
  static String formatPlain(num value) {
    final isNegative = value < 0;
    final absoluteValue = value.abs();

    final fixed = absoluteValue.toStringAsFixed(2);
    final parts = fixed.split('.');

    final integerPart = parts[0];
    final decimalPart = parts[1];

    final buffer = StringBuffer();

    for (int i = 0; i < integerPart.length; i++) {
      final reverseIndex = integerPart.length - i;

      buffer.write(integerPart[i]);

      if (reverseIndex > 1 && reverseIndex % 3 == 1) {
        buffer.write('.');
      }
    }

    final sign = isNegative ? '-' : '';

    return '$sign${buffer.toString()},$decimalPart';
  }

  static String formatTl(num value) {
    return '${formatPlain(value)} ₺';
  }

  static String formatTlText(num value) {
    return '${formatPlain(value)} TL';
  }

  static double? tryParseAmount(String? input) {
    if (input == null) return null;

    var text = input.trim();

    if (text.isEmpty) return null;

    text = text
        .replaceAll('₺', '')
        .replaceAll('TL', '')
        .replaceAll('tl', '')
        .replaceAll(' ', '');

    final hasComma = text.contains(',');
    final hasDot = text.contains('.');

    if (hasComma && hasDot) {
      final lastComma = text.lastIndexOf(',');
      final lastDot = text.lastIndexOf('.');

      if (lastComma > lastDot) {
        // Turkish style: 5.000,50
        text = text.replaceAll('.', '').replaceAll(',', '.');
      } else {
        // English style fallback: 5,000.50
        text = text.replaceAll(',', '');
      }
    } else if (hasComma) {
      // Turkish decimal: 5000,50
      text = text.replaceAll(',', '.');
    } else if (hasDot) {
      final dotCount = '.'.allMatches(text).length;
      final lastPart = text.split('.').last;

      if (dotCount == 1 && lastPart.length <= 2) {
        // Decimal dot fallback: 5000.50
      } else {
        // Turkish thousands: 5.000
        text = text.replaceAll('.', '');
      }
    }

    return double.tryParse(text);
  }
}