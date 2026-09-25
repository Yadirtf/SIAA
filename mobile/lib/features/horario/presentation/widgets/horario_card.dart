// horario_card.dart - Tarjeta representativa de una sesión de clase en el horario (US-ACA-01..09)
import 'package:flutter/material.dart';
import '../../data/models/sesion_horario_model.dart';

class HorarioCard extends StatelessWidget {
  final SesionHorarioModel sesion;

  const HorarioCard({super.key, required this.sesion});

  Color _obtenerColorEstado(BuildContext context) {
    if (sesion.esCancelada) return Colors.red.shade700;
    if (sesion.enCurso) return Colors.green.shade700;
    return Theme.of(context).primaryColor;
  }

  Color _obtenerFondoEstado() {
    if (sesion.esCancelada) return Colors.red.shade50;
    if (sesion.enCurso) return Colors.green.shade50;
    return Colors.blue.shade50;
  }

  @override
  Widget build(BuildContext context) {
    final colorPrincipal = _obtenerColorEstado(context);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 1.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: sesion.esCancelada ? Colors.red.shade200 : Colors.grey.shade200,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.access_time_rounded, size: 16, color: colorPrincipal),
                    const SizedBox(width: 6),
                    Text(
                      '${sesion.horaInicio} - ${sesion.horaFin}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: colorPrincipal,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: _obtenerFondoEstado(),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: colorPrincipal.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    sesion.estado,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: colorPrincipal,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              sesion.asignatura,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                decoration: sesion.esCancelada ? TextDecoration.lineThrough : null,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                Chip(
                  avatar: const Icon(Icons.people_outline, size: 14),
                  label: Text('Grupo ${sesion.grupo}'),
                  padding: EdgeInsets.zero,
                  labelStyle: const TextStyle(fontSize: 12),
                  visualDensity: VisualDensity.compact,
                ),
                Chip(
                  avatar: const Icon(Icons.meeting_room_outlined, size: 14),
                  label: Text(sesion.espacio),
                  padding: EdgeInsets.zero,
                  labelStyle: const TextStyle(fontSize: 12),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            if (sesion.esCancelada && sesion.motivoCancelacion != null) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Motivo: ${sesion.motivoCancelacion}',
                  style: TextStyle(fontSize: 12, color: Colors.red.shade900),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
