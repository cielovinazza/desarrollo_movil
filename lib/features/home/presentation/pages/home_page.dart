import 'package:flutter/material.dart';
import 'package:project/features/cliente/presentation/pages/registro_cliente_page.dart';
import 'package:project/features/cliente/presentation/pages/listado_cliente_page.dart';
import 'package:project/features/cotizacion/presentation/pages/crear_cotizacion_page.dart';
import 'package:project/shared/design_system/app_theme.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:project/core/utils/currency_formatter.dart';

class HomePage extends StatelessWidget {
  final VoidCallback onGoToCotizaciones;
  final bool isDarkMode;
  final ValueChanged<bool> onThemeChanged;

  const HomePage({
    super.key,
    required this.onGoToCotizaciones,
    required this.isDarkMode,
    required this.onThemeChanged,
  });

  void _mostrarConfiguracion(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Configuración',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              SwitchListTile(
                title: const Text('Modo Oscuro'),
                value: isDarkMode,
                onChanged: (value) {
                  onThemeChanged(value);
                },
              ),
              ListTile(
                leading: const Icon(Icons.sync),
                title: const Text('Sincronizar datos'),
                subtitle: const Text('Sincronización manual con Firebase'),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Sincronización manual seleccionada'),
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final esOscuro = theme.brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sistema de Cotizaciones'),
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle_outlined),
            onPressed: () => _mostrarConfiguracion(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              children: [
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Theme.of(context).cardColor,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                    border: Border.all(color: AppTheme.primary, width: 3),
                  ),
                  child: ClipOval(
                    child: Image.asset(
                      'assets/images/logoapp.png',
                      height: 152,
                      width: 152,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                Text(
                  'App de Cotizaciones',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),

                const SizedBox(height: 6),

                Text(
                  'Gestione sus proyectos y clientes con precisión y rapidez profesional.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                  ),
                ),

                const SizedBox(height: 28),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.primary,
                        AppTheme.primary.withValues(alpha: 0.85),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primary.withValues(alpha: 0.25),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Nueva Cotización',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Inicie una propuesta técnica hoy.',
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const CrearCotizacionPage(),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).cardColor,
                            foregroundColor: esOscuro
                                ? Colors.white
                                : theme.primaryColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 2,
                          ),
                          icon: Icon(Icons.add_circle_outline),
                          label: Text(
                            'Crear Ahora',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                Row(
                  children: [
                    Expanded(
                      child: _ActionCard(
                        icon: Icons.person_add_alt_1,
                        title: 'Registrar Cliente',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const RegistroClientePage(),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: _ActionCard(
                        icon: Icons.people_alt,
                        title: 'Ver Clientes',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ListadoClientesPage(),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                _DashboardMetricas(onTap: onGoToCotizaciones),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DashboardMetricas extends StatefulWidget {
  final VoidCallback onTap;

  const _DashboardMetricas({required this.onTap});

  @override
  State<_DashboardMetricas> createState() => _DashboardMetricasState();
}

class _DashboardMetricasState extends State<_DashboardMetricas> {
  bool cargando = true;
  bool usandoCache = false;

  double totalMes = 0;
  Map<String, int> estados = {};

  static const String _cacheKey = 'dashboard_metricas_mes';

  @override
  void initState() {
    super.initState();
    _cargarMetricas();
  }

  Future<void> _cargarMetricas() async {
    try {
      final ahora = DateTime.now();
      final inicioMes = DateTime(ahora.year, ahora.month, 1);
      final inicioMesSiguiente = DateTime(ahora.year, ahora.month + 1, 1);

      final snapshot = await FirebaseFirestore.instance
          .collection('cotizaciones')
          .where(
            'fechaCreacion',
            isGreaterThanOrEqualTo: Timestamp.fromDate(inicioMes),
          )
          .where(
            'fechaCreacion',
            isLessThan: Timestamp.fromDate(inicioMesSiguiente),
          )
          .get()
          .timeout(const Duration(seconds: 4));

      double total = 0;
      final Map<String, int> conteoEstados = {};

      for (final doc in snapshot.docs) {
        final data = doc.data();

        final monto = data['totalFinal'];
        if (monto is num) {
          total += monto.toDouble();
        }

        final estado = (data['estado'] ?? 'Sin estado').toString();
        conteoEstados[estado] = (conteoEstados[estado] ?? 0) + 1;
      }

      await _guardarCache(total, conteoEstados);

      if (!mounted) return;
      setState(() {
        totalMes = total;
        estados = conteoEstados;
        cargando = false;
        usandoCache = false;
      });
    } catch (_) {
      await _cargarDesdeCache();
    }
  }

  Future<void> _guardarCache(double total, Map<String, int> estados) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(
      _cacheKey,
      jsonEncode({'totalMes': total, 'estados': estados}),
    );
  }

  Future<void> _cargarDesdeCache() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_cacheKey);

    if (raw == null) {
      if (!mounted) return;
      setState(() {
        cargando = false;
        usandoCache = true;
      });
      return;
    }

    final data = jsonDecode(raw) as Map<String, dynamic>;

    if (!mounted) return;
    setState(() {
      totalMes = (data['totalMes'] as num?)?.toDouble() ?? 0;
      estados = Map<String, int>.from(data['estados'] ?? {});
      cargando = false;
      usandoCache = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final totalCotizaciones = estados.values.fold<int>(0, (a, b) => a + b);

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.primaryColor.withValues(alpha: 0.12)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: cargando
            ? const Center(child: CircularProgressIndicator())
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: theme.primaryColor.withValues(
                          alpha: 0.1,
                        ),
                        child: Icon(Icons.bar_chart, color: theme.primaryColor),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Dashboard del Mes',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (usandoCache) const Icon(Icons.cloud_off, size: 18),
                    ],
                  ),

                  const SizedBox(height: 16),

                  Text(
                    'Total cotizado este mes',
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${CurrencyFormatter.format(totalMes)} CLP',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.primaryColor,
                    ),
                  ),

                  const Divider(height: 28),

                  Text(
                    'Estados de cotizaciones',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),

                  if (estados.isEmpty)
                    const Text('No hay cotizaciones registradas este mes.')
                  else
                    ...estados.entries.map((entry) {
                      final porcentaje = totalCotizaciones == 0
                          ? 0.0
                          : entry.value / totalCotizaciones;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${entry.key}: ${entry.value}'),
                            const SizedBox(height: 4),
                            LinearProgressIndicator(
                              value: porcentaje,
                              minHeight: 8,
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ],
                        ),
                      );
                    }),

                  if (usandoCache) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Mostrando últimos datos guardados sin conexión.',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ],
              ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final esOscuro = theme.brightness == Brightness.dark;
    return Material(
      color: Theme.of(context).cardColor,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          height: 120,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: esOscuro
                  ? Colors.white.withValues(alpha: 0.08)
                  : AppTheme.primary.withValues(alpha: 0.1),
            ),
            boxShadow: [
              BoxShadow(
                color: esOscuro
                    ? Colors.white.withValues(alpha: 0.015)
                    : Colors.black.withValues(alpha: 0.01),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                backgroundColor: AppTheme.primary.withValues(alpha: 0.1),
                child: Icon(icon, color: AppTheme.primary),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
