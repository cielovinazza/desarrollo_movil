import '../entities/material.dart';
import '../repositories/material_repository.dart';

class ListarMateriales {
  final MaterialRepository repository;

  ListarMateriales(this.repository);

  Future<List<MaterialEntity>> call() async {
    return await repository.listarMateriales();
  }
}
