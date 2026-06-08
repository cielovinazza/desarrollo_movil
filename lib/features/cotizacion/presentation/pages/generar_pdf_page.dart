import 'package:flutter/material.dart';

import '../../data/dtos/cotizacion_dtos.dart';
import '../../data/mappers/cotizacion_mapper.dart';
import '../widgets/previsualizacion_pdf.dart';

class GenerarPdfPage extends StatelessWidget {
  final CotizacionDto cotizacion;

  const GenerarPdfPage({
    super.key,
    required this.cotizacion,
  });

  @override
  Widget build(BuildContext context) {
    final model = CotizacionMapper.fromDto(cotizacion);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Generar PDF ${cotizacion.codigo}',
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: PrevisualizacionPdfWidget(
          cotizacion: model,
          idCotizacion: cotizacion.id,
          codigoCotizacion: cotizacion.codigo,
          materiales: model.materiales,
          manoObra: model.listaManoObra,
          habilitado: true,
          onListo: () async {
            Navigator.pop(context, true);
          },
        ),
      ),
    );
  }
}