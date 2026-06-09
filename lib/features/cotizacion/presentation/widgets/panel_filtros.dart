import 'package:flutter/material.dart';

class PanelFiltros extends StatelessWidget {
  final TextEditingController idSearchController;
  final TextEditingController searchController;
  final String? estadoFiltro;
  final DateTime? fechaInicioFiltro;
  final DateTime? fechaFinFiltro;
  final ValueChanged<String> onFiltroIdChanged;
  final ValueChanged<String> onFiltroClienteChanged;
  final ValueChanged<String?> onEstadoChanged;
  final ValueChanged<DateTime?> onFechaInicioChanged;
  final ValueChanged<DateTime?> onFechaFinChanged;

  const PanelFiltros({
    super.key,
    required this.idSearchController,
    required this.searchController,
    required this.estadoFiltro,
    required this.fechaInicioFiltro,
    required this.fechaFinFiltro,
    required this.onFiltroIdChanged,
    required this.onFiltroClienteChanged,
    required this.onEstadoChanged,
    required this.onFechaInicioChanged,
    required this.onFechaFinChanged,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: Theme.of(context).dividerColor.withValues(alpha: 0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(4.0),
        child: ExpansionTile(
          title: Text('Filtros Avanzados', style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          childrenPadding: const EdgeInsets.all(12),
          expandedCrossAxisAlignment: CrossAxisAlignment.start,
          shape: const Border(),
          children: [
            TextField(
              controller: idSearchController,
              textCapitalization: TextCapitalization.characters,
              enableSuggestions: false,
              autocorrect: false,
              onChanged: onFiltroIdChanged,
              decoration: const InputDecoration(
                labelText: 'Buscar por código único',
                prefixIcon: Icon(Icons.key),
                hintText: 'Ej: CT-001',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: searchController,
              onChanged: onFiltroClienteChanged,
              decoration: const InputDecoration(
                labelText: 'Buscar por nombre del cliente',
                prefixIcon: Icon(Icons.person),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: estadoFiltro,
              decoration: const InputDecoration(labelText: 'Filtrar por Estado'),
              items: const [
                DropdownMenuItem(value: null, child: Text('Todos los estados')),
                DropdownMenuItem(value: 'En Proceso', child: Text('En Proceso')),
                DropdownMenuItem(value: 'Lista para Envío', child: Text('Lista para Envío')),
                DropdownMenuItem(value: 'Enviada', child: Text('Enviada')),
                DropdownMenuItem(value: 'Aprobada por el Cliente', child: Text('Aprobada por el Cliente')),
                DropdownMenuItem(value: 'Rechazada por el Cliente', child: Text('Rechazada por el Cliente')),
              ],
              onChanged: onEstadoChanged,
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 12)),
                    onPressed: () async {
                      final fecha = await showDatePicker(
                        context: context,
                        initialDate: fechaInicioFiltro ?? DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2100),
                      );
                      if (fecha != null) onFechaInicioChanged(fecha);
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.date_range, size: 18),
                            const SizedBox(width: 8),
                            Text(
                              fechaInicioFiltro == null ? 'Desde' : '${fechaInicioFiltro!.day}/${fechaInicioFiltro!.month}/${fechaInicioFiltro!.year}',
                              style: const TextStyle(fontSize: 13),
                            ),
                          ],
                        ),
                        if (fechaInicioFiltro != null)
                          GestureDetector(
                            onTap: () => onFechaInicioChanged(null),
                            child: const Padding(
                              padding: EdgeInsets.all(4.0),
                              child: Icon(Icons.close, size: 16, color: Colors.grey),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 12)),
                    onPressed: () async {
                      final fecha = await showDatePicker(
                        context: context,
                        initialDate: fechaFinFiltro ?? DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2100),
                      );
                      if (fecha != null) onFechaFinChanged(fecha);
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.date_range, size: 18),
                            const SizedBox(width: 8),
                            Text(
                              fechaFinFiltro == null ? 'Hasta' : '${fechaFinFiltro!.day}/${fechaFinFiltro!.month}/${fechaFinFiltro!.year}',
                              style: const TextStyle(fontSize: 13),
                            ),
                          ],
                        ),
                        if (fechaFinFiltro != null)
                          GestureDetector(
                            onTap: () => onFechaFinChanged(null),
                            child: const Padding(
                              padding: EdgeInsets.all(4.0),
                              child: Icon(Icons.close, size: 16, color: Colors.grey),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}