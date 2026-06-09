import 'package:flutter/material.dart';

class BotonBloqueoVisual extends StatelessWidget {
  final bool habilitado;
  final bool cargando;
  final VoidCallback? onPressed;
  final IconData? icon;
  final String texto;
  final Color colorActivo;
  final EdgeInsetsGeometry padding;

  const BotonBloqueoVisual({
    super.key,
    required this.habilitado,
    required this.onPressed,
    required this.texto,
    required this.colorActivo,
    this.cargando = false,
    this.icon,
    this.padding = const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
  });

  @override
  Widget build(BuildContext context) {
    final puedePresionar = habilitado && !cargando;

    return ElevatedButton.icon(
      onPressed: puedePresionar ? onPressed : null,
      icon: cargando
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Icon(icon ?? Icons.check_circle_outline, size: 18),
      label: Text(
        cargando ? 'Procesando...' : texto,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: colorActivo,
        foregroundColor: Colors.white,
        disabledBackgroundColor: Colors.grey.shade300,
        disabledForegroundColor: Colors.grey.shade600,
        padding: padding,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}
