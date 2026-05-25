class ManoDeObra {
  final String cargo;
  final double valorJornada;
  final int dias;

  ManoDeObra({
    required this.cargo,
    required this.valorJornada,
    required this.dias,
  });

  double get subtotal => valorJornada * dias;
}