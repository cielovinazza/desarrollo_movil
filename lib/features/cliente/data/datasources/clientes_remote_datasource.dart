import '../dtos/cliente_dtos.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ClientesRemoteDataSource {
  final FirebaseFirestore firestore;

  ClientesRemoteDataSource(this.firestore);

  static const String _collection = 'cliente';

  Future<void> agregarCliente(ClienteDto cliente) async {
    final docRef =firestore.collection(_collection).doc(cliente.rut);
    final docSnapshot = await docRef.get();
    
    if (docSnapshot.exists){
      throw Exception('El Rut ${cliente.rut} ya se encuentra registrado en el sistema.');
    }
    await docRef.set(cliente.toMap());
}

  Future<List<ClienteDto>> getClientes({bool forzarServidor = false}) async {
  final query = firestore.collection(_collection);

  if (!forzarServidor) {
    try {
      final cacheSnapshot = await query.get(
        const GetOptions(source: Source.cache),
      );
      if (cacheSnapshot.docs.isNotEmpty) {
        print('CLIENTES DESDE CACHÉ (${cacheSnapshot.docs.length} docs)');
        return cacheSnapshot.docs
            .map((doc) => ClienteDto.fromFirestore(doc.id, doc.data()))
            .toList();
      }
    } catch (_) {}
  }
  print('CLIENTES DESDE SERVIDOR');
  try {
    return await _obtenerDesdeServidor(query);
  } catch (_) {
    return await _obtenerDesdeServidor(query, source: Source.cache);
  }
}

  Future<List<ClienteDto>> _obtenerDesdeServidor(
  Query<Map<String, dynamic>> query, {
  Source source = Source.server,
}) async {
  final snapshot = await query.get(GetOptions(source: source));
  return snapshot.docs
      .map((doc) => ClienteDto.fromFirestore(doc.id, doc.data()))
      .toList();
}

  Future<void> editarCliente(String id, ClienteDto cliente) async {
    await firestore
        .collection(_collection)
        .doc(id)
        .set(cliente.toMap(), SetOptions(merge: true));
  }
  Future<void> eliminarCliente(String id) async {
    await firestore.collection(_collection).doc(id).delete();
  }
}
