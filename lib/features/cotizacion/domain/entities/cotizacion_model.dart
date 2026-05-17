import '../entities/mano_de_obra.dart';
class ItemTrabajo {
  final String tipo;
  final double metrosCuadrados;
  final double precioPorMetro;

  ItemTrabajo({
    required this.tipo,
    required this.metrosCuadrados,
    required this.precioPorMetro,
  });

  // Subtotal de este ítem específico
  double get subtotal => metrosCuadrados * precioPorMetro;
}

class CotizacionModel {
  final String direccionObra;
  
  // Tarea A: Lista de trabajos independientes (Pintura, Yeso, etc.)
  final List<ItemTrabajo> listaTrabajos;

  // Tarea B: Costos Adicionales e Impuestos
  final double? viatico; 
  final double porcentajeUtilidad; 
  final double porcentajeIva;      

  // Mocks requeridos para el Sprint 2 (Simulación de lo que hacen tus compañeros)
  final double costoMaterialesSimulado;
  final List<ManoDeObra> listaManoObra;

  CotizacionModel({
    required this.direccionObra,
    required this.listaTrabajos,
    this.viatico,
    required this.porcentajeUtilidad,
    this.porcentajeIva = 19.0,
    this.costoMaterialesSimulado = 50000.0,
    required this.listaManoObra,
  });

  // Suma total de todos los subtotales de la lista de trabajos
  double get subtotalObraTotal {
    return listaTrabajos.fold(0.0, (suma, item) => suma + item.subtotal);
  }

  double get subtotalManoObraTotal {

  return listaManoObra.fold(
    0.0,
    (suma, item) =>
        suma + item.subtotal,
  );
}

  // Fórmula: Total = (Suma Mat + Suma MO + Viático) * (1 + %Utilidad) * (1 + %IVA)
  int calcularTotalFinal() {
    double costoBaseTotal = subtotalObraTotal + 
        costoMaterialesSimulado + 
        subtotalManoObraTotal + 
        (viatico ?? 0.0);

    double factorUtilidad = 1 + (porcentajeUtilidad / 100);
    double factorIva = 1 + (porcentajeIva / 100);

    double totalCalculado = costoBaseTotal * factorUtilidad * factorIva;

    // Redondeo tradicional a CLP sin decimales
    return totalCalculado.round();
  }
}