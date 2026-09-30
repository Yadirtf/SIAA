// marcaje_admin_tile.dart — Fila del listado administrativo de marcajes (US-MAR-09)
import 'package:flutter/material.dart';

import '../../../../core/utils/fechas_es.dart';
import '../../../marcaje/domain/models/marcaje_historial_model.dart';
import '../../../marcaje/presentation/widgets/resultado_badge.dart';

class MarcajeAdminTile extends StatelessWidget {
  final MarcajeHistorialItem item;
  final VoidCallback onTap;

  const MarcajeAdminTile({super.key, required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final persona = item.usuarioNombre.isNotEmpty
        ? item.usuarioNombre
        : 'Usuario sin nombre';
    final aula = item.espacioCodigo.isEmpty ? '' : ' · ${item.espacioCodigo}';
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: ListTile(
        onTap: onTap,
        title:
            Text(persona, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(
          '${item.tituloSesion}$aula\n'
          '${item.tipo == 'SALIDA' ? 'Salida' : 'Entrada'} · ${fechaHora(item.timestampServidor)}',
        ),
        isThreeLine: true,
        trailing: ResultadoBadge(item: item),
      ),
    );
  }
}
