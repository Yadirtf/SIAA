// aviso_privacidad_screen.dart — Aviso de privacidad a pantalla completa (US-LEG-01, CA-011)
// Se presenta antes de cualquier solicitud de permiso de ubicación y no se puede
// descartar sin una decisión explícita (Acepto / No acepto).
import 'package:flutter/material.dart';
import '../widgets/privacidad_view.dart';

class AvisoPrivacidadScreen extends StatelessWidget {
  const AvisoPrivacidadScreen({super.key});

  static bool _visible = false;

  /// true mientras el aviso está en pantalla (bloquea otras navegaciones).
  static bool get visible => _visible;

  /// Muestra el aviso; se cierra cuando el usuario registra su decisión.
  /// Devuelve true si aceptó.
  static Future<bool> mostrar(BuildContext context) async {
    if (_visible) return false;
    _visible = true;
    try {
      final r = await Navigator.of(context).push<bool>(MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => const AvisoPrivacidadScreen(),
      ));
      return r ?? false;
    } finally {
      _visible = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: const Text('Aviso de privacidad'),
        ),
        body: SafeArea(
          child: PrivacidadView(
            onDecidido: (acepta) => Navigator.of(context).pop(acepta),
          ),
        ),
      ),
    );
  }
}
