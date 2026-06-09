import '../../domain/entities/material.dart';
import '../../domain/repositories/material_repository.dart';

class MaterialRepositoryImpl implements MaterialRepository {
  static final List<MaterialEntity> _materiales = [];

  @override
  Future<void> crearMaterial(MaterialEntity material) async {
    _materiales.add(material);
  }

  @override
  Future<List<MaterialEntity>> listarMateriales() async {
    return _materiales;
  }

  @override
  Future<void> editarMaterial(int index, MaterialEntity material) async {
    _materiales[index] = material;
  }

  @override
  Future<void> eliminarMaterial(int index) async {
    _materiales.removeAt(index);
  }

  @override
  Future<void> agregarMultiples(List<MaterialEntity> materiales) async {
  _materiales.addAll(materiales);
}
}
