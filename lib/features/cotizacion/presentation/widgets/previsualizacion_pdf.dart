import 'package:flutter/material.dart';
import '../../domain/entities/cotizacion_model.dart';
import '../../domain/entities/mano_de_obra.dart';
import 'package:project/features/materiales/domain/entities/material.dart';

class PrevisualizacionPdfWidget extends StatefulWidget {
  final CotizacionModel cotizacion;
  final List<MaterialEntity> materiales;
  final List<ManoDeObra> manoObra;
  final VoidCallback onListo;

  const PrevisualizacionPdfWidget({
    super.key,
    required this.cotizacion,
    required this.materiales,
    required this.manoObra,
    required this.onListo,
  });

  @override
  State<PrevisualizacionPdfWidget> createState() =>
      _PrevisualizacionPdfWidgetState();
}

class _PrevisualizacionPdfWidgetState extends State<PrevisualizacionPdfWidget> {
  bool _cargado = false;

  static const Color _verde = Color(0xFF2E7D32);
  static const Color _verdeSuave = Color(0xFFE8F5E9);
  static const Color _gris = Color(0xFF6B7280);
  static const Color _texto = Color(0xFF0F172A);

  double get _subtotalMateriales =>
      widget.materiales.fold(0.0, (suma, material) => suma + material.subtotal);

  double get _subtotalManoObra =>
      widget.manoObra.fold(0.0, (suma, manoObra) => suma + manoObra.subtotal);

  double get _gastoTransporte => widget.cotizacion.viatico ?? 0.0;

  double get _subtotalCostosDirectos =>
      _subtotalMateriales + _subtotalManoObra + _gastoTransporte;

  double get _montoUtilidad =>
      _subtotalCostosDirectos * (widget.cotizacion.porcentajeUtilidad / 100);

  double get _baseConUtilidad => _subtotalCostosDirectos + _montoUtilidad;

  double get _montoIva =>
      _baseConUtilidad * (widget.cotizacion.porcentajeIva / 100);

  double get _totalFinal => _baseConUtilidad + _montoIva;

  String _clp(double valor) {
    return '\$${valor.round().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (match) => '${match[1]}.')} CLP';
  }

  @override
  void initState() {
    super.initState();

    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) {
        setState(() {
          _cargado = true;
        });
        widget.onListo();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      child: _cargado ? _buildPreview() : _buildCargando(),
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

  Widget _buildPreview() {
    return Container(
      key: const ValueKey('preview'),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFD1D5DB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildEncabezado(),
          _buildInfoCliente(),
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
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildEncabezado() {
    final fecha = DateTime.now();

    final codigo =
        'COT-${fecha.year}${fecha.month.toString().padLeft(2, '0')}${fecha.day.toString().padLeft(2, '0')}';

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
          const Text(
            'PREVISUALIZACIÓN DE COTIZACIÓN',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 13,
              letterSpacing: 0.5,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              codigo,
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
              widget.cotizacion.cliente.isEmpty
                  ? 'Sin cliente'
                  : widget.cotizacion.cliente,
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
                '${material.cantidad.toStringAsFixed(1)} ${material.unidadMedida} × ${_clp(material.costoUnitario)}',
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
