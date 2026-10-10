// sesion_grupal_header.dart — Datos de la clase en curso para el control grupal del docente
import 'package:flutter/material.dart';

import '../../../../../core/utils/fechas_es.dart';
import '../../../domain/models/sesion_activa_model.dart';

class SesionGrupalHeader extends StatelessWidget {
  final SesionActivaModel sesion;

  const SesionGrupalHeader({super.key, required this.sesion});

  @override
  Widget build(BuildContext context) {
    final gris = Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(sesion.asignatura,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text('Grupo ${sesion.grupo} · Aula ${sesion.espacio.codigo}',
                style: TextStyle(color: gris)),
            const SizedBox(height: 2),
            Text(
              '${hora12h(sesion.inicioProgramado)} - ${hora12h(sesion.finProgramado)}',
              style: TextStyle(color: gris),
            ),
          ],
        ),
      ),
    );
  }
}
