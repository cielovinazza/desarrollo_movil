import '../dtos/cliente_dtos.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ClientesRemoteDataSource {
  final FirebaseFirestore firestore;

  ClientesRemoteDataSource(this.firestore);

  static const String _collection = 'cliente';

  Future<void> agregarCliente(ClienteDto cliente) async {
    final ref = await firestore.collection(_collection).add(cliente.toMap());
    await ref.update({'id': ref.id});
  }

  Future<List<ClienteDto>> getClientes() async {
    final snapshot = await firestore.collection(_collection).get();
    return snapshot.docs.map((doc) {
      return ClienteDto.fromFirestore(doc.id, doc.data());
    }).toList();
  }

  Future<void> editarCliente(String id, ClienteDto cliente) async {
    await firestore
        .collection(_collection)
        .doc(id)
        .set(cliente.toMap(), SetOptions(merge: true));
  }
}