import '../entities/mano_de_obra.dart';
import '../../../materiales/domain/entities/material.dart';
import '../../../cliente/domain/entities/cliente.dart';

class ItemTrabajo {
  final String tipo;
  final double metrosCuadrados;
  final double precioPorMetro;
  final String? descripcionBreve; //Atributo opcional

  ItemTrabajo({
    required this.tipo,
    required this.metrosCuadrados,
    required this.precioPorMetro,
    this.descripcionBreve, //Parámetro opcional en el constructor
  });

  // Subtotal de este ítem específico
  double get subtotal =>
    double.parse((metrosCuadrados * precioPorMetro).toStringAsFixed(2));
}

class CotizacionModel {
  final Cliente cliente;
  final String direccionObra;
  final List<ItemTrabajo> listaTrabajos;
  final double? viatico; 
  final double porcentajeUtilidad; 
  final double porcentajeIva; 
  final List<MaterialEntity> materiales;     
  final List<ManoDeObra> listaManoObra;

  CotizacionModel({
    required this.cliente,
    required this.direccionObra,
    required this.listaTrabajos,
    this.viatico,
    required this.porcentajeUtilidad,
    this.porcentajeIva = 19.0,
    required this.materiales,
    required this.listaManoObra,
  });

  // Suma total de todos los subtotales de la lista de trabajos
  double get subtotalObraTotal {
    final total = listaTrabajos.fold(
      0.0,
      (suma, item) => suma + item.subtotal,
    );
    return double.parse(total.toStringAsFixed(2));
  }

  double get subtotalMateriales {
    final total = materiales.fold(
      0.0,
      (suma, item) => suma + item.subtotal,
    );
    return double.parse(total.toStringAsFixed(2));
  }
  
  double get subtotalManoObraTotal {
    final total = listaManoObra.fold(
      0.0,
      (suma, item) => suma + item.subtotal,
    );
    return double.parse(total.toStringAsFixed(2));
  }

  // Fórmula: Total = (Suma Mat + Suma MO + Viático) * (1 + %Utilidad) * (1 + %IVA)
  double calcularTotalFinal() {
    double costoBaseTotal = subtotalObraTotal + 
        subtotalMateriales + 
        subtotalManoObraTotal + 
        (viatico ?? 0.0);

    double factorUtilidad = 1 + (porcentajeUtilidad / 100);
    double factorIva = 1 + (porcentajeIva / 100);

    double totalCalculado = costoBaseTotal * factorUtilidad * factorIva;
    totalCalculado =
      double.parse(totalCalculado.toStringAsFixed(2));

    // Redondeo tradicional a CLP sin decimales
    return totalCalculado.roundToDouble();
  } 
}