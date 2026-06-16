import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../data/dtos/cotizacion_dtos.dart';
import '../../data/mappers/cotizacion_mapper.dart';
import '../../data/datasources/cotizacion_firebase_datasource.dart';
import '../../data/repositories/cotizacion_repository_impl.dart';   
import '../../../../shared/widgets/app_dialogs.dart';               
import '../widgets/previsualizacion_pdf.dart';

class GenerarPdfPage extends StatefulWidget {
  final CotizacionDto cotizacion;

  const GenerarPdfPage({super.key, required this.cotizacion});

  @override
  State<GenerarPdfPage> createState() => _GenerarPdfPageState();
}

class _GenerarPdfPageState extends State<GenerarPdfPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late final CotizacionFirestoreDataSource datasource;
  late final CotizacionRepositoryImpl repositoryParaPdf;

  @override
  void initState() {
    super.initState();
    datasource = CotizacionFirestoreDataSource(_firestore);
    repositoryParaPdf = CotizacionRepositoryImpl(datasource);
  }

  Future<void> _forzarGeneracionPdf(dynamic model) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PopScope(
        canPop: false,
        child: AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          content: const Row(
            children: [
              CircularProgressIndicator(color: Colors.green),
              SizedBox(width: 20),
              Expanded(
                child: Text(
                  'Generando y subiendo PDF a Storage...',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    try {
      await PrevisualizacionPdfWidget.generarYsubirPdfEstatico(
        cotizacion: model,
        materiales: model.materiales,
        codigoCotizacion: widget.cotizacion.codigo,
        manoObra: model.listaManoObra,
        idCotizacion: widget.cotizacion.id,
        repository: repositoryParaPdf,
      );
      if (!mounted) return;
      Navigator.pop(context);

      AppDialogs.mostrarSnackBar(context, '¡PDF generado exitosamente!');

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);

      AppDialogs.mostrarSnackBar(context, 'Error al regenerar el PDF: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final model = CotizacionMapper.fromDto(widget.cotizacion);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text('Generar PDF ${widget.cotizacion.codigo}')),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: PrevisualizacionPdfWidget(
                cotizacion: model,
                idCotizacion: widget.cotizacion.id,
                codigoCotizacion: widget.cotizacion.codigo,
                materiales: model.materiales,
                manoObra: model.listaManoObra,
                habilitado: true,
                onListo: () async {
                  Navigator.pop(context, true);
                },
              ),
            ),
          ),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.scaffoldBackgroundColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  offset: const Offset(0, -4),
                  blurRadius: 10,
                ),
              ],
            ),
            child: SafeArea(
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade700,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () => _forzarGeneracionPdf(model),
                  icon: const Icon(Icons.picture_as_pdf),
                  label: const Text(
                    'Generar y subir Pdf',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
