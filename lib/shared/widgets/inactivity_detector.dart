import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class InactivityDetector extends StatefulWidget {
  final Widget child;
  final int timeoutMinutes;
  final int warningMinutes;

  const InactivityDetector({
    super.key, 
    required this.child,
    this.timeoutMinutes = 10,
    this.warningMinutes = 1,
  });

  @override
  State<InactivityDetector> createState() => _InactivityDetectorState();
}

class _InactivityDetectorState extends State<InactivityDetector> {
  Timer? _timer;
  bool _dialogoVisible = false;
  bool _cerrando = false;

  void _resetTimer() {
    if (_dialogoVisible) return;
    _timer?.cancel();
    _timer = Timer(
      Duration(minutes: widget.timeoutMinutes - widget.warningMinutes),
      _mostrarAviso,
    );
  }

  Future<void> _cerrarSesion() async {
    _timer?.cancel();
    _cerrando = true;

    if (_dialogoVisible && mounted) {
      _dialogoVisible = false;
      Navigator.of(context, rootNavigator: true).pop();
    }

    await FirebaseAuth.instance.signOut();
  }

  // CRITERIO DE ACEPTACIÓN 2: Cancela la cuenta regresiva de gracia y reinicia el timer general
  void _mantenerConectado(BuildContext dialogCtx) {
    _timer?.cancel(); // Frena el timer que gatillaba _cerrarSesion
    setState(() {
      _dialogoVisible = false;
    });
    Navigator.of(dialogCtx).pop(); // Cierra el modal de alerta
    _timer = Timer(
      Duration(minutes: widget.timeoutMinutes - widget.warningMinutes),
      _mostrarAviso,
    );
  }

  void _mostrarAviso() {
    if (!mounted || _dialogoVisible) return;
    _dialogoVisible = true;

    _timer = Timer(Duration(minutes: widget.warningMinutes), _cerrarSesion);

    showDialog(
      context: context,
      barrierDismissible: false, // Forzar uso de botones explícitos para consistencia de UX
      builder: (ctx) => AlertDialog(
        title: const Text('Sesión a punto de expirar'),
        content: Text(
          'Tu sesión se cerrará en ${widget.warningMinutes} minuto(s) '
          'por inactividad.',
        ),
        actions: [
          // CRITERIO DE ACEPTACIÓN 1: Botón de acción secundario explícito para continuar
          OutlinedButton(
            onPressed: () => _mantenerConectado(ctx),
            child: const Text('Mantener conectado'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _cerrarSesion();
            },
            child: const Text('Cerrar sesión'),
          ),
        ],
      ),
    ).then((_) {
      // Manejo seguro por si el diálogo es destruido por otra vía
      if (!_cerrando && _dialogoVisible) {
        setState(() {
          _dialogoVisible = false;
        });
        _resetTimer();
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _resetTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => _resetTimer(),
      onPointerMove: (_) => _resetTimer(),
      onPointerSignal: (_) => _resetTimer(),
      child: widget.child,
    );
  }
}