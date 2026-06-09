import '../entities/material.dart';
import '../repositories/material_repository.dart';

class EditarMaterial {
  final MaterialRepository repository;

  EditarMaterial(this.repository);

  Future<void> call(int index, MaterialEntity material) async {
    await repository.editarMaterial(index, material);
  }
}
