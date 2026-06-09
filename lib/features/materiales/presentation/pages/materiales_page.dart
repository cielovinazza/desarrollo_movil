import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../data/repositories/material_repository_impl.dart';
import '../../domain/entities/material.dart';
import '../../domain/usecases/crear_material.dart';
import '../../domain/usecases/editar_material.dart';
import '../../domain/usecases/eliminar_material.dart';
import '../../domain/usecases/listar_material.dart';
import '../../utils/csv_parser.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../shared/widgets/app_dialogs.dart';

class MaterialesPage extends StatefulWidget {
  const MaterialesPage({super.key});

  @override
  State<MaterialesPage> createState() => _MaterialesPageState();
}

class _MaterialesPageState extends State<MaterialesPage> {
  late final CrearMaterial crearMaterialUseCase;
  late final EditarMaterial editarMaterialUseCase;
  late final EliminarMaterial eliminarMaterialUseCase;
  late final ListarMateriales listarMaterialesUseCase;

  final nombreController = TextEditingController();
  final unidadController = TextEditingController();
  final cantidadController = TextEditingController();
  final costoController = TextEditingController();

  List<MaterialEntity> materiales = [];

  int? indexEditando;

  @override
  void initState() {
    super.initState();

    final repository = MaterialRepositoryImpl();

    crearMaterialUseCase = CrearMaterial(repository);
    editarMaterialUseCase = EditarMaterial(repository);
    eliminarMaterialUseCase = EliminarMaterial(repository);
    listarMaterialesUseCase = ListarMateriales(repository);

    cargarMateriales();
  }

  @override
  void dispose() {
    nombreController.dispose();
    unidadController.dispose();
    cantidadController.dispose();
    costoController.dispose();
    super.dispose();
  }

  Future<void> cargarMateriales() async {
    final resultado = await listarMaterialesUseCase();
    setState(() {
      materiales = resultado;
    });
  }

  Future<void> guardarMaterial() async {
    final nombre = nombreController.text.trim();
    final unidad = unidadController.text.trim();
    final cantidadTexto = cantidadController.text.trim();
    final costoTexto = costoController.text.trim();

    if (nombre.isEmpty ||
        unidad.isEmpty ||
        cantidadTexto.isEmpty ||
        costoTexto.isEmpty) {
      AppDialogs.mostrarSnackBar(context, 'Completa todos los campos');
      return;
    }

    final cantidad = double.tryParse(cantidadTexto);
    final costo = double.tryParse(costoTexto);

    if (cantidad == null || cantidad <= 0) {
      AppDialogs.mostrarSnackBar(context, 'Ingresa una cantidad válida');
      return;
    }

    if (costo == null || costo <= 0) {
      AppDialogs.mostrarSnackBar(context, 'Ingresa un costo válido');
      return;
    }

    final material = MaterialEntity(
      nombre: nombre,
      unidadMedida: unidad,
      cantidad: cantidad,
      costoUnitario: costo,
    );

    if (indexEditando == null) {
      await crearMaterialUseCase(material);
      if(!mounted) return;
      AppDialogs.mostrarSnackBar(context, 'Material agregado');
    } else {
      await editarMaterialUseCase(indexEditando!, material);
      if(!mounted) return;
      AppDialogs.mostrarSnackBar(context, 'Material actualizado');
    }

    limpiarFormulario();
    await cargarMateriales();
  }

  Future<void> eliminarMaterial(int index) async {
    await eliminarMaterialUseCase(index);
    await cargarMateriales();
    if(!mounted) return;
    AppDialogs.mostrarSnackBar(context, 'Material eliminado');
  }

  void editarMaterial(int index) {
    final material = materiales[index];
    nombreController.text = material.nombre;
    unidadController.text = material.unidadMedida;
    cantidadController.text = material.cantidad.toString();
    costoController.text = material.costoUnitario.toString();
    setState(() => indexEditando = index);
  }

  void limpiarFormulario() {
    nombreController.clear();
    unidadController.clear();
    cantidadController.clear();
    costoController.clear();
    setState(() => indexEditando = null);
  }

  void mostrarMensaje(String mensaje) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(mensaje)));
  }

  void filtrarCosto(String value) {
    final textoFiltrado = value.replaceAll(RegExp(r'[^0-9.]'), '');
    if (textoFiltrado != value) {
      costoController.value = TextEditingValue(
        text: textoFiltrado,
        selection: TextSelection.collapsed(offset: textoFiltrado.length),
      );
    }
  }

  Future<void> _seleccionarArchivo() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
      withData: true,
    );

    if (result == null || result.files.isEmpty) return;

    final archivo = result.files.first;
    if (archivo.bytes == null) return;

    await _procesarCSV(utf8.decode(archivo.bytes!));
  }

  Future<void> _procesarCSV(String contenido) async {
  final resultado = parsearCSV(contenido);

  for (final material in resultado.materialesValidos) {
    await crearMaterialUseCase(material);
  }

  await cargarMateriales();
  if (!mounted) return;

  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text(
        'Resultado de importación',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Importados: ${resultado.materialesValidos.length}'),
            Text('Rechazados: ${resultado.filasRechazadas.length}'),
            if (resultado.filasRechazadas.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 4),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: resultado.filasRechazadas.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (_, i) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Text(resultado.filasRechazadas[i]),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Cerrar'),
        ),
      ],
    ),
  );
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registro de materiales'),
        centerTitle: true,
        actions: [
          TextButton.icon(
            onPressed: _seleccionarArchivo,
            icon: const Icon(Icons.upload_file),
            label: const Text('Importar CSV'),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: nombreController,
              decoration: const InputDecoration(
                labelText: 'Nombre del material',
                hintText: 'Ej: Cemento, Arena, Tubo PVC',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 16),

            TextField(
              controller: unidadController,
              decoration: const InputDecoration(
                labelText: 'Unidad de medida',
                hintText: 'Ej: kg, m², m³, unidad, saco, litro',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 16),

            TextField(
              controller: cantidadController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Cantidad',
                hintText: 'Ej: 10',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 16),

            TextField(
              controller: costoController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Costo unitario (CLP)',
                hintText: 'Ej: 5500',
                border: OutlineInputBorder(),
              ),
              onChanged: filtrarCosto,
            ),

            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: guardarMaterial,
                child: Text(
                  indexEditando == null
                      ? 'Agregar material'
                      : 'Actualizar material',
                ),
              ),
            ),

            if (indexEditando != null) ...[
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: limpiarFormulario,
                  child: const Text('Cancelar edición'),
                ),
              ),
            ],

            const SizedBox(height: 24),

            Expanded(
              child: materiales.isEmpty
                  ? const Center(child: Text('No hay materiales registrados'))
                  : ListView.builder(
                      itemCount: materiales.length,
                      itemBuilder: (context, index) {
                        final material = materiales[index];

                        return Card(
                          child: ListTile(
                            title: Text(material.nombre),
                            subtitle: Text(
                              'Unidad: ${material.unidadMedida}\n'
                              '${material.cantidad.toStringAsFixed(0)} × ${CurrencyFormatter.format(material.costoUnitario)} = ${CurrencyFormatter.format(material.subtotal)}',
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(
                                    Icons.edit,
                                    color: Colors.orange,
                                  ),
                                  onPressed: () => editarMaterial(index),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete,
                                    color: Colors.red,
                                  ),
                                  onPressed: () => eliminarMaterial(index),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
