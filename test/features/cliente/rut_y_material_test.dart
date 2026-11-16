import 'package:flutter_test/flutter_test.dart';
import 'package:project/features/cliente/presentation/formatters/mascara_rut_formatters.dart';
import 'package:project/features/materiales/domain/entities/material.dart';

void main() {
  group('RutInputFormatter', () {
    test('Formatea correctamente un RUT', () {
      expect(RutInputFormatter.formatear('123456789'), '12.345.678-9');
    });

    test('Normaliza un RUT que ya contiene puntos y guion', () {
      expect(RutInputFormatter.formatear('12.345.678-9'), '12.345.678-9');
    });
  });

  group('MaterialEntity', () {
    test('Calcula el subtotal y redondea a dos decimales', () {
      final material = MaterialEntity(
        nombre: 'Cemento',
        unidadMedida: 'saco',
        costoUnitario: 1234.567,
        cantidad: 2,
      );

      expect(material.subtotal, 2469.13);
    });
  });
}
