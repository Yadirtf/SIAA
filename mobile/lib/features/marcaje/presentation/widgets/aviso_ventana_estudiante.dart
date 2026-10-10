// aviso_ventana_estudiante.dart — Mensaje claro para el estudiante cuando su docente aún
// no habilita el marcaje o ya lo cerró (US-MAR-13), en lugar de una cuenta regresiva.
import 'package:flutter/material.dart';

import '../../../../core/utils/fechas_es.dart';
import '../../domain/models/sesion_activa_model.dart';

class AvisoVentanaEstudiante extends StatelessWidget {
  final SesionActivaModel sesion;

  const AvisoVentanaEstudiante({super.key, required this.sesion});

  /// Texto corto para la insignia de la tarjeta de sesión.
  static String insignia(VentanaInfo ventana) =>
      ventana.estaCerrada ? 'Marcaje cerrado' : 'Aún no habilitado';

  @override
  Widget build(BuildContext context) {
    final ventana = sesion.ventana;
    if (ventana.estaAbierta) return const SizedBox.shrink();
    final cerrada = ventana.estaCerrada;
    final color = cerrada ? Colors.grey.shade800 : Colors.blue.shade800;
    final fondo = cerrada ? Colors.grey.shade100 : Colors.blue.shade50;
    final titulo = cerrada
        ? 'El marcaje para estudiantes ya cerró'
        : 'Tu docente aún no habilita el marcaje';
    final detalle = cerrada
        ? 'Si no alcanzaste a marcar, habla con tu docente.'
        : ventana.minutosParaAbrir > 0
            ? 'Tu clase empieza a las ${hora12h(sesion.inicioProgramado)}. '
                'Desliza hacia abajo para actualizar cuando tu docente lo habilite.'
            : 'Desliza hacia abajo para actualizar cuando tu docente lo habilite.';
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: fondo,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
              cerrada
                  ? Icons.lock_clock_rounded
                  : Icons.hourglass_empty_rounded,
              color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(titulo,
                    style:
                        TextStyle(color: color, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(detalle, style: TextStyle(color: color, fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
