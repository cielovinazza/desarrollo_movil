import 'package:flutter/material.dart';
import '../../domain/entities/cotizacion_model.dart';

class CrearCotizacionPage extends StatefulWidget {
  const CrearCotizacionPage({super.key});

  @override
  State<CrearCotizacionPage> createState() => _CrearCotizacionPageState();
}

class _CrearCotizacionPageState extends State<CrearCotizacionPage> {
  final _formKey = GlobalKey<FormState>();
  int _currentStep = 0;

  // Color verde institucional de la app
  final Color _verdeApp = const Color(0xFF2E7D32);

  // --- Controllers ---
  final _direccionController = TextEditingController();
  final _viaticoController = TextEditingController(); 
  final _utilidadController = TextEditingController(text: '0');
  final _ivaController = TextEditingController(text: '19');

  final List<ItemTrabajo> _trabajosAgregados = [];
  final List<String> _tiposDisponibles = ['Pintura', 'Yeso', 'Estuco', 'Pasta Muro'];

  @override
  void dispose() {
    _direccionController.dispose();
    _viaticoController.dispose();
    _utilidadController.dispose();
    _ivaController.dispose();
    super.dispose();
  }

  // Captura el estado y calcula en vivo
  // Nota: Mantiene los mocks exigidos de materiales y mano de obra del Sprint 2
  CotizacionModel _obtenerEstadoActual() {
    final viaticoTexto = _viaticoController.text.trim();
    final double? viaticoValor = viaticoTexto.isEmpty ? null : double.tryParse(viaticoTexto);

    return CotizacionModel(
      direccionObra: _direccionController.text.trim(),
      listaTrabajos: _trabajosAgregados,
      viatico: viaticoValor,
      porcentajeUtilidad: double.tryParse(_utilidadController.text) ?? 0.0,
      porcentajeIva: double.tryParse(_ivaController.text) ?? 19.0,
    );
  }

