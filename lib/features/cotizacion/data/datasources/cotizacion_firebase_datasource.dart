import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../dtos/cotizacion_dtos.dart';

class CotizacionFirestoreDataSource {
  final FirebaseFirestore firestore;
  final FirebaseStorage storage = FirebaseStorage.instance;

  CotizacionFirestoreDataSource(this.firestore);

  Future<void> guardarCotizacion(CotizacionDto dto) async {
    final collection = firestore.collection('cotizaciones');
    final totalDocs = await collection.get();
    final numero = totalDocs.docs.length + 1;
    final codigo = 'CT-${numero.toString().padLeft(3, '0')}';

    await collection.add({
      ...dto.toMap(),
      'codigo': codigo,
      'fechaCreacion': FieldValue.serverTimestamp(),
    });
  }

  Future<List<CotizacionDto>> obtenerCotizacion({
    String? idBusqueda,
    String? nombreCliente,
    String? estado,
    DateTime? fechaInicio,
    DateTime? fechaFin,
  }) async {
    // 1. Inicializamos la Query apuntando a la colección siempre
    Query query = firestore.collection('cotizaciones');

    // 2. NUEVO CAMBIO: Si viene idBusqueda, filtramos por el campo manual 'codigo'
    if (idBusqueda != null && idBusqueda.trim().isNotEmpty) {
      query = query.where('codigo', isEqualTo: idBusqueda.trim());
    }

    // 3. Filtro por nombre del cliente (Búsqueda por prefijo)
    if (nombreCliente != null && nombreCliente.trim().isNotEmpty) {
      final str = nombreCliente.trim();
      query = query
          .where('clienteNombre', isGreaterThanOrEqualTo: str)
          .where('clienteNombre', isLessThanOrEqualTo: '$str\uf8ff');
    }

    // 4. Filtro por Estado
    if (estado != null && estado.isNotEmpty) {
      query = query.where('estado', isEqualTo: estado);
    }

    // 5. Filtros de Fechas
    if (fechaInicio != null) {
      query = query.where('fechaCreacion', isGreaterThanOrEqualTo: Timestamp.fromDate(fechaInicio));
    }
    
    if (fechaFin != null) {
      final finDelDia = DateTime(fechaFin.year, fechaFin.month, fechaFin.day, 23, 59, 59);
      query = query.where('fechaCreacion', isLessThanOrEqualTo: Timestamp.fromDate(finDelDia));
    }

    // 6. Ordenamos los resultados por fecha de creación descendente
    query = query.orderBy('fechaCreacion', descending: true);

    // 7. Lanzamos la petición combinada a Firestore
    final snapshot = await query.get();

    return snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>; 
      return CotizacionDto.fromMap(doc.id, data);
    }).toList();
  }

  Future<void> actualizarEstado(String id, String estado) async {
    await firestore.collection('cotizaciones').doc(id).update({
      'estado': estado,
    });
  }

  Future<String> subirPdfCotizacion(String id, File archivoPdf) async {
    try {
      final ref = storage.ref().child('cotizaciones/$id/documento.pdf');
      
      final uploadTask = ref.putFile(
        archivoPdf,
        SettableMetadata(contentType: 'application/pdf'),
      );

      final TaskSnapshot snapshot = await uploadTask.timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          uploadTask.cancel();
          throw Exception('Timeout: La subida superó los 5 segundos.');
        },
      );

      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> vincularPdfACotizacion(String id, String url) async {
    await firestore.collection('cotizaciones').doc(id).update({
      'pdfUrl': url,
    });
  }

  Future<void> crearNuevaVersion(String cotizacionId) async {
  final docRef = firestore.collection('cotizaciones').doc(cotizacionId);

  await firestore.runTransaction((transaction) async {
    final snapshot = await transaction.get(docRef);
    if (!snapshot.exists) return;

    final data = snapshot.data()!;
    final versionActual = (data['version'] as int?) ?? 1;

    final versionRef = docRef
        .collection('versiones')
        .doc('v$versionActual');

    transaction.set(versionRef, {
      ...data,
      'versionGuardada': versionActual,
      'guardadoEn': FieldValue.serverTimestamp(),
    });

    transaction.update(docRef, {'version': versionActual + 1});
  });
}
}