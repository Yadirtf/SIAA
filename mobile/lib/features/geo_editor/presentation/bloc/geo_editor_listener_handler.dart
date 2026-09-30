import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:siaa_mobile/core/theme/app_theme.dart';
import '../widgets/dialogs/solapamiento_dialogs.dart';
import 'geo_editor_bloc.dart';
import 'geo_editor_event.dart';
import 'geo_editor_state.dart';

class GeoEditorListenerHandler {
  static void manejarEstado(
    BuildContext context,
    GeoEditorState state, {
    required String espacioId,
  }) {
    if (state.solapamientoCritico != null) {
      SolapamientoDialogs.mostrarCritico(context, state.solapamientoCritico!);
      return;
    }
    if (state.solapamientoAdvertencia != null) {
      SolapamientoDialogs.mostrarAdvertencia(
        context,
        advertencia: state.solapamientoAdvertencia!,
        detalles: state.solapamientoDetalles,
        onConfirmar: (motivo) {
          context.read<GeoEditorBloc>().add(
                GuardarGeometriaBackendRequested(
                  espacioId: espacioId,
                  confirmarSolapamiento: true,
                  motivoSolapamiento: motivo,
                ),
              );
        },
      );
      return;
    }
    if (state.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(state.errorMessage!),
          backgroundColor: SIAAColors.asistenciaAusente,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
    if (state.successMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(state.successMessage!),
          backgroundColor: SIAAColors.asistenciaPresente,
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.of(context).pop(true);
    }
  }
}
