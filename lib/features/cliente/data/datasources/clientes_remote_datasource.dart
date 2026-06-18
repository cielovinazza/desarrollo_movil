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

    final querySnapshot = await firestore.collection(_collection)
                                          .where('rut', isEqualTo:  cliente.rut)
                                          .limit(1).get();
    if (querySnapshot.docs.isNotEmpty){
      throw Exception('El rut ${cliente.rut} ya se encuentra registrado en el sistema.');
    }
    await docRef.set(cliente.toMap());
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
  Future<void> eliminarCliente(String id) async {
    await firestore.collection(_collection).doc(id).delete();
  }
}
