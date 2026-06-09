import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/cotizacion_model.dart';
import '../../domain/entities/mano_de_obra.dart';
import 'package:project/features/materiales/domain/entities/material.dart';
import '../../data/datasources/cotizacion_firebase_datasource.dart';
import '../../data/repositories/cotizacion_repository_impl.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../shared/widgets/app_dialogs.dart';

class PrevisualizacionPdfWidget extends StatefulWidget {
  final CotizacionModel cotizacion;
  final List<MaterialEntity> materiales;
  final String codigoCotizacion;
  final List<ManoDeObra> manoObra;
  final Future<void> Function() onListo;
  final String idCotizacion;
  final bool habilitado;

  const PrevisualizacionPdfWidget({
    super.key,
    required this.cotizacion,
    required this.idCotizacion,
    required this.materiales,
    required this.codigoCotizacion,
    required this.manoObra,
    required this.onListo,
    required this.habilitado,
  });

  static Future<void> generarYsubirPdfEstatico({
    required CotizacionModel cotizacion,
    required List<MaterialEntity> materiales,
    required String codigoCotizacion,
    required List<ManoDeObra> manoObra,
    required String idCotizacion,
    required CotizacionRepositoryImpl repository,
  }) async {
    final pdf = pw.Document();
    final cliente = cotizacion.cliente;

    double subtotalMateriales = materiales.fold(0.0, (suma, m) => suma + m.subtotal);
    double subtotalManoObra = manoObra.fold(0.0, (suma, mo) => suma + mo.subtotal);
    double gastoTransporte = cotizacion.viatico ?? 0.0;
    double subtotalTrabajosObra = cotizacion.subtotalObraTotal;
    double subtotalCostosDirectos = subtotalTrabajosObra + subtotalMateriales + subtotalManoObra + gastoTransporte;
    double montoUtilidad = subtotalCostosDirectos * (cotizacion.porcentajeUtilidad / 100);
    double baseConUtilidad = subtotalCostosDirectos + montoUtilidad;
    double montoIva = baseConUtilidad * (cotizacion.porcentajeIva / 100);
    double totalFinal = baseConUtilidad + montoIva;

    String clp(double valor) => '${CurrencyFormatter.format(valor)} CLP';

    pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.letter,
          margin: const pw.EdgeInsets.all(28),
          footer: (pw.Context context) {
            return pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.Text(
                'Página ${context.pageNumber} de ${context.pagesCount}',
                style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey),
              ),
            );
          },
          build: (pw.Context context) {
            return [
              pw.Container(
                padding: const pw.EdgeInsets.all(15),
                decoration: const pw.BoxDecoration(
                  color: PdfColor.fromInt(0xFF2E7D32),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'COTIZACION PROFESIONAL',
                      style: pw.TextStyle(
                        color: PdfColors.white,
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    pw.Text(
                      codigoCotizacion,
                      style: pw.TextStyle(
                        color: PdfColors.white,
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 15),

              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'Datos del Cliente:',
                          style: pw.TextStyle(
                            fontSize: 11,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          'Cliente: ${cliente.nombre}',
                          style: const pw.TextStyle(fontSize: 11),
                        ),
                        pw.Text(
                          'Rut: ${cliente.rut}',
                          style: const pw.TextStyle(fontSize: 11),
                        ),
                        pw.Text(
                          'Correo: ${cliente.correo}',
                          style: const pw.TextStyle(fontSize: 11),
                        ),
                        pw.Text(
                          'Teléfono: ${cliente.telefono}',
                          style: const pw.TextStyle(fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text(
                          'Lugar de la Obra:',
                          style: pw.TextStyle(
                            fontSize: 11,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          cotizacion.direccionObra.isEmpty
                              ? 'Sin dirección'
                              : cotizacion.direccionObra,
                          style: const pw.TextStyle(fontSize: 11),
                          textAlign: pw.TextAlign.right,
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              pw.SizedBox(height: 20),

              pw.Text(
                'DETALLE DE TRABAJOS DE OBRA',
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 12,
                  color: const PdfColor.fromInt(0xFF2E7D32),
                ),
              ),
              pw.Divider(),

              if (cotizacion.listaTrabajos.isEmpty)
                pw.Text(
                  'Sin trabajos registrados',
                  style: pw.TextStyle(
                    fontSize: 10,
                    fontStyle: pw.FontStyle.italic,
                  ),
                )
              else
                ...cotizacion.listaTrabajos.map(
                  (t) => pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(vertical: 2),
                    child: pw.Row(
                      children: [
                        pw.Expanded(
                          flex: 5,
                          child: pw.Text(
                            t.tipo,
                            style: const pw.TextStyle(fontSize: 10),
                          ),
                        ),
                        pw.Expanded(
                          flex: 4,
                          child: pw.Text(
                            '${t.metrosCuadrados.toStringAsFixed(1)} m² × ${clp(t.precioPorMetro)}',
                            style: const pw.TextStyle(fontSize: 10),
                            textAlign: pw.TextAlign.center,
                          ),
                        ),
                        pw.Expanded(
                          flex: 3,
                          child: pw.Text(
                            clp(t.subtotal),
                            style: const pw.TextStyle(fontSize: 10),
                            textAlign: pw.TextAlign.end,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              pw.SizedBox(height: 10),

              pw.Align(
                alignment: pw.Alignment.centerRight,
                child: pw.Text(
                  'Subtotal Trabajos de Obra: ${clp(subtotalTrabajosObra)}',
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
              ),

              pw.SizedBox(height: 20),

              pw.Text(
                'DETALLE DE MATERIALES',
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 12,
                  color: const PdfColor.fromInt(0xFF2E7D32),
                ),
              ),
              pw.Divider(),

              if (materiales.isEmpty)
                pw.Text(
                  'Sin materiales registrados',
                  style: pw.TextStyle(
                    fontSize: 10,
                    fontStyle: pw.FontStyle.italic,
                  ),
                )
              else
                ...materiales.map(
                  (m) => pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(vertical: 2),
                    child: pw.Row(
                      children: [
                        pw.Expanded(
                          flex: 5,
                          child: pw.Text(
                            m.nombre,
                            style: const pw.TextStyle(fontSize: 10),
                          ),
                        ),
                        pw.Expanded(
                          flex: 4,
                          child: pw.Text(
                            '${m.cantidad} ${m.unidadMedida}',
                            style: const pw.TextStyle(fontSize: 10),
                            textAlign: pw.TextAlign.center,
                          ),
                        ),
                        pw.Expanded(
                          flex: 3,
                          child: pw.Text(
                            clp(m.subtotal),
                            style: const pw.TextStyle(fontSize: 10),
                            textAlign: pw.TextAlign.end,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              pw.SizedBox(height: 10),

              pw.Align(
                alignment: pw.Alignment.centerRight,
                child: pw.Text(
                  'Subtotal Materiales: ${clp(subtotalMateriales)}',
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
              ),

              pw.SizedBox(height: 20),

              pw.Text(
                'DETALLE DE MANO DE OBRA',
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 12,
                  color: const PdfColor.fromInt(0xFF2E7D32),
                ),
              ),
              pw.Divider(),

              if (manoObra.isEmpty)
                pw.Text(
                  'Sin mano de obra registrada',
                  style: pw.TextStyle(
                    fontSize: 10,
                    fontStyle: pw.FontStyle.italic,
                  ),
                )
              else
                ...manoObra.map(
                  (mo) => pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(vertical: 2),
                    child: pw.Row(
                      children: [
                        pw.Expanded(
                          flex: 5,
                          child: pw.Text(
                            mo.cargo,
                            style: const pw.TextStyle(fontSize: 10),
                          ),
                        ),
                        pw.Expanded(
                          flex: 4,
                          child: pw.Text(
                            '${mo.dias} días × ${clp(mo.valorJornada)}',
                            style: const pw.TextStyle(fontSize: 10),
                            textAlign: pw.TextAlign.center,
                          ),
                        ),
                        pw.Expanded(
                          flex: 3,
                          child: pw.Text(
                            clp(mo.subtotal),
                            style: const pw.TextStyle(fontSize: 10),
                            textAlign: pw.TextAlign.end,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              pw.SizedBox(height: 10),

              pw.Align(
                alignment: pw.Alignment.centerRight,
                child: pw.Text(
                  'Subtotal Mano de Obra: ${clp(subtotalManoObra)}',
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
              ),

              pw.SizedBox(height: 20),

              pw.Text(
                'TRANSPORTE',
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 12,
                  color: const PdfColor.fromInt(0xFF2E7D32),
                ),
              ),
              pw.Divider(),

              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Gastos de viático / traslado',
                    style: const pw.TextStyle(fontSize: 10),
                  ),
                  pw.Text(
                    clp(gastoTransporte),
                    style: const pw.TextStyle(fontSize: 10),
                  ),
                ],
              ),

              pw.SizedBox(height: 25),

              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: const pw.BoxDecoration(
                  color: PdfColor.fromInt(0xFFE8F5E9),
                ),
                child: pw.Column(
                  children: [
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text('Costos Directos:'),
                        pw.Text(clp(subtotalCostosDirectos)),
                      ],
                    ),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(
                          'Utilidad (${cotizacion.porcentajeUtilidad}%):',
                        ),
                        pw.Text(clp(montoUtilidad)),
                      ],
                    ),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text('IVA (${cotizacion.porcentajeIva}%):'),
                        pw.Text(clp(montoIva)),
                      ],
                    ),
                    pw.Divider(),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(
                          'TOTAL FINAL:',
                          style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        pw.Text(
                          clp(totalFinal),
                          style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ];
          },
        ),
    );

    final directorio = await getTemporaryDirectory();
    final nombreSeguro = codigoCotizacion.replaceAll('/', '-');
    final nombrePdf = '$nombreSeguro.pdf';
    final rutaArchivo = '${directorio.path}/$nombrePdf';
    final archivoFisico = File(rutaArchivo);
    
    await archivoFisico.writeAsBytes(await pdf.save());
    
    
    await repository.gestionarYSubirPdf(
      id: idCotizacion,
      codigo: codigoCotizacion,
      archivo: archivoFisico,
    );
  }

  @override
  State<PrevisualizacionPdfWidget> createState() =>
      _PrevisualizacionPdfWidgetState();

  
}

class _PrevisualizacionPdfWidgetState extends State<PrevisualizacionPdfWidget> {
  bool _cargado = false;
  bool _subiendo = false;
  

  late final CotizacionRepositoryImpl _repository;

  static const Color _verde = Color(0xFF2E7D32);
  static const Color _verdeSuave = Color(0xFFE8F5E9);
  static const Color _gris = Color(0xFF6B7280);
  static const Color _texto = Color(0xFF0F172A);

  double get _subtotalMateriales =>
      widget.materiales.fold(0.0, (suma, material) => suma + material.subtotal);

  double get _subtotalManoObra =>
      widget.manoObra.fold(0.0, (suma, manoObra) => suma + manoObra.subtotal);

  double get _gastoTransporte => widget.cotizacion.viatico ?? 0.0;

  double get _subtotalTrabajosObra => widget.cotizacion.subtotalObraTotal;

  double get _subtotalCostosDirectos =>
      _subtotalTrabajosObra +
      _subtotalMateriales +
      _subtotalManoObra +
      _gastoTransporte;

  double get _montoUtilidad =>
      _subtotalCostosDirectos * (widget.cotizacion.porcentajeUtilidad / 100);

  double get _baseConUtilidad => _subtotalCostosDirectos + _montoUtilidad;

  double get _montoIva =>
      _baseConUtilidad * (widget.cotizacion.porcentajeIva / 100);

  double get _totalFinal => _baseConUtilidad + _montoIva;

  String _clp(double valor) {
    return '${CurrencyFormatter.format(valor)} CLP';
  }

  @override
  void initState() {
    super.initState();
    _repository = CotizacionRepositoryImpl(
      CotizacionFirestoreDataSource(FirebaseFirestore.instance),
    );
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) {
        setState(() {
          _cargado = true;
        });
      }
    });
  }

  /*Future<void> _procesarYSubirCotizacion(String docIdInyectado) async {
    setState(() => _subiendo = true);

try {
      
      await PrevisualizacionPdfWidget.generarYsubirPdfEstatico(
        cotizacion: widget.cotizacion,
        materiales: widget.materiales,
        codigoCotizacion: widget.codigoCotizacion,
        manoObra: widget.manoObra,
        idCotizacion: widget.idCotizacion,
        repository: _repository,
      );

      setState(() => _subiendo = false);
      await widget.onListo();
    } catch (e) {
      if (!mounted) return;
      setState(() => _subiendo = false);
      AppDialogs.mostrarError(
        context,
        'Error de Almacenamiento',
        e.toString().replaceAll('Exception: ', ''),
      );
    }
  }*/

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      child: _subiendo
          ? _buildSubiendoAStorage()
          : (_cargado ? _buildPreview() : _buildCargando()),
    );
  }

  Widget _buildCargando() {
    return Container(
      key: const ValueKey('cargando'),
      padding: const EdgeInsets.symmetric(vertical: 40),
      alignment: Alignment.center,
      child: const Column(
        children: [
          CircularProgressIndicator(color: _verde),
          SizedBox(height: 16),
          Text(
            'Preparando previsualización...',
            style: TextStyle(color: _gris, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildSubiendoAStorage() {
    return Container(
      key: const ValueKey('subiendo'),
      padding: const EdgeInsets.symmetric(vertical: 40),
      alignment: Alignment.center,
      child: const Column(
        children: [
          CircularProgressIndicator(color: Colors.blue),
          SizedBox(height: 16),
          Text(
            'Subiendo PDF a Firebase Storage...',
            style: TextStyle(
              color: _texto,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreview() {
    return LayoutBuilder(
      key: const ValueKey('preview'),
      builder: (context, constraints) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.72,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFD1D5DB)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildEncabezado(),

              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildInfoCliente(),
                      _buildDivisor(),
                      _buildSeccionTrabajosObra(),
                      _buildDivisor(),
                      _buildSeccionMateriales(),
                      _buildDivisor(),
                      _buildSeccionManoObra(),
                      _buildDivisor(),
                      _buildFilaTransporte(),
                      _buildDivisor(),
                      _buildResumenTotales(),
                      _buildDivisor(),
                      _buildTotalFinal(),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),

              /*Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _verde,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  icon: const Icon(Icons.cloud_upload_outlined),
                  label: const Text(
                    'CONFIRMAR Y SUBIR COTIZACIÓN',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  onPressed: widget.habilitado ? () {
                    _procesarYSubirCotizacion(widget.idCotizacion);
                  }: null,
                ),
              ),*/
            ],
          ),
        );
      },
    );
  }

  Widget _buildSeccionTrabajosObra() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _tituloSeccion(Icons.construction_outlined, 'TRABAJOS DE OBRA'),
          const SizedBox(height: 8),

          if (widget.cotizacion.listaTrabajos.isEmpty)
            _filaVacia('Sin trabajos registrados')
          else
            ...widget.cotizacion.listaTrabajos.map(
              (trabajo) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 5,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            trabajo.tipo,
                            style: const TextStyle(fontSize: 12, color: _texto, fontWeight: FontWeight.bold),
                          ),
                          if (trabajo.descripcionBreve != null && trabajo.descripcionBreve!.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              trabajo.descripcionBreve!,
                              style: const TextStyle(
                                fontSize: 11,
                                color: _gris,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 4,
                      child: Text(
                        '${trabajo.metrosCuadrados.toStringAsFixed(1)} m² × ${_clp(trabajo.precioPorMetro)}',
                        style: const TextStyle(fontSize: 11, color: _gris),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Text(
                        _clp(trabajo.subtotal),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _texto,
                        ),
                        textAlign: TextAlign.end,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          const SizedBox(height: 6),
          _filaSubtotal(
            'Subtotal trabajos de obra',
            _clp(_subtotalTrabajosObra),
          ),
        ],
      ),
    );
  }

  Widget _buildEncabezado() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: const BoxDecoration(
        color: _verde,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(11),
          topRight: Radius.circular(11),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.picture_as_pdf_outlined,
            color: Colors.white70,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'PREVISUALIZACIÓN DE COTIZACIÓN',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
                letterSpacing: 0.5,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha((0.2 * 255).toInt()),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              widget.codigoCotizacion,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          
        ],
      ),
    );
  }

  Widget _buildInfoCliente() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: _infoItem(
              Icons.person_outline,
              'Cliente',
              widget.cotizacion.cliente.nombre.isEmpty
                  ? 'Sin cliente'
                  : widget.cotizacion.cliente.nombre,
            ),
          ),
          Expanded(
            child: _infoItem(
              Icons.location_on_outlined,
              'Dirección obra',
              widget.cotizacion.direccionObra.isEmpty
                  ? 'Sin dirección'
                  : widget.cotizacion.direccionObra,
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoItem(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 14, color: _gris),
        const SizedBox(width: 5),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 10, color: _gris)),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _texto,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSeccionMateriales() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _tituloSeccion(Icons.inventory_2_outlined, 'MATERIALES'),
          const SizedBox(height: 8),
          if (widget.materiales.isEmpty)
            _filaVacia('Sin materiales registrados')
          else
            ...widget.materiales.map(
              (material) => _filaItem(
                material.nombre,
                '${material.cantidad.toStringAsFixed(0)} ${material.unidadMedida} × ${_clp(material.costoUnitario)}',
                _clp(material.subtotal),
              ),
            ),
          const SizedBox(height: 6),
          _filaSubtotal('Subtotal materiales', _clp(_subtotalMateriales)),
        ],
      ),
    );
  }

  Widget _buildSeccionManoObra() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _tituloSeccion(Icons.engineering_outlined, 'MANO DE OBRA'),
          const SizedBox(height: 8),
          if (widget.manoObra.isEmpty)
            _filaVacia('Sin mano de obra registrada')
          else
            ...widget.manoObra.map(
              (manoObra) => _filaItem(
                manoObra.cargo,
                '${manoObra.dias.toStringAsFixed(0)} días × ${_clp(manoObra.valorJornada)}',
                _clp(manoObra.subtotal),
              ),
            ),
          const SizedBox(height: 6),
          _filaSubtotal('Subtotal mano de obra', _clp(_subtotalManoObra)),
        ],
      ),
    );
  }

  Widget _buildFilaTransporte() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _tituloSeccion(Icons.local_shipping_outlined, 'TRANSPORTE'),
          const SizedBox(height: 8),
          _filaItem(
            'Gastos de viático / traslado',
            _gastoTransporte > 0 ? 'Monto fijo' : 'No incluido',
            _clp(_gastoTransporte),
          ),
        ],
      ),
    );
  }

  Widget _buildResumenTotales() {
    final porcentajeUtilidad = widget.cotizacion.porcentajeUtilidad;
    final porcentajeIva = widget.cotizacion.porcentajeIva;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _verdeSuave,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFA5D6A7)),
      ),
      child: Column(
        children: [
          _filaResumen(
            'Subtotal costos directos',
            _clp(_subtotalCostosDirectos),
            negrita: true,
          ),
          const SizedBox(height: 6),
          _filaResumen(
            'Utilidad aplicada (${porcentajeUtilidad.toStringAsFixed(1)}%)',
            _clp(_montoUtilidad),
            icono: Icons.trending_up,
            colorIcono: _verde,
          ),
          const SizedBox(height: 6),
          _filaResumen('Base + utilidad', _clp(_baseConUtilidad)),
          const SizedBox(height: 6),
          _filaResumen(
            'IVA (${porcentajeIva.toStringAsFixed(0)}%)',
            _clp(_montoIva),
            icono: Icons.percent,
            colorIcono: Colors.orange,
          ),
        ],
      ),
    );
  }

  Widget _buildTotalFinal() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      decoration: BoxDecoration(
        color: _verde,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'TOTAL FINAL',
            style: TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.bold,
              fontSize: 12,
              letterSpacing: 0.3,
            ),
          ),
          Text(
            _clp(_totalFinal),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ],
      ),
    );
  }

  Widget _tituloSeccion(IconData icon, String titulo) {
    return Row(
      children: [
        Icon(icon, size: 14, color: _verde),
        const SizedBox(width: 5),
        Text(
          titulo,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: _verde,
            letterSpacing: 0.8,
          ),
        ),
      ],
    );
  }

  Widget _filaItem(String nombre, String detalle, String monto) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 5,
            child: Text(
              nombre,
              style: const TextStyle(fontSize: 12, color: _texto),
            ),
          ),
          Expanded(
            flex: 4,
            child: Text(
              detalle,
              style: const TextStyle(fontSize: 11, color: _gris),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              monto,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: _texto,
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  Widget _filaVacia(String mensaje) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Text(
        mensaje,
        style: const TextStyle(
          fontSize: 11,
          color: _gris,
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }

  Widget _filaSubtotal(String label, String monto) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: _verde,
          ),
        ),
        Text(
          monto,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: _verde,
          ),
        ),
      ],
    );
  }

  Widget _filaResumen(
    String label,
    String monto, {
    bool negrita = false,
    IconData? icono,
    Color? colorIcono,
  }) {
    return Row(
      children: [
        if (icono != null) ...[
          Icon(icono, size: 13, color: colorIcono ?? _verde),
          const SizedBox(width: 4),
        ],
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: negrita ? FontWeight.bold : FontWeight.normal,
              color: _texto,
            ),
          ),
        ),
        Text(
          monto,
          style: TextStyle(
            fontSize: 13,
            fontWeight: negrita ? FontWeight.bold : FontWeight.w600,
            color: _texto,
          ),
        ),
      ],
    );
  }

  Widget _buildDivisor() {
    return const Divider(height: 1, thickness: 1, color: Color(0xFFE5E7EB));
  }
}