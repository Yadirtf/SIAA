import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/formatos.dart';
import '../../../../core/widgets/aviso_panel.dart';
import '../../../../core/widgets/encabezado_seccion.dart';
import '../bloc/asistencia_grupo_cubit.dart';
import '../bloc/asistencia_grupo_state.dart';
import '../widgets/asistencia_grupo_resumen.dart';
import '../widgets/asistencia_grupo_tabla.dart';

/// Reporte de asistencia estudiantil por grupo (US-REP-05). Requiere un
/// [AsistenciaGrupoCubit] en el contexto.
class AsistenciaEstudiantilScreen extends StatefulWidget {
  const AsistenciaEstudiantilScreen({super.key});

  @override
  State<AsistenciaEstudiantilScreen> createState() =>
      _AsistenciaEstudiantilScreenState();
}

class _AsistenciaEstudiantilScreenState
    extends State<AsistenciaEstudiantilScreen> {
  @override
  void initState() {
    super.initState();
    context.read<AsistenciaGrupoCubit>().cargarPeriodos();
  }

  Widget _selector({
    required String etiqueta,
    required String? valor,
    required List<(String, String)> opciones,
    required ValueChanged<String?> onCambio,
  }) {
    final ids = opciones.map((o) => o.$1).toSet();
    return SizedBox(
      width: 300,
      child: DropdownButtonFormField<String?>(
        value: ids.contains(valor) ? valor : null,
        isExpanded: true,
        isDense: true,
        decoration: InputDecoration(
          labelText: etiqueta,
          border: const OutlineInputBorder(),
          isDense: true,
        ),
        items: opciones
            .map(
              (o) => DropdownMenuItem<String?>(
                value: o.$1,
                child: Text(o.$2, overflow: TextOverflow.ellipsis),
              ),
            )
            .toList(),
        onChanged: onCambio,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AsistenciaGrupoCubit, AsistenciaGrupoState>(
      builder: (context, state) {
        final cubit = context.read<AsistenciaGrupoCubit>();
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const EncabezadoSeccion(
                icono: Icons.school_outlined,
                titulo: 'Asistencia estudiantil',
                subtitulo:
                    'Porcentaje acumulado por estudiante y promedio del grupo',
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _selector(
                    etiqueta: 'Periodo académico',
                    valor: state.periodoId,
                    opciones: state.periodos
                        .map((p) => (p.id, p.nombre))
                        .toList(),
                    onCambio: cubit.seleccionarPeriodo,
                  ),
                  _selector(
                    etiqueta: 'Grupo',
                    valor: state.grupoId,
                    opciones: state.grupos
                        .map((g) => (g.grupoId, g.etiqueta))
                        .toList(),
                    onCambio: cubit.seleccionarGrupo,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _contenido(state, cubit),
            ],
          ),
        );
      },
    );
  }

  Widget _contenido(AsistenciaGrupoState state, AsistenciaGrupoCubit cubit) {
    switch (state.status) {
      case AsistenciaGrupoStatus.inicial:
        final sinGrupos = state.periodoId != null && state.grupos.isEmpty;
        return AvisoPanel(
          icono: Icons.query_stats_rounded,
          titulo: sinGrupos ? 'Sin grupos disponibles' : 'Elija un grupo',
          detalle:
              state.error ??
              (sinGrupos
                  ? 'No tiene grupos con sesiones en este periodo.'
                  : 'Seleccione el periodo y el grupo a consultar.'),
        );
      case AsistenciaGrupoStatus.cargando:
        return AvisoPanel.cargando();
      case AsistenciaGrupoStatus.error:
        return AvisoPanel.error(
          titulo: 'Error al generar el reporte',
          detalle: state.error ?? '',
          onReintentar: cubit.consultar,
        );
      case AsistenciaGrupoStatus.cargado:
        final r = state.reporte!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AsistenciaGrupoResumen(reporte: r),
            const SizedBox(height: 16),
            if (r.estudiantes.isEmpty)
              const AvisoPanel(
                icono: Icons.person_search_rounded,
                titulo: 'Grupo sin estudiantes',
                detalle: 'El grupo no tiene integrantes registrados.',
              )
            else
              AsistenciaGrupoTabla(reporte: r),
            const SizedBox(height: 8),
            Text(
              'Filas resaltadas: asistencia por debajo del umbral mínimo '
              '(${r.umbral} %). El porcentaje es el mismo que ve el estudiante '
              'en la app. Generado: ${Formatos.fechaHora(r.generadoEn)}',
              style: AppTextStyles.bodySmall,
            ),
          ],
        );
    }
  }
}
