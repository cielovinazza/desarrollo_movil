import 'package:flutter_test/flutter_test.dart';
import 'package:project/features/cliente/domain/entities/cliente.dart';

void main() {
  group('Entidad Cliente', () {
    test('Convierte un cliente a JSON y recupera sus datos', () {
      final cliente = Cliente(
        id: '1',
        nombre: 'Cristobal',
        rut: '12345678-9',
        telefono: '912345678',
        correo: 'cliente@email.com',
        direccion: 'Santiago',
      );

      final recuperado = Cliente.fromJson(cliente.toJson());

      expect(recuperado.nombre, cliente.nombre);
      expect(recuperado.rut, cliente.rut);
      expect(recuperado.correo, cliente.correo);
      expect(recuperado.id, cliente.id);
    });

    test('copyWith modifica el nombre sin alterar los demás datos', () {
      final cliente = Cliente(
        nombre: 'Juan',
        rut: '12345678-9',
        telefono: '912345678',
        correo: 'juan@email.com',
      );

      final actualizado = cliente.copyWith(nombre: 'Pedro');

      expect(actualizado.nombre, 'Pedro');
      expect(actualizado.rut, cliente.rut);
      expect(actualizado.telefono, cliente.telefono);
    });
  });
}
