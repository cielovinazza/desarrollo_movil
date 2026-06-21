import 'package:flutter/material.dart';

class PostItTab extends StatelessWidget {
  final String observacion;
  final String codigo;
  final Color color;

  const PostItTab({
    super.key,
    required this.observacion,
    required this.codigo,
    this.color = const Color(0xFFFFF59D),
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _mostrarNotaDialog(context),
      child: Tooltip(
        message: 'Ver nota',
        child: Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 3,
                offset: const Offset(1, 1), 
              ),
            ],
          ),
          child: const Center(
            child: Icon(
              Icons.sticky_note_2_outlined,
              size: 16,
              color: Colors.black87,
            ),
          ),
        ),
      ),
    );
  }

  void _mostrarNotaDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Transform.rotate(
            angle: -0.02,
            child: Container(
              constraints: const BoxConstraints(maxWidth: 320),
              padding: const EdgeInsets.fromLTRB(22, 28, 22, 22),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF59D),
                borderRadius: BorderRadius.circular(2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.35),
                    blurRadius: 16,
                    offset: const Offset(4, 8),
                  ),
                ],
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    top: -38,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Transform.rotate(
                        angle: -0.5,
                        child: Container(
                          width: 46,
                          height: 18,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.55),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.8),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.sticky_note_2_outlined,
                            size: 16,
                            color: Colors.brown.shade400,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              codigo.isEmpty ? 'Observación' : 'Observación · $codigo',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: Colors.brown.shade700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Text(
                        observacion,
                        style: TextStyle(
                          fontSize: 14.5,
                          height: 1.4,
                          color: Colors.brown.shade900,
                        ),
                      ),
                      const SizedBox(height: 18),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () => Navigator.pop(context),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.brown.shade700,
                          ),
                          child: const Text('Cerrar'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _FlagClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final double w = size.width;
    final double h = size.height;
    final double puntaW = h * 0.55;

    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(w - puntaW, 0)
      ..lineTo(w, h / 2)
      ..lineTo(w - puntaW, h)
      ..lineTo(0, h)
      ..close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
class _FlagDashedBorderPainter extends CustomPainter {
  final Color color;
  final double dashWidth;
  final double dashGap;
  final double strokeWidth;

  _FlagDashedBorderPainter({
    required this.color,
    this.dashWidth = 3,
    this.dashGap = 2.5,
    this.strokeWidth = 1,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final path = _FlagClipper().getClip(size);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    for (final metric in path.computeMetrics()) {
      double distance = 0;
      while (distance < metric.length) {
        final double siguiente = distance + dashWidth;
        canvas.drawPath(
          metric.extractPath(
            distance,
            siguiente.clamp(0, metric.length),
          ),
          paint,
        );
        distance = siguiente + dashGap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _FlagDashedBorderPainter oldDelegate) => false;
}