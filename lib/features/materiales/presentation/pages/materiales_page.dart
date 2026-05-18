import 'package:flutter/material.dart';
import '../../data/repositories/material_repository_impl.dart';
import '../../domain/entities/material.dart';
import '../../domain/usecases/crear_material.dart';
import '../../domain/usecases/editar_material.dart';
import '../../domain/usecases/eliminar_material.dart';
import '../../domain/usecases/listar_material.dart';

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
    final costoTexto = costoController.text.trim();

    if (nombre.isEmpty || unidad.isEmpty || costoTexto.isEmpty) {
      mostrarMensaje('Completa todos los campos');
      return;
    }

    final costo = double.tryParse(costoTexto);

    if (costo == null || costo <= 0) {
      mostrarMensaje('Ingresa un costo válido');
      return;
    }

    final material = MaterialEntity(
      nombre: nombre,
      unidadMedida: unidad,
      costoUnitario: costo,
    );

    if (indexEditando == null) {
      await crearMaterialUseCase(material);
      mostrarMensaje('Material agregado');
    } else {
      await editarMaterialUseCase(indexEditando!, material);
      mostrarMensaje('Material actualizado');
    }

    limpiarFormulario();
    await cargarMateriales();
  }

  Future<void> eliminarMaterial(int index) async {
    await eliminarMaterialUseCase(index);
    await cargarMateriales();

    mostrarMensaje('Material eliminado');
  }

  void editarMaterial(int index) {
    final material = materiales[index];

    nombreController.text = material.nombre;
    unidadController.text = material.unidadMedida;
    costoController.text = material.costoUnitario.toString();

    setState(() {
      indexEditando = index;
    });
  }

  void limpiarFormulario() {
    nombreController.clear();
    unidadController.clear();
    costoController.clear();

    setState(() {
      indexEditando = null;
    });
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registro de materiales'),
        centerTitle: true,
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
              controller: costoController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Costo unitario',
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
                              'Costo unitario: \$${material.costoUnitario}',
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(
                                    Icons.edit,
                                    color: Colors.orange,
                                  ),
                                  onPressed: () {
                                    editarMaterial(index);
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete,
                                    color: Colors.red,
                                  ),
                                  onPressed: () {
                                    eliminarMaterial(index);
                                  },
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
