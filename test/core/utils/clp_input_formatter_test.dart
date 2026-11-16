import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project/core/utils/clp_input_formatter.dart';

void main() {
  group('ClpInputFormatter', () {
    test('Convierte los dígitos a formato de pesos chilenos', () {
      final formatter = ClpInputFormatter();

      final resultado = formatter.formatEditUpdate(
        const TextEditingValue(text: ''),
        const TextEditingValue(text: '1234'),
      );

      expect(resultado.text, contains(r'$'));
      expect(resultado.text, contains('1.234'));
    });

    test('Limita la cantidad máxima de dígitos', () {
      final formatter = ClpInputFormatter(maxDigits: 5);

      final resultado = formatter.formatEditUpdate(
        const TextEditingValue(text: ''),
        const TextEditingValue(text: '123456789'),
      );

      expect(ClpInputFormatter.toDouble(resultado.text), 12345);
    });

    test('Convierte texto formateado a número', () {
      expect(ClpInputFormatter.toDouble('\$ 12.345'), 12345);
      expect(ClpInputFormatter.toDouble(''), 0);
    });
  });
}
