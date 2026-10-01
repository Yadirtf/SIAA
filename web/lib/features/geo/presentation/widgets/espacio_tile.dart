import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../data/models/geo_models.dart';
import '../bloc/geo_bloc.dart';
import '../bloc/geo_event.dart';
import '../dialogs/verificacion_espacio_dialog.dart';
import '../edicion/editores_geo.dart';
import '../editor/editor_geometria_dialog.dart';
import 'verificacion_indicador.dart';

/// Fila de la lista de espacios: datos básicos, indicador de verificación
/// complementaria (RF-GEO-016) y acciones de editar, configurar y eliminar.
class EspacioTile extends StatelessWidget {
  final EspacioModel espacio;

  const EspacioTile({super.key, required this.espacio});

  @override
  Widget build(BuildContext context) {
    final verificacion = espacio.verificacionComplementaria;
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.accentEmerald.withOpacity(0.12),
          child: const Icon(
            Icons.meeting_room_outlined,
            color: AppColors.accentEmerald,
          ),
        ),
        title: Row(
          children: [
            Flexible(
              child: Text(
                '${espacio.nombre} (${espacio.codigo})',
                style: AppTextStyles.h3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (espacio.tieneVerificacion) ...[
              const SizedBox(width: 8),
              VerificacionIndicador(verificacion: verificacion!),
            ],
          ],
        ),
        subtitle: Text(
          'Tipo: ${espacio.tipo} • Capacidad: ${espacio.capacidad} est. • Piso: ${espacio.piso ?? 1}'
          '${espacio.tieneGeometria ? '' : ' • Sin polígono'}',
          style: AppTextStyles.bodyMedium,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Editar datos del espacio',
              onPressed: () => editarEspacio(context, espacio),
            ),
            IconButton(
              icon: Icon(
                espacio.tieneGeometria
                    ? Icons.pentagon_rounded
                    : Icons.pentagon_outlined,
                color: espacio.tieneGeometria
                    ? AppColors.accentEmerald
                    : AppColors.textMuted,
              ),
              tooltip: espacio.tieneGeometria
                  ? 'Editar polígono en el mapa'
                  : 'Sin polígono: dibujarlo en el mapa',
              onPressed: () => mostrarEditorGeometria(context, espacio),
            ),
            IconButton(
              icon: const Icon(
                Icons.wifi_tethering_rounded,
                color: AppColors.primaryAccent,
              ),
              tooltip: 'Verificación complementaria',
              onPressed: () =>
                  mostrarVerificacionEspacioDialog(context, espacio),
            ),
            IconButton(
              icon: const Icon(
                Icons.delete_outline_rounded,
                color: AppColors.accentRose,
              ),
              tooltip: 'Eliminar espacio',
              onPressed: () {
                context.read<GeoBloc>().add(DeleteEspacioEvent(espacio.id));
              },
            ),
          ],
        ),
      ),
    );
  }
}
