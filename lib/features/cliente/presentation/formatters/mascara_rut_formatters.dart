import 'package:flutter/services.dart';

class RutInputFormatter extends TextInputFormatter {
  
  static String formatear(String rut) {
    String text = rut.replaceAll('.', '').replaceAll('-', '').toUpperCase();
    if (text.isEmpty) return '';
    if (text.length > 9) text = text.substring(0, 9);

    String cuerpo = text.length > 1 ? text.substring(0, text.length - 1) : text;
    String dv = text.length > 1 ? text.substring(text.length - 1) : '';

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

    if (dv.isNotEmpty) rutFormateado = '$rutFormateado-$dv';
    return rutFormateado;
  }

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

    if (text.length > 1) {
      final cuerpo = text.substring(0, text.length - 1);
      if (!RegExp(r'^\d+$').hasMatch(cuerpo)) {
        return oldValue;
      }
    }

    final rutFormateado = formatear(text);

    return TextEditingValue(
      text: rutFormateado,
      selection: TextSelection.collapsed(offset: rutFormateado.length),
    );
  }
}