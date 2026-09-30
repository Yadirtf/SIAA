import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:siaa_mobile/core/theme/app_theme.dart';
import '../bloc/geo_editor_bloc.dart';
import '../bloc/geo_editor_event.dart';
import '../bloc/geo_editor_state.dart';
import 'dialogs/confirmar_reinicio_dialog.dart';
import 'dialogs/historial_versiones_dialog.dart';

class GeoEditorAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String espacioId;
  final String espacioCodigo;
  final String espacioNombre;
  final GeoEditorState state;

  const GeoEditorAppBar({
    super.key,
    required this.espacioId,
    required this.espacioCodigo,
    required this.espacioNombre,
    required this.state,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Cartografía: $espacioCodigo',
              style: const TextStyle(fontSize: 16)),
          Text(espacioNombre,
              style:
                  const TextStyle(fontSize: 12, color: SIAAColors.neutral400)),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.history_rounded),
          tooltip: 'Historial de versiones (US-GEO-06)',
          onPressed: () {
            context.read<GeoEditorBloc>().add(
                  CargarVersionesHistoricasRequested(espacioId),
                );
            HistorialVersionesDialog.mostrar(
              context,
              versiones: state.versionesHistoricas,
              versionActivaPreview: state.versionPreview?.version,
              onSeleccionarPreview: (version) {
                context.read<GeoEditorBloc>().add(
                      SeleccionarVersionPreviewRequested(version),
                    );
              },
            );
          },
        ),
        IconButton(
          icon: const Icon(Icons.refresh),
          tooltip: 'Reiniciar polígono',
          onPressed: state.vertices.isNotEmpty
              ? () => ConfirmarReinicioDialog.mostrar(
                    context,
                    onConfirmar: () => context
                        .read<GeoEditorBloc>()
                        .add(const LimpiarVerticesRequested()),
                  )
              : null,
        ),
      ],
    );
  }
}
