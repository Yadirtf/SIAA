// justificacion_form_screen.dart — Radicar justificación de una sesión (US-JUS-01)
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_theme.dart';
import '../../data/repositories/justificacion_repository.dart';
import '../../data/services/soporte_picker_service.dart';
import '../cubit/justificacion_form_cubit.dart';
import '../cubit/justificacion_form_state.dart';
import '../widgets/justificacion_form_body.dart';
import '../widgets/radicacion_exitosa_view.dart';
import 'mis_justificaciones_screen.dart';

class JustificacionFormScreen extends StatelessWidget {
  final String sesionId;
  final String? nombreSesion;
  final String? fechaSesion;
  final JustificacionRepository? repository;
  final SoportePickerService? picker;

  const JustificacionFormScreen({
    super.key,
    required this.sesionId,
    this.nombreSesion,
    this.fechaSesion,
    this.repository,
    this.picker,
  });

  /// Abre el formulario; devuelve `true` si se radicó la justificación.
  static Future<bool?> abrir(
    BuildContext context, {
    required String sesionId,
    String? nombreSesion,
    String? fechaSesion,
  }) {
    return Navigator.of(context).push<bool>(MaterialPageRoute(
      builder: (_) => JustificacionFormScreen(
        sesionId: sesionId,
        nombreSesion: nombreSesion,
        fechaSesion: fechaSesion,
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final repo = repository ?? JustificacionRepository();
    return BlocProvider(
      create: (_) => JustificacionFormCubit(
        repo,
        sesionId: sesionId,
        picker: picker,
      ),
      child: Scaffold(
        appBar: AppBar(title: const Text('Justificar inasistencia')),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(SIAASpacing.md),
            child: BlocBuilder<JustificacionFormCubit, JustificacionFormState>(
              builder: (context, state) {
                final radicada = state.radicada;
                if (state.envio == EnvioJustificacion.exito &&
                    radicada != null) {
                  return RadicacionExitosaView(
                    justificacion: radicada,
                    onVerMisJustificaciones: () =>
                        Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (_) =>
                            MisJustificacionesScreen(repository: repo),
                      ),
                    ),
                  );
                }
                return JustificacionFormBody(
                  state: state,
                  nombreSesion: nombreSesion,
                  fechaSesion: fechaSesion,
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
