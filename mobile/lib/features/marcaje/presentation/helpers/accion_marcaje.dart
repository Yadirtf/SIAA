// accion_marcaje.dart — Tipo, etiqueta e ícono del botón de marcaje según la ventana vigente (US-MAR-15)
import 'package:flutter/material.dart';
import '../../domain/models/sesion_activa_model.dart';

class AccionMarcaje {
  /// Tipo que se envía al servidor: ENTRADA | SALIDA.
  final String tipo;
  final String label;
  final IconData icon;

  const AccionMarcaje._(this.tipo, this.label, this.icon);

  /// El tipo lo decide la ventana que informa el servidor, no el marcaje previo:
  /// en ventana de entrada nunca se ofrece la salida (el servidor la rechazaría).
  factory AccionMarcaje.de(SesionActivaModel sesion) {
    if (!sesion.ventana.esSalida) {
      return sesion.tieneMarcajeEntrada
          ? const AccionMarcaje._(
              'ENTRADA', 'ENTRADA REGISTRADA', Icons.check_circle_rounded)
          : const AccionMarcaje._(
              'ENTRADA', 'MARCAR ENTRADA', Icons.touch_app_rounded);
    }
    if (sesion.salidaDesactivada) {
      return const AccionMarcaje._(
          'SALIDA', 'SALIDA DESACTIVADA', Icons.block_rounded);
    }
    return sesion.tieneMarcajeSalida
        ? const AccionMarcaje._(
            'SALIDA', 'SALIDA REGISTRADA', Icons.check_circle_rounded)
        : const AccionMarcaje._(
            'SALIDA', 'MARCAR SALIDA', Icons.logout_rounded);
  }
}

/// Formatea minutos de permanencia: 95 → "1 h 35 min", 40 → "40 min", 120 → "2 h".
String formatearPermanencia(int minutos) {
  final m = minutos < 0 ? 0 : minutos;
  final horas = m ~/ 60;
  final resto = m % 60;
  if (horas == 0) return '$resto min';
  if (resto == 0) return '$horas h';
  return '$horas h $resto min';
}
