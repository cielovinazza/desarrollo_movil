import '../entities/material.dart';

abstract class MaterialRepository {
  Future<void> crearMaterial(MaterialEntity material);

  Future<List<MaterialEntity>> listarMateriales();

  Future<void> editarMaterial(int index, MaterialEntity material);

  Future<void> eliminarMaterial(int index);
}
