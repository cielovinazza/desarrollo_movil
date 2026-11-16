import 'package:flutter_test/flutter_test.dart';
import 'package:project/core/utils/currency_formatter.dart';

void main() {
  group('CurrencyFormatter', () {
    test('Formatea un monto en pesos chilenos', () {
      final resultado = CurrencyFormatter.format(12345);

      expect(resultado, contains('12.345'));
      expect(resultado, contains(r'$'));
    });

    test('Formatea correctamente un valor cero', () {
      final resultado = CurrencyFormatter.format(0);

      expect(resultado, contains('0'));
      expect(resultado, contains(r'$'));
    });
  });
}
