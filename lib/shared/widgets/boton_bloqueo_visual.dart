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

    return ElevatedButton(
      onPressed: puedePresionar ? onPressed : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: colorActivo,
        foregroundColor: Colors.white,
        disabledBackgroundColor: Colors.grey.shade300,
        disabledForegroundColor: Colors.grey.shade600,
        padding: padding,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (cargando) ...[
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            ),
            const SizedBox(width: 8),
          ] 
          else if (icon != null) ...[
            Icon(icon, size: 18),
            const SizedBox(width: 8),
          ],
          const SizedBox(height: 6,),
          Text(
            cargando ? 'Procesando...' : texto,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}