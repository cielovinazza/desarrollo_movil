import 'package:flutter/material.dart';
import 'crear_cotizacion_page.dart';

class CotizacionesTabPage extends StatelessWidget {
  const CotizacionesTabPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.description_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Historial de Cotizaciones vacío',
              style: TextStyle(fontSize: 18, color: Colors.grey, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'Presiona el botón + para iniciar el Stepper del Sprint 2',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CrearCotizacionPage()),
          );
        },
        label: const Text('Nueva Cotización'),
        icon: const Icon(Icons.add),
        backgroundColor: const Color(0xFF2E7D32), 
      ),
    );
  }
}