class ManoDeObra {
  final String cargo;
  final double valorJornada;
  final double dias;

  ManoDeObra({
    required this.cargo,
    required this.valorJornada,
    required this.dias,
  });

  double get subtotal => valorJornada * dias;
}