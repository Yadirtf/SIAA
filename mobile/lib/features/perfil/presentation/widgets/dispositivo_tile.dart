// dispositivo_tile.dart — Dispositivo vinculado a la cuenta (RF-AUT-004)
import 'package:flutter/material.dart';

import '../../../../core/utils/fechas_es.dart';
import '../../domain/perfil_model.dart';

class DispositivoTile extends StatelessWidget {
  final DispositivoPerfil dispositivo;
  final bool esActual;

  const DispositivoTile(
      {super.key, required this.dispositivo, required this.esActual});

  @override
  Widget build(BuildContext context) {
    final d = dispositivo;
    final color = d.revocado || d.pendienteAprobacion
        ? Colors.orange.shade800
        : (d.confiable ? Colors.green.shade700 : Colors.grey.shade700);
    final nombre = d.modelo.isNotEmpty ? d.modelo : 'Dispositivo';
    final detalle = [
      if (d.so.isNotEmpty) d.so,
      if (d.versionApp.isNotEmpty) 'App ${d.versionApp}',
      if (d.vinculadoEn != null)
        'Vinculado el ${fechaCorta(d.vinculadoEn!.toLocal())}',
    ].join(' · ');
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(Icons.smartphone_rounded, color: color),
      title: Row(
        children: [
          Flexible(child: Text(nombre, overflow: TextOverflow.ellipsis)),
          if (esActual) ...[
            const SizedBox(width: 6),
            const Chip(
              label: Text('Este dispositivo', style: TextStyle(fontSize: 10)),
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
            ),
          ],
        ],
      ),
      subtitle: Text(detalle.isEmpty ? '—' : detalle),
      trailing: Text(d.estadoEtiqueta,
          style: TextStyle(
              color: color, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }
}
