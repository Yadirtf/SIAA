// horario_card.dart - Tarjeta compacta de una sesión del horario (US-ACA-01..09, §9.1)
import 'package:flutter/material.dart';
import '../../data/models/sesion_horario_model.dart';

class HorarioCard extends StatelessWidget {
  final SesionHorarioModel sesion;

  const HorarioCard({super.key, required this.sesion});

  Color _color(BuildContext context) {
    if (sesion.esCancelada) return Colors.red.shade700;
    if (sesion.enCurso) return Colors.green.shade700;
    return Theme.of(context).colorScheme.primary;
  }

  @override
  Widget build(BuildContext context) {
    final color = _color(context);
    final gris =
        Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.65);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: color.withValues(alpha: 0.25)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 52,
              child: Column(
                children: [
                  Text(sesion.horaInicio,
                      style:
                          TextStyle(fontWeight: FontWeight.bold, color: color)),
                  Text(sesion.horaFin,
                      style: TextStyle(fontSize: 12, color: gris)),
                ],
              ),
            ),
            Container(
              width: 3,
              height: 44,
              margin: const EdgeInsets.symmetric(horizontal: 10),
              color: color,
            ),
            Expanded(child: _detalle(gris)),
          ],
        ),
      ),
    );
  }

  Widget _detalle(Color gris) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                sesion.tituloConGrupo,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  decoration:
                      sesion.esCancelada ? TextDecoration.lineThrough : null,
                ),
              ),
            ),
            if (!sesion.esProgramada)
              Text(
                sesion.estadoEtiqueta.toUpperCase(),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: sesion.esCancelada ? Colors.red.shade700 : gris,
                ),
              ),
          ],
        ),
        const SizedBox(height: 2),
        _linea(Icons.meeting_room_outlined, sesion.aulaEtiqueta, gris),
        if (sesion.docentesNombres.isNotEmpty)
          _linea(Icons.person_outline, sesion.docentesNombres.join(', '), gris),
        if (sesion.esCancelada && sesion.motivoCancelacion != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              'Motivo: ${sesion.motivoCancelacion}',
              style: TextStyle(fontSize: 12, color: Colors.red.shade800),
            ),
          ),
      ],
    );
  }

  Widget _linea(IconData icono, String texto, Color gris) => Padding(
        padding: const EdgeInsets.only(top: 2),
        child: Row(
          children: [
            Icon(icono, size: 14, color: gris),
            const SizedBox(width: 4),
            Expanded(
              child: Text(texto,
                  style: TextStyle(fontSize: 12, color: gris),
                  overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
      );
}
