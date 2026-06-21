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

  String _formatearFecha(DateTime fecha) {
    final dia = fecha.day.toString().padLeft(2, '0');
    final mes = fecha.month.toString().padLeft(2, '0');
    return '$dia/$mes/${fecha.year}';
  }

  Future<void> _seleccionarFecha(
    BuildContext context,
    DateTime? actual,
    ValueChanged<DateTime?> onChanged,
  ) async {
    final fecha = await showDatePicker(
      context: context,
      initialDate: actual ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (fecha != null) onChanged(fecha);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final hayFiltrosFecha = fechaInicioFiltro != null || fechaFinFiltro != null;

    return Card(
      elevation: 0,
      color: theme.cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: theme.dividerColor.withValues(alpha: 0.3)),
      ),
      child: Theme(
        data: theme.copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          title: Row(
            children: [
              Icon(Icons.tune, size: 18, color: theme.hintColor),
              const SizedBox(width: 8),
              Text(
                'Filtros avanzados',
                style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
              ),
              if (hayFiltrosFecha) ...[
                const SizedBox(width: 8),
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: theme.primaryColor,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ],
          ),
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          expandedCrossAxisAlignment: CrossAxisAlignment.start,
          shape: const Border(),
          collapsedShape: const Border(),
          children: [
            TextField(
              controller: idSearchController,
              textCapitalization: TextCapitalization.characters,
              enableSuggestions: false,
              autocorrect: false,
              onChanged: onFiltroIdChanged,
              decoration: InputDecoration(
                labelText: 'Buscar por código único',
                hintText: 'Ej: CT-001',
                prefixIcon: Icon(Icons.key_outlined, size: 20, color: theme.hintColor),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: searchController,
              onChanged: onFiltroClienteChanged,
              decoration: InputDecoration(
                labelText: 'Buscar por nombre del cliente',
                prefixIcon: Icon(Icons.person_outline, size: 20, color: theme.hintColor),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: estadoFiltro,
              decoration: const InputDecoration(labelText: 'Filtrar por estado'),
              items: const [
                DropdownMenuItem(value: null, child: Text('Todos los estados')),
                DropdownMenuItem(value: 'En Proceso', child: Text('En Proceso')),
                DropdownMenuItem(value: 'Lista para Envío', child: Text('Lista para Envío')),
                DropdownMenuItem(value: 'Enviada', child: Text('Enviada')),
                DropdownMenuItem(value: 'Aprobada por el Cliente', child: Text('Aprobada por el Cliente')),
                DropdownMenuItem(value: 'Rechazada por el Cliente', child: Text('Rechazada por el Cliente')),
                DropdownMenuItem(value: 'Cancelada', child: Text('Cancelada')),
              ],
              onChanged: onEstadoChanged,
            ),
            const SizedBox(height: 16),
            Text(
              'Rango de fechas',
              style: textTheme.labelMedium?.copyWith(color: theme.hintColor),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _FiltroFechaChip(
                  icon: Icons.calendar_today_outlined,
                  label: fechaInicioFiltro == null
                      ? 'Desde'
                      : 'Desde ${_formatearFecha(fechaInicioFiltro!)}',
                  activo: fechaInicioFiltro != null,
                  onTap: () => _seleccionarFecha(
                    context,
                    fechaInicioFiltro,
                    onFechaInicioChanged,
                  ),
                  onClear: fechaInicioFiltro != null
                      ? () => onFechaInicioChanged(null)
                      : null,
                ),
                _FiltroFechaChip(
                  icon: Icons.calendar_today_outlined,
                  label: fechaFinFiltro == null
                      ? 'Hasta'
                      : 'Hasta ${_formatearFecha(fechaFinFiltro!)}',
                  activo: fechaFinFiltro != null,
                  onTap: () => _seleccionarFecha(
                    context,
                    fechaFinFiltro,
                    onFechaFinChanged,
                  ),
                  onClear: fechaFinFiltro != null
                      ? () => onFechaFinChanged(null)
                      : null,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _FiltroFechaChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool activo;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  const _FiltroFechaChip({
    required this.icon,
    required this.label,
    required this.activo,
    required this.onTap,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final Color bg = activo
        ? theme.primaryColor.withValues(alpha: 0.12)
        : Colors.transparent;
    final Color fg = activo ? theme.primaryColor : colorScheme.onSurfaceVariant;
    final Color border = activo
        ? theme.primaryColor.withValues(alpha: 0.4)
        : theme.dividerColor.withValues(alpha: 0.4);

    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 15, color: fg),
              const SizedBox(width: 6),
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: fg,
                  fontWeight: activo ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
              if (onClear != null) ...[
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: onClear,
                  child: Icon(Icons.close, size: 14, color: fg),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}