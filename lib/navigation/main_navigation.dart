import 'package:flutter/material.dart';
import 'package:project/features/cliente/presentation/pages/listado_cliente_page.dart';
import 'package:project/features/home/presentation/pages/home_page.dart';
import 'package:project/features/cotizacion/presentation/pages/cotizaciones_page.dart';

class MainNavigation extends StatefulWidget {
  final bool isDarkMode;
  final ValueChanged<bool> onThemeChanged;

  const MainNavigation({
    super.key,
    required this.isDarkMode,
    required this.onThemeChanged,
  });

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;
  bool _filtrarMesActual = false;

  void changeTab(int index) {
    setState(() {
      _currentIndex = index;

      if (index != 2) {
        _filtrarMesActual = false;
      }
    });
  }

  void abrirCotizacionesMesActual() {
    setState(() {
      _filtrarMesActual = true;
      _currentIndex = 2;
    });
  }

  List<Widget> get _pages => [
        HomePage(
          onGoToCotizaciones: abrirCotizacionesMesActual,
          isDarkMode: widget.isDarkMode,
          onThemeChanged: widget.onThemeChanged,
        ),
        const ListadoClientesPage(),
        CotizacionesPage(filtrarMesActual: _filtrarMesActual),
      ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: changeTab,
        selectedItemColor: const Color(0xFF2E7D32),
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Inicio',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people_outline),
            activeIcon: Icon(Icons.people),
            label: 'Clientes',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.description_outlined),
            activeIcon: Icon(Icons.description),
            label: 'Cotizaciones',
          ),
        ],
      ),
    );
  }
}
