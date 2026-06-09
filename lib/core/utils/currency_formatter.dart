import 'package:intl/intl.dart';

class CurrencyFormatter {
  static final NumberFormat clp = NumberFormat.currency(
    locale: 'es_CL',
    symbol: '\$',
    decimalDigits: 0,
  );

  static String format(num value) {
    return clp.format(value);
  }
}
