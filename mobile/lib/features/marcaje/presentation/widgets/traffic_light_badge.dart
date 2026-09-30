// traffic_light_badge.dart — Semáforo visual de 6 estados (SRS §9.1)
import 'package:flutter/material.dart';
import '../bloc/marcaje_state.dart';

class TrafficLightBadge extends StatelessWidget {
  final SemaforoMarcaje semaforo;
  final double? precision;

  const TrafficLightBadge({
    super.key,
    required this.semaforo,
    this.precision,
  });

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    IconData icon;
    String label;

    switch (semaforo) {
      case SemaforoMarcaje.fueraDeVentana:
        bg = Colors.grey.shade200;
        fg = Colors.grey.shade700;
        icon = Icons.timer_outlined;
        label = 'Fuera de ventana';
        break;
      case SemaforoMarcaje.buscandoGps:
        bg = Colors.blue.shade50;
        fg = Colors.blue.shade700;
        icon = Icons.radar_rounded;
        label = 'Buscando satélites GPS...';
        break;
      case SemaforoMarcaje.precisionInsuficiente:
        bg = Colors.amber.shade100;
        fg = Colors.amber.shade900;
        icon = Icons.gps_not_fixed_rounded;
        label = precision != null
            ? 'Precisión baja (±${precision!.toStringAsFixed(1)}m)'
            : 'Precisión GPS insuficiente';
        break;
      case SemaforoMarcaje.listo:
        bg = Colors.green.shade50;
        fg = Colors.green.shade700;
        icon = Icons.check_circle_outline_rounded;
        label = precision != null
            ? 'Listo para marcar (±${precision!.toStringAsFixed(1)}m)'
            : 'Listo para marcar';
        break;
      case SemaforoMarcaje.fueraDeAula:
        bg = Colors.red.shade50;
        fg = Colors.red.shade700;
        icon = Icons.location_off_rounded;
        label = 'Ubicación fuera del aula';
        break;
      case SemaforoMarcaje.registrado:
        bg = Colors.teal.shade50;
        fg = Colors.teal.shade800;
        icon = Icons.verified_rounded;
        label = 'Marcaje registrado';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: fg.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: fg),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                color: fg,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
