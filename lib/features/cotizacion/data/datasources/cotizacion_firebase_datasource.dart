import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../dtos/cotizacion_dtos.dart';
import '../../../../core/utils/strings_extensions.dart';

class CotizacionFirestoreDataSource {
  final FirebaseFirestore firestore;
  final FirebaseStorage storage = FirebaseStorage.instance;

  CotizacionFirestoreDataSource(this.firestore);

  Future<String> guardarCotizacion(CotizacionDto dto) async {
    final collection = firestore.collection('cotizaciones');

    // GENERAR CÓDIGO SI VIENE VACÍO
    String codigo = dto.codigo;

    if (codigo.trim().isEmpty) {
      final contadorRef = firestore.collection('contadores').doc('cotizaciones');
      codigo = await firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(contadorRef);
        int siguienteNumero = 1;
        if (snapshot.exists) {
          final datos = snapshot.data();
          final ultimoNumero = datos?['ultimoNumero'] as int? ?? 0;
          siguienteNumero = ultimoNumero + 1;
        }
        transaction.set(
          contadorRef,
          {'ultimoNumero': siguienteNumero},
          SetOptions(merge: true),
        );
        return 'CT-${siguienteNumero.toString().padLeft(3, '0')}';
      });
    }
    // ACTUALIZAR
    if (dto.id.isNotEmpty) {
      await collection.doc(dto.id).set({
        ...dto.toMap(),
        'codigo': codigo,
        'fechaCreacion': dto.fechaCreacion ?? FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

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

    // 1. SI HAY CÓDIGO, HACEMOS BÚSQUEDA DIRECTA Y RETORNAMOS
    final codigoBusqueda = idBusqueda?.trim().toUpperCase();

    // 2. SI NO HAY ID, RECIÉN AHÍ APLICAMOS LOS FILTROS DE LISTADO MASIVO
    if (clienteNombre != null && clienteNombre.trim().isNotEmpty) {
      final busqueda = clienteNombre.toTitleCase();
      query = query
          .where('clienteNombre', isGreaterThanOrEqualTo: busqueda)
          .where('clienteNombre', isLessThanOrEqualTo: '$busqueda\uf8ff');
    }

    if (estado != null) {
      query = query.where('estado', isEqualTo: estado);
    }

    if (fechaInicio != null) {
      query = query.where(
        'fechaCreacion',
        isGreaterThanOrEqualTo: Timestamp.fromDate(fechaInicio),
      );
    }
    if (fechaFin != null) {
      final fechaSiguiente = DateTime(
        fechaFin.year,
        fechaFin.month,
        fechaFin.day + 1,
      );

      query = query.where(
        'fechaCreacion',
        isLessThan: Timestamp.fromDate(fechaSiguiente),
      );
    }

    query = query.orderBy('fechaCreacion', descending: true);
    QuerySnapshot snapshot;
    try {
      snapshot = await query.get(const GetOptions(source: Source.server));
    } catch (_) {
      snapshot = await query.get(const GetOptions(source: Source.cache));
    }
    var resultados = snapshot.docs
        .map(
          (doc) =>
              CotizacionDto.fromMap(doc.id, doc.data() as Map<String, dynamic>),
        )
        .toList();

    if (codigoBusqueda != null && codigoBusqueda.trim().isNotEmpty) {
      resultados = resultados.where((cotizacion) {
        return cotizacion.codigo.toUpperCase().contains(codigoBusqueda);
      }).toList();
    }

    return resultados;
  }

  Future<void> actualizarEstado(
    String id,
    String estado, {
    String? observacion,
  }) async {
    await firestore.collection('cotizaciones').doc(id).update({
      'estado': estado,
      'observacionEstado': observacion?.trim() ?? '',
      'fechaCambioEstado': FieldValue.serverTimestamp(),
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
    await firestore.collection('cotizaciones').doc(id).update({'pdfUrl': url});
  }

  Future<void> crearNuevaVersion(String cotizacionId) async {
    final docRef = firestore.collection('cotizaciones').doc(cotizacionId);

    await firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);
      if (!snapshot.exists) return;

      final data = snapshot.data()!;
      final versionActual = (data['version'] as int?) ?? 1;

      final versionRef = docRef.collection('versiones').doc('v$versionActual');

      transaction.set(versionRef, {
        ...data,
        'versionGuardada': versionActual,
        'guardadoEn': FieldValue.serverTimestamp(),
      });

      transaction.update(docRef, {'version': versionActual + 1});
    });
  }

Future<String> enviarCorreoTriggerEmail({
  required String clienteEmail,
  required String clienteNombre,
  required String direccion,
  required String asunto,
  required String pdfUrl,
  required String codigo,
}) async {
  try {
    final cuerpoHtml = '''
      <h3>Estimado/a $clienteNombre,</h3>
      <p>Junto con saludar, adjuntamos un documento con la propuesta correspondiente a la cotizacion para el proyecto ubicado en <strong>$direccion</strong>.</p>
      <p>Saludos cordiales.</p>
    ''';
    final docRef =await FirebaseFirestore.instance.collection('historial_correos').add({
      'to': clienteEmail.trim(),
      'message': {
        'subject': asunto,
        'html': cuerpoHtml,
        'attachments': [
          {
            'filename': 'Cotizacion_$codigo.pdf',
            'path': pdfUrl, 
          }
        ],
      },
    });
    print('Correo enviado con éxito.');
    return docRef.id;

    
  } catch (e) {
    print('Error al registrar el correo en Firestore: $e');
    throw Exception('No se pudo programar el envío del correo de la cotización.');
  }
}
}