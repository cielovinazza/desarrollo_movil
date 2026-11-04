import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class VerPdfPage extends StatefulWidget {
  final String? url;
  final String codigoCotizacion;

  const VerPdfPage({
    super.key,
    required this.url,
    required this.codigoCotizacion,
  });

  @override
  State<VerPdfPage> createState() => _VerPdfPageState();
}

class _VerPdfPageState extends State<VerPdfPage> {
  Uint8List? _bytesPdf;
  bool _cargando = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargarPdf();
  }

  Future<void> _cargarPdf() async {
    try {
      if (widget.url == null || widget.url!.isEmpty) {
        throw Exception('No existe una URL para este documento.');
      }

      final referencia =
          FirebaseStorage.instance.refFromURL(widget.url!);

      final bytes = await referencia.getData(50 * 1024 * 1024);

      if (bytes == null || bytes.isEmpty) {
        throw Exception('El PDF está vacío.');
      }

      if (!mounted) return;

      setState(() {
        _bytesPdf = bytes;
        _cargando = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString();
        _cargando = false;
      });

      debugPrint('ERROR DESCARGANDO PDF: $e');
    }
  }

  Future<void> _compartir() async {
    if (_bytesPdf == null) return;

    await SharePlus.instance.share(
      ShareParams(
        title: 'Cotización: ${widget.codigoCotizacion}',
        files: [
          XFile.fromData(
            _bytesPdf!,
            name: 'Cotizacion_${widget.codigoCotizacion}.pdf',
            mimeType: 'application/pdf',
          ),
        ],
      ),
    );
  }

  Future<void> _abrirEnNavegador() async {
    if (widget.url == null || widget.url!.isEmpty) return;

    final uri = Uri.parse(widget.url!);

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('PDF: ${widget.codigoCotizacion}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            tooltip: 'Compartir PDF',
            onPressed: _bytesPdf != null ? _compartir : null,
          ),
          IconButton(
            icon: const Icon(Icons.open_in_browser),
            tooltip: 'Abrir en navegador',
            onPressed: _abrirEnNavegador,
          ),
        ],
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: Colors.red,
                          size: 48,
                        ),
                        const SizedBox(height: 12),
                        const Text('No se pudo cargar el PDF'),
                        const SizedBox(height: 8),
                        Text(
                          _error!,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _cargando = true;
                              _error = null;
                            });
                            _cargarPdf();
                          },
                          child: const Text('Reintentar'),
                        ),
                      ],
                    ),
                  ),
                )
              : SfPdfViewer.memory(_bytesPdf!),
    );
  }
}
