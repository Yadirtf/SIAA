import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/formatos.dart';
import '../../../../core/widgets/aviso_panel.dart';
import '../../../../core/widgets/encabezado_seccion.dart';
import '../bloc/tablero_cubit.dart';
import '../bloc/tablero_state.dart';
import '../widgets/tablero_detalle.dart';
import '../widgets/tablero_indicadores.dart';

/// Tablero de indicadores en vivo (US-REP-03). Requiere un [TableroCubit]
/// ya iniciado en el contexto; se actualiza solo mientras está abierto.
class TableroScreen extends StatelessWidget {
  const TableroScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TableroCubit, TableroState>(
      builder: (context, state) {
        final cubit = context.read<TableroCubit>();
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              EncabezadoSeccion(
                icono: Icons.monitor_heart_outlined,
                titulo: 'Tablero en vivo',
                subtitulo: 'Pulso del día dentro de su ámbito',
                acciones: [
                  OutlinedButton.icon(
                    onPressed: state.status == TableroStatus.cargando
                        ? null
                        : cubit.actualizar,
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: const Text('Actualizar'),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _contenido(state, cubit),
            ],
          ),
        );
      },
    );
  }

  Widget _contenido(TableroState state, TableroCubit cubit) {
    final t = state.tablero;
    if (t == null) {
      if (state.status == TableroStatus.error) {
        return AvisoPanel.error(
          titulo: 'No se pudo cargar el tablero',
          detalle: state.error ?? '',
          onReintentar: cubit.actualizar,
        );
      }
      return AvisoPanel.cargando();
    }
    final proxima = state.proximaActualizacion;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (state.error != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              'No se pudo actualizar: ${state.error}. Se muestran los últimos '
              'datos.',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.statusDangerText,
              ),
            ),
          ),
        TableroIndicadores(tablero: t),
        const SizedBox(height: 16),
        TableroSinMarcaje(sesiones: t.sinMarcaje),
        const SizedBox(height: 16),
        TableroAlertas(alertas: t.alertas),
        const SizedBox(height: 8),
        Text(
          'Día ${t.fecha} · actualizado ${Formatos.fechaHora(t.generadoEn)}'
          '${proxima == null ? '' : ' · próxima actualización en '
                    '${proxima.inSeconds} s'}',
          style: AppTextStyles.bodySmall,
        ),
      ],
    );
  }
}
