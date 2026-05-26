import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../dtos/cotizacion_dtos.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import '../../../../shared/widgets/strings_extensions.dart';

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
  String? clienteNombre,
  String? estado,
  DateTime? fechaInicio,
  DateTime? fechaFin,
}) async {
  Query query = firestore.collection('cotizaciones');

  // 1. SI HAY ID O CÓDIGO, HACEMOS BÚSQUEDA DIRECTA Y RETORNAMOS
 if (idBusqueda != null && idBusqueda.isNotEmpty) {
  // .trim() elimina espacios vacíos al inicio o al final
  final codigoLimpio = idBusqueda.trim().toUpperCase(); 
  
  final snapshot = await query.where('codigo', isEqualTo: codigoLimpio).get();
  return snapshot.docs.map((doc) => CotizacionDto.fromMap(doc.id, doc.data() as Map<String, dynamic>)).toList();
}

  // 2. SI NO HAY ID, RECIÉN AHÍ APLICAMOS LOS FILTROS DE LISTADO MASIVO
  if (clienteNombre != null && clienteNombre.trim().isNotEmpty) {
    final busqueda=clienteNombre.toTitleCase();
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
  Future<void> procesarEnvioCotizacion(CotizacionDto cotizacion) async {
  final docCotizacionRef = firestore.collection('cotizaciones').doc(cotizacion.id);

  final smtpServer = gmail('derick9103@gmail.com', 'inhv wdve dtuf hkns');

  // 2. ESTRUCTURA DEL CORREO (RF17)
  final message = Message()
    ..from = Address('derick9103@gmail.com', 'Nombre contratista')
    ..recipients.add(cotizacion.clienteEmail)
    ..subject = 'Cotización N°${cotizacion.codigo}' // Formato estricto RF17
    ..html = '''
      <h3>Estimado/a ${cotizacion.clienteNombre},</h3>
      <p>Junto con saludar, adjuntamos la propuesta correspondiente al proyecto ubicado en <strong>${cotizacion.direccion}</strong>.</p>
      <p>Quedamos atentos a sus comentarios o aprobación.</p>
      <br>
      <p>Saludos cordiales,</p>
    ''';

  // Adjuntar el archivo PDF mediante su URL de red de Firebase Storage (RF17)
  if (cotizacion.pdfUrl != null && cotizacion.pdfUrl!.isNotEmpty) {
    final archivoAdjunto=await _descargarArchivoTemporal(
      cotizacion.pdfUrl!, 
      'Cotizacion_${cotizacion.codigo}.pdf'
    );
    message.attachments.add(FileAttachment(archivoAdjunto));
  }

  // 3. CAMBIO DE ESTADO ASÍNCRONO E INTENTO DE ENVÍO
  try {
    // Marcamos inmediatamente en base de datos que pasó a "Enviada"
    await docCotizacionRef.update({'estado': 'Enviada'});

    // Enviar el correo de forma asíncrona
    await send(message, smtpServer);
    print('Correo enviado con éxito.');

  } catch (e) {
    // 4. IMPLEMENTAR MANEJO DE ERRORES Y REVERSIÓN (RF17)
    print('El envío falló. Iniciando reversión...');
    
    final batch = firestore.batch();

    // A. Revertir el estado a "Lista para Envío"
    batch.update(docCotizacionRef, {'estado': 'Lista para Envío'});

    // B. Registrar el intento fallido con fecha, hora y causa exacta
    final logErrorRef = firestore.collection('historial_errores_envio').doc();
    batch.set(logErrorRef, {
      'cotizacionId': cotizacion.id,
      'fechaHora': FieldValue.serverTimestamp(), // Fecha y hora del servidor
      'causa': e.toString(),
      'notificadoAlContratista': true,
    });

    await batch.commit();

    // C. Lanzar excepción para notificar a la interfaz de usuario (Contratista)
    throw Exception('Error al enviar correo: El estado volvió a "Lista para Envío". Causa: $e');
  }
}

// Función auxiliar necesaria para descargar el PDF de Storage a la memoria del fono y poder adjuntarlo
Future<File> _descargarArchivoTemporal(String url, String nombreArchivo) async {
  final response = await http.get(Uri.parse(url));
  final directory = await getTemporaryDirectory(); // Requiere path_provider
  final file = File('${directory.path}/$nombreArchivo');
  return await file.writeAsBytes(response.bodyBytes);
}

}