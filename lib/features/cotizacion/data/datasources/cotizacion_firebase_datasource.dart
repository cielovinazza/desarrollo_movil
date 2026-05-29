import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../dtos/cotizacion_dtos.dart';
import '../../../../shared/widgets/strings_extensions.dart';

class CotizacionFirestoreDataSource {
  final FirebaseFirestore firestore;
  final FirebaseStorage storage = FirebaseStorage.instance;

  CotizacionFirestoreDataSource(this.firestore);

  Future<String> guardarCotizacion(CotizacionDto dto) async {
  final collection = firestore.collection('cotizaciones');

  // GENERAR CÓDIGO SI VIENE VACÍO
  String codigo = dto.codigo;

  if (codigo.trim().isEmpty) {
    final snapshot = await collection
        .orderBy('fechaCreacion', descending: true)
        .limit(1)
        .get();

    int numero = 1;

    if (snapshot.docs.isNotEmpty) {
      final ultimoCodigo = snapshot.docs.first.data()['codigo'] ?? 'CT-000';

      final match = RegExp(r'CT-(\d+)').firstMatch(ultimoCodigo);

      if (match != null) {
        numero = int.parse(match.group(1)!) + 1;
      }
    }

    codigo = 'CT-${numero.toString().padLeft(3, '0')}';
  }

  // ACTUALIZAR
  if (dto.id.isNotEmpty) {
    await collection.doc(dto.id).set(
      {
        ...dto.toMap(),
        'codigo': codigo,
        'fechaCreacion':
            dto.fechaCreacion ?? FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );

    return dto.id;
  }

  // CREAR
  final nuevoDocRef = collection.doc();
  final nuevoId = nuevoDocRef.id;

  await nuevoDocRef.set({
    ...dto.toMap(),
    'id': nuevoId,
    'codigo': codigo,
    'fechaCreacion': FieldValue.serverTimestamp(),
  });

  return nuevoId;
}

  Future<List<CotizacionDto>> obtenerCotizacion({
    String? idBusqueda,
    String? clienteNombre,
    String? estado,
    DateTime? fechaInicio,
    DateTime? fechaFin,
  }) async {
    Query query = firestore.collection('cotizaciones');

    // 1. SI HAY ID O CÓDIGO, HACEMOS BÚSQUEDA DIRECTA Y RETORNAMOS
    if (idBusqueda != null && idBusqueda.isNotEmpty) {
      final codigoLimpio = idBusqueda.trim().toUpperCase(); 
      
      final snapshot = await query.where('codigo', isEqualTo: codigoLimpio).get();
      return snapshot.docs.map((doc) => CotizacionDto.fromMap(doc.id, doc.data() as Map<String, dynamic>)).toList();
    }

    // 2. SI NO HAY ID, RECIÉN AHÍ APLICAMOS LOS FILTROS DE LISTADO MASIVO
    if (clienteNombre != null && clienteNombre.trim().isNotEmpty) {
      final busqueda = clienteNombre.toTitleCase();
      query = query.where('clienteNombre', isGreaterThanOrEqualTo: busqueda)
                    .where('clienteNombre', isLessThanOrEqualTo: '$busqueda\uf8ff');
    }

    if (estado != null) {
      query = query.where('estado', isEqualTo: estado);
    }

    if (fechaInicio != null) {
      query = query.where('fechaCreacion', isGreaterThanOrEqualTo: Timestamp.fromDate(fechaInicio));
    }
    if (fechaFin != null) {
      query = query.where('fechaCreacion', isLessThanOrEqualTo: Timestamp.fromDate(fechaFin));
    }
    
    query = query.orderBy('fechaCreacion', descending: true);
    final snapshot = await query.get();
    return snapshot.docs.map((doc) => CotizacionDto.fromMap(doc.id, doc.data() as Map<String, dynamic>)).toList();
  }

  Future<void> actualizarEstado(String id, String estado) async {
    await firestore.collection('cotizaciones').doc(id).update({
      'estado': estado,
    });
  }

  Future<String> subirPdfCotizacion(String codigo, File archivoPdf) async {
    try {
      final ref = storage.ref().child('cotizaciones/$codigo/documento.pdf');
      
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

  Future<void> enviarCorreoDesdeFirebase(CotizacionDto cotizacion) async {
    await firestore.collection('historial_correos').add({
      'to': cotizacion.clienteEmail,
      'message': {
        'subject': 'Cotización N°${cotizacion.codigo}',
        'html': '''
          <h3>Estimado/a ${cotizacion.clienteNombre},</h3>
          <p>Junto con saludar, adjuntamos la propuesta correspondiente al proyecto ubicado en <strong>${cotizacion.direccion}</strong>.</p>
          <p>Saludos cordiales,</p>
        ''',
        'attachments': [
          {
            'filename': 'Cotizacion_${cotizacion.codigo}.pdf',
            'path': cotizacion.pdfUrl, // La extensión lee la URL y la adjunta
          }
        ],
      },
    });
  }
}