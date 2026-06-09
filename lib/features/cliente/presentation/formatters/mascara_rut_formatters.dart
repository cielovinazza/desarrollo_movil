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

    // máximo 9 caracteres (8 + DV)
    if (text.length > 9) {
      return oldValue;
    }

    // solo validar cuerpo numérico (sin DV aún)
    if (text.length > 1) {
      final cuerpo = text.substring(0, text.length - 1);

      if (!RegExp(r'^\d+$').hasMatch(cuerpo)) {
        return oldValue;
      }
    }

    String cuerpo = text;
    String dv = '';

    if (text.length > 1) {
      cuerpo = text.substring(0, text.length - 1);
      dv = text.substring(text.length - 1);
    }

    // formatear con puntos
    String rutFormateado = '';
    int contador = 0;

    for (int i = cuerpo.length - 1; i >= 0; i--) {
      rutFormateado = cuerpo[i] + rutFormateado;
      contador++;

      if (contador == 3 && i != 0) {
        rutFormateado = '.$rutFormateado';
        contador = 0;
      }
    }

    // agregar DV si existe
    if (dv.isNotEmpty) {
      rutFormateado = '$rutFormateado-$dv';
    }

    return TextEditingValue(
      text: rutFormateado,
      selection: TextSelection.collapsed(offset: rutFormateado.length),
    );
  }
}