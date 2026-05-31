import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart'; 
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class VerPdfPage extends StatelessWidget {
  final String? url;
  final String codigoCotizacion;

  const VerPdfPage({super.key, 
     required this.url,
    required this.codigoCotizacion
    });

  void compartir(BuildContext context){
    if (url == null || url!.isEmpty) return;
    
    SharePlus.instance.share(ShareParams(
      title: 'Cotizacion: $codigoCotizacion',
      text: 'Cotizacion $codigoCotizacion\n$url'
    ));
  }

  Future<void> descargarPdf(BuildContext context)async{
    if (url == null || url!.isEmpty)return;

    final uri=Uri.parse(url!);
    try{
      if (await canLaunchUrl(uri)){
        await launchUrl(uri,mode: LaunchMode.externalApplication);
      }else{
        throw 'No se pudo abrir el enlace de descarga';
      }
    } catch(e){
      if (context.mounted){
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error en la descarga: $e'), backgroundColor: Colors.red,)
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme=Theme.of(context);
    final bool urlValida = url != null && url!.isNotEmpty;
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('PDF: $codigoCotizacion'),
        actions: [
          IconButton(icon: const Icon(Icons.share_outlined),
          tooltip: 'Compartir PDF',
          onPressed: urlValida ? ()=>compartir(context):null
          ),

          IconButton(icon: const Icon(Icons.download_outlined),
          tooltip: 'Descargar PDF',
          onPressed: urlValida? ()=>descargarPdf(context):null,),
          const SizedBox(width: 8,)
        ],
      ),
      body: !urlValida
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