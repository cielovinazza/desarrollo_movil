import 'package:flutter_test/flutter_test.dart';
import 'package:project/core/utils/strings_extensions.dart';

void main() {
  group('StringCapitalization', () {
    test('Convierte una frase a Title Case', () {
      expect('hola mundo'.toTitleCase(), 'Hola Mundo');
    });

    test('Elimina espacios y controla cadenas vacías', () {
      expect('   '.toTitleCase(), '');
      expect('  HOLA   MUNDO  '.toTitleCase(), 'Hola Mundo');
    });
  });
}