  // Modal rediseñado con bordes redondeados y inputs limpios
  void _mostrarDialogoAgregarTrabajo() {
    String tipoSeleccionado = _tiposDisponibles.first;
    final m2ItemController = TextEditingController();
    final precioItemController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(Icons.add_task, color: _verdeApp),
              const SizedBox(width: 10),
              const Text('Añadir Trabajo', style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: tipoSeleccionado,
                  decoration: const InputDecoration(
                    labelText: 'Tipo de Rubro',
                    border: OutlineInputBorder(),
                  ),
                  items: _tiposDisponibles.map((tipo) => DropdownMenuItem(
                    value: tipo,
                    child: Text(tipo),
                  )).toList(),
                  onChanged: (value) {
                    setModalState(() => tipoSeleccionado = value!);
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: m2ItemController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Cantidad Metros Cuadrados (m²)', 
                    prefixIcon: Icon(Icons.square_foot),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: precioItemController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Precio por m² (CLP)', 
                    prefixIcon: Icon(Icons.sell_outlined),
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () {
                final m2 = double.tryParse(m2ItemController.text) ?? 0.0;
                final precio = double.tryParse(precioItemController.text) ?? 0.0;

                if (m2 > 0 && precio > 0) {
                  setState(() {
                    _trabajosAgregados.add(
                      ItemTrabajo(tipo: tipoSeleccionado, metrosCuadrados: m2, precioPorMetro: precio),
                    );
                  });
                  Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _verdeApp,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Guardar Ítem'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final datosEnVivo = _obtenerEstadoActual();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nueva Cotización', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: _verdeApp,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        onChanged: () => setState(() {}),
        child: Theme(
          // Estiliza los controles del Stepper para usar el color verde corporativo
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(primary: _verdeApp),
          ),
          child: Stepper(
            type: StepperType.vertical,
            currentStep: _currentStep,
            onStepContinue: () {
              if (_currentStep < 4) {
                setState(() => _currentStep += 1);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: _verdeApp,
                    content: Text('Cotización guardada. Total: \$${datosEnVivo.calcularTotalFinal()} CLP'),
                  ),
                );
                Navigator.pop(context);
              }
            },
            onStepCancel: () {
              if (_currentStep > 0) {
                setState(() => _currentStep -= 1);
              } else {
                Navigator.pop(context);
              }
            },
            steps: [
              // Paso 1: Cliente
              Step(
                title: const Text('Identificación del Cliente', style: TextStyle(fontWeight: FontWeight.w600)),
                isActive: _currentStep >= 0,
                content: const Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 8.0),
                    child: Text('Buscador de clientes por RUT (Sprint 1).', style: TextStyle(color: Colors.grey)),
                  ),
                ),
              ),

              // Paso 2: DATOS DE OBRA REDISEÑADOS Y SÚPER ORDENADOS
              Step(
                title: const Text('Detalle de Trabajos de la Obra', style: TextStyle(fontWeight: FontWeight.w600)),
                isActive: _currentStep >= 1,
                content: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    TextFormField(
                      controller: _direccionController,
                      decoration: const InputDecoration(
                        labelText: 'Dirección general del proyecto', 
                        prefixIcon: Icon(Icons.location_on_outlined),
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Fila de encabezado limpia
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Ítems de Construcción', 
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)
                        ),
                        OutlinedButton.icon(
                          onPressed: _mostrarDialogoAgregarTrabajo,
                          icon: const Icon(Icons.add, size: 16),
                          label: const Text('Añadir Ítem', style: TextStyle(fontWeight: FontWeight.bold)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: _verdeApp,
                            side: BorderSide(color: _verdeApp, width: 1.5),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 20, thickness: 1),

                    if (_trabajosAgregados.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          child: Column(
                            children: const [
                              Icon(Icons.assignment_late_outlined, color: Colors.grey, size: 36),
                              SizedBox(height: 8),
                              Text(
                                'No has añadido ningún trabajo todavía.', 
                                style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic, fontSize: 13)
                              ),
                            ],
                          ),
                        ),
                      ),

                    // Tarjetas (Cards) de items súper estilizadas y ordenadas
                    ..._trabajosAgregados.asMap().entries.map((entry) {
                      int index = entry.key;
                      ItemTrabajo item = entry.value;
                      return Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.grey.shade200),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.02),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            )
                          ]
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: _verdeApp.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.build_circle_outlined, color: _verdeApp, size: 22),
                          ),
                          title: Text(
                            item.tipo, 
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Text(
                              '${item.metrosCuadrados} m²  ×  \$${item.precioPorMetro.toStringAsFixed(0)} / m²',
                              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                            ),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '\$${item.subtotal.toStringAsFixed(0)}', 
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87)
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 22),
                                onPressed: () => setState(() => _trabajosAgregados.removeAt(index)),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                    
                    if (_trabajosAgregados.isNotEmpty) const SizedBox(height: 16),
                    
                    // Cuadro de Subtotal elegante alineado al diseño
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: _verdeApp.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: _verdeApp.withOpacity(0.2)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Subtotal Obra:', 
                            style: TextStyle(fontWeight: FontWeight.bold, color: _verdeApp, fontSize: 14)
                          ),
                          Text(
                            '\$${datosEnVivo.subtotalObraTotal.toStringAsFixed(0)} CLP', 
                            style: TextStyle(fontWeight: FontWeight.bold, color: _verdeApp, fontSize: 16)
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),

              // Paso 3: Mano de Obra
              Step(
                title: const Text('Cargas de Mano de Obra', style: TextStyle(fontWeight: FontWeight.w600)),
                isActive: _currentStep >= 2,
                content: Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Text('Costo acumulado MO (Simulado): \$${datosEnVivo.costoManoObraSimulado.toStringAsFixed(0)} CLP', style: const TextStyle(color: Colors.grey)),
                  ),
                ),
              ),

              // Paso 4: Materiales
              Step(
                title: const Text('Catálogo de Materiales', style: TextStyle(fontWeight: FontWeight.w600)),
                isActive: _currentStep >= 3,
                content: Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Text('Costo calculado materiales (Simulado): \$${datosEnVivo.costoMaterialesSimulado.toStringAsFixed(0)} CLP', style: const TextStyle(color: Colors.grey)),
                  ),
                ),
              ),

              // Paso 5: Totales finales y Costos Adicionales (Viático)
              Step(
                title: const Text('Configuración de Totales', style: TextStyle(fontWeight: FontWeight.w600)),
                isActive: _currentStep >= 4,
                content: Column(
                  children: [
                    const SizedBox(height: 4),
                    TextFormField(
                      controller: _viaticoController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Viático adicional (Opcional - CLP)', 
                        prefixIcon: Icon(Icons.payments_outlined),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _utilidadController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: '% Porcentaje de Utilidad', 
                        prefixIcon: Icon(Icons.trending_up),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _ivaController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: '% IVA Legal', 
                        prefixIcon: Icon(Icons.percent),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Tarjeta de total general institucional del proyecto
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _verdeApp, 
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: _verdeApp.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          )
                        ]
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'TOTAL GENERAL NETO + IMPUESTOS', 
                            style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5)
                          ),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Monto Final:', 
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)
                              ),
                              Text(
                                '\$${datosEnVivo.calcularTotalFinal()} CLP',
                                style: const TextStyle(
                                  color: Colors.white, 
                                  fontSize: 24, 
                                  fontWeight: FontWeight.bold
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}