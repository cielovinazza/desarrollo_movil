import 'package:cloud_firestore/cloud_firestore.dart';

import '../dtos/cotizacion_dtos.dart';

class CotizacionFirestoreDataSource {

  final FirebaseFirestore firestore;

  CotizacionFirestoreDataSource(
    this.firestore,
  );

  Future<void> guardarCotizacion(
  CotizacionDto dto,
) async {

  final collection =
      firestore.collection(
    'cotizaciones',
  );

  final totalDocs =
      await collection.get();

  final numero =
      totalDocs.docs.length + 1;

  final codigo =
      'CT-${numero.toString().padLeft(3, '0')}';

  await collection.add({

    ...dto.toMap(),

    'codigo': codigo,

    'fechaCreacion':
        FieldValue.serverTimestamp(),
  });
}

Future<List<CotizacionDto>>
    obtenerCotizacion() async {

  final snapshot =
      await firestore
          .collection(
            'cotizaciones',
          )
          .get();

  return snapshot.docs.map((doc) {

    final data = doc.data();

    return CotizacionDto.fromMap(
      doc.id,
      data,
    );

  }).toList();
}

  Future<void> actualizarEstado(
  String id,
  String estado,
) async {

  await firestore
      .collection('cotizaciones')
      .doc(id)
      .update({
    'estado': estado,
  });
}
}