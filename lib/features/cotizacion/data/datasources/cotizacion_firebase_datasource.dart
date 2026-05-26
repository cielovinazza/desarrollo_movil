import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../dtos/cotizacion_dtos.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

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
  Future<void> procesarEnvioCotizacion(CotizacionDto cotizacion) async {
  final docCotizacionRef = firestore.collection('cotizaciones').doc(cotizacion.id);
  
  // 1. CONFIGURACIÓN DEL SERVIDOR SMTP (Ejemplo con Gmail)
  // ⚠️ Tip: Para Gmail debes usar una "Contraseña de aplicación" generada desde tu cuenta Google, no tu clave normal.
  final smtpServer = gmail('desarrollo.movil123@gmail.com', 'inhv wdve dtuf hkns');

  // 2. ESTRUCTURA DEL CORREO (RF17)
  final message = Message()
    ..from = Address('desarrollo.movil123@gmail.com', 'Nombre contratista')
    ..recipients.add(cotizacion.clienteEmail) // Email extraído de tu DTO
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