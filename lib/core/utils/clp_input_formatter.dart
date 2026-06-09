import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class ClpInputFormatter extends TextInputFormatter {
  final int maxDigits;

  ClpInputFormatter({this.maxDigits = 9});

  static final NumberFormat _formatter = NumberFormat.decimalPattern('es_CL');

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    String digitsOnly = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');

    if (digitsOnly.length > maxDigits) {
      digitsOnly = digitsOnly.substring(0, maxDigits);
    }

    if (digitsOnly.isEmpty) {
      return const TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      );
    }

    final number = int.parse(digitsOnly);
    final newText = '\$ ${_formatter.format(number)}';

    return TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
    );
  }

  static double toDouble(String value) {
    final digitsOnly = value.replaceAll(RegExp(r'[^0-9]'), '');

    if (digitsOnly.isEmpty) return 0;

    return double.parse(digitsOnly);
  }

  static String formatNumber(num value) {
    return '\$ ${_formatter.format(value)}';
  }
}
