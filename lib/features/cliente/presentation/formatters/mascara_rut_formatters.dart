import 'package:flutter/services.dart';

class RutInputFormatter extends TextInputFormatter {

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {

    String text = newValue.text
        .replaceAll('.', '')
        .replaceAll('-', '')
        .toUpperCase();

    if (text.isEmpty) {
      return newValue;
    }

    if (text.length > 9) {
      return oldValue;
    }

    // Solo números en el cuerpo
    if (text.length > 1) {

      String cuerpo = text.substring(
        0,
        text.length - 1,
      );

      if (!RegExp(r'^\d+$').hasMatch(cuerpo)) {
        return oldValue;
      }
    }

    // DV puede ser número o K
    String ultimo = text.substring(text.length - 1);

    if (!RegExp(r'^[0-9K]$').hasMatch(ultimo)) {
      return oldValue;
    }

    if (text.length == 1) {
      return TextEditingValue(
        text: text,

        selection: TextSelection.collapsed(
          offset: text.length,
        ),
      );
    }

    String cuerpo = text.substring(
      0,
      text.length - 1,
    );

    String dv = text.substring(text.length - 1);

    String rutFormateado = '';

    int contador = 0;

    for (int i = cuerpo.length - 1; i >= 0; i--) {

      rutFormateado =
          cuerpo[i] + rutFormateado;

      contador++;

      if (contador == 3 && i != 0) {

        rutFormateado =
            '.$rutFormateado';

        contador = 0;
      }
    }

    rutFormateado = '$rutFormateado-$dv';

    return TextEditingValue(
      text: rutFormateado,

      selection: TextSelection.collapsed(
        offset: rutFormateado.length,
      ),
    );
  }
}