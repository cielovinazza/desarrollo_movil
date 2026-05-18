import '../entities/material.dart';
import '../repositories/material_repository.dart';

class CrearMaterial {
  final MaterialRepository repository;

  CrearMaterial(this.repository);

  Future<void> call(MaterialEntity material) async {
    await repository.crearMaterial(material);
  }
}
