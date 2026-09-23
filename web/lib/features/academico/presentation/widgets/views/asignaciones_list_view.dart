import 'package:flutter/material.dart';
import '../../../data/academico_models.dart';

class AsignacionesListView extends StatelessWidget {
  final List<AsignacionModel> asignaciones;

  const AsignacionesListView({super.key, required this.asignaciones});

  @override
  Widget build(BuildContext context) {
    if (asignaciones.isEmpty) {
      return const Center(
        child: Text('No hay asignaciones para este periodo académico.'),
      );
    }

    return ListView.separated(
      itemCount: asignaciones.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (ctx, i) {
        final a = asignaciones[i];
        return ListTile(
          leading: CircleAvatar(
            backgroundColor:
                a.exentaGeoespacial ? Colors.purple.shade50 : Colors.blue.shade50,
            child: Icon(
              a.exentaGeoespacial ? Icons.computer : Icons.room,
              color: a.exentaGeoespacial ? Colors.purple : Colors.blue,
            ),
          ),
          title: Text(
            '${a.docenteNombre} — Grupo ${a.grupoId}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Text(
            '${a.franja.diaNombre} ${a.franja.horaInicio} - ${a.franja.horaFin} | Espacio: ${a.espacioNombre ?? a.espacioId ?? "Sin aula física"}',
          ),
          trailing: Chip(
            label: Text(
              a.modalidad,
              style: const TextStyle(fontSize: 11),
            ),
          ),
        );
      },
    );
  }
}
