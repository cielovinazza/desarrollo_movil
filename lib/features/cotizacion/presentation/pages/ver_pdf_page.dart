import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart'; 

class VerPdfPage extends StatelessWidget {
  final String? url;
  final String codigoCotizacion;

  const VerPdfPage({super.key, 
     required this.url,
    required this.codigoCotizacion
    });

  @override
  Widget build(BuildContext context) {
    final theme=Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('PDF: $codigoCotizacion'),
      ),
      body: (url == null || url!.isEmpty)
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'Error: El enlace del documento no es válido o no existe.',
                  style: TextStyle(fontSize: 16, color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : SfPdfViewer.network(url!), 
    );
  }
}