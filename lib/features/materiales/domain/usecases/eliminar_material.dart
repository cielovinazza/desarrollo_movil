import '../repositories/material_repository.dart';

class EliminarMaterial {
  final MaterialRepository repository;

  EliminarMaterial(this.repository);

  Future<void> call(int index) async {
    await repository.eliminarMaterial(index);
  }
}
