import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../data/models/sesion_model.dart';
import '../../domain/academico_repository.dart';
import '../cubit/sesion_detalle_cubit.dart';
import '../widgets/estado_sesion_chip.dart';
import '../widgets/parametros_congelados_lista.dart';

/// Detalle de una sesión con sus parámetros congelados. Consulta el servidor
/// para saber cuáles difieren ya de la cascada vigente.
class SesionDetalleDialog extends StatelessWidget {
  final SesionModel sesion;

  /// Por defecto el repositorio del contexto.
  final AcademicoRepository? repository;

  const SesionDetalleDialog({super.key, required this.sesion, this.repository});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (ctx) => SesionDetalleCubit(
        repository: repository ?? ctx.read<AcademicoRepository>(),
      )..cargar(sesion.id),
      child: AlertDialog(
        title: Row(
          children: [
            const Icon(
              Icons.event_note_rounded,
              color: AppColors.primaryAccent,
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(sesion.grupoTexto, style: AppTextStyles.h3)),
          ],
        ),
        content: SizedBox(
          width: 520,
          child: BlocBuilder<SesionDetalleCubit, SesionDetalleState>(
            builder: (context, state) {
              if (state.cargando) {
                return const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              if (state.error != null) {
                return Text(state.error!, style: AppTextStyles.bodyMedium);
              }
              return _Contenido(sesion: state.sesion!);
            },
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }
}

class _Contenido extends StatelessWidget {
  final SesionModel sesion;

  const _Contenido({required this.sesion});

  Widget _dato(String etiqueta, String valor) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 110,
          child: Text(etiqueta, style: AppTextStyles.bodySmall),
        ),
        Expanded(
          child: Text(
            valor.isEmpty ? '—' : valor,
            style: AppTextStyles.bodySmall.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    final s = sesion;
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: EstadoSesionChip(s.estado),
          ),
          const SizedBox(height: 8),
          _dato('Fecha', '${s.fecha} · ${s.horaInicio}–${s.horaFin}'),
          _dato('Aula', s.aulaTexto),
          _dato('Ubicación', s.ubicacionTexto),
          _dato('Docentes', s.docentesTexto),
          if (s.motivoCancelacion.isNotEmpty)
            _dato('Motivo', s.motivoCancelacion),
          const SizedBox(height: 16),
          Text('Parámetros congelados (RN-002)', style: AppTextStyles.h3),
          const SizedBox(height: 8),
          ParametrosCongeladosLista(
            congelados: s.parametrosCongelados,
            diferentes: s.parametrosDiferentes,
          ),
        ],
      ),
    );
  }
}
