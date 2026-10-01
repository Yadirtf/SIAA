import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/hora_12h.dart';
import '../bloc/academico_bloc.dart';
import '../bloc/academico_event.dart';
import '../bloc/academico_state.dart';
import '../dialogs/asignacion_dialog.dart';
import '../dialogs/importar_csv_dialog.dart';
import '../helpers/filtro_asignaciones.dart';
import '../widgets/filtros_asignaciones_bar.dart';
import '../widgets/tabla_asignaciones.dart';

/// Asignaciones horarias (US-ACA-02, US-ACA-03, US-ACA-08) con filtros por
/// periodo, día y búsqueda libre. Abre en el periodo activo si hay uno.
class AsignacionesScreen extends StatefulWidget {
  const AsignacionesScreen({super.key});

  @override
  State<AsignacionesScreen> createState() => _AsignacionesScreenState();
}

class _AsignacionesScreenState extends State<AsignacionesScreen> {
  FiltroAsignaciones? _filtro;

  FiltroAsignaciones _filtroInicial(AcademicoLoaded state) {
    final activo = state.periodos.where((p) => p.estado == 'ACTIVO');
    return FiltroAsignaciones(
      periodoId: activo.isEmpty ? null : activo.first.id,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(28),
      child: BlocBuilder<AcademicoBloc, AcademicoState>(
        buildWhen: (prev, curr) =>
            curr is AcademicoLoaded ||
            curr is AcademicoLoading ||
            curr is AcademicoError,
        builder: (context, state) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _encabezado(context, state),
            const SizedBox(height: 24),
            Expanded(child: _contenido(context, state)),
          ],
        ),
      ),
    );
  }

  Widget _encabezado(BuildContext context, AcademicoState state) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Asignaciones Horarias y Aulas', style: AppTextStyles.h2),
              const SizedBox(height: 4),
              Text(
                'Vinculación docente-grupo-aula y franjas recurrentes (US-ACA-02, US-ACA-03, US-ACA-08)',
                style: AppTextStyles.bodyMedium,
              ),
            ],
          ),
        ),
        OutlinedButton.icon(
          onPressed: () => showDialog(
            context: context,
            builder: (_) => const ImportarCsvDialog(),
          ),
          icon: const Icon(Icons.file_upload_outlined, size: 18),
          label: const Text('Carga Masiva CSV'),
        ),
        const SizedBox(width: 8),
        IconButton(
          icon: const Icon(Icons.refresh_rounded),
          tooltip: 'Actualizar lista',
          onPressed: () =>
              context.read<AcademicoBloc>().add(const LoadAcademicoDataEvent()),
        ),
        const SizedBox(width: 8),
        if (state is AcademicoLoaded)
          ElevatedButton.icon(
            onPressed: () => showDialog(
              context: context,
              builder: (_) => AsignacionDialog(
                periodos: state.periodos,
                grupos: state.grupos,
                asignaturas: state.asignaturas,
              ),
            ),
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('Nueva Asignación'),
          ),
      ],
    );
  }

  Widget _contenido(BuildContext context, AcademicoState state) {
    if (state is AcademicoError) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: AppColors.accentRose,
              size: 40,
            ),
            const SizedBox(height: 12),
            Text(state.message, style: AppTextStyles.bodyMedium),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => context.read<AcademicoBloc>().add(
                const LoadAcademicoDataEvent(),
              ),
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }
    if (state is! AcademicoLoaded) {
      return const Center(child: CircularProgressIndicator());
    }
    final filtro = _filtro ??= _filtroInicial(state);
    final filas = filtro.aplicar(
      asignaciones: state.asignaciones,
      asignaturas: state.asignaturas,
      grupos: state.grupos,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FiltrosAsignacionesBar(
          periodos: state.periodos,
          filtro: filtro,
          resultados: filas.length,
          onCambio: (f) => setState(() => _filtro = f),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: filas.isEmpty
              ? _vacio(state.asignaciones.isEmpty)
              : TablaAsignaciones(
                  filas: filas,
                  onEditar: (f) => showDialog(
                    context: context,
                    builder: (_) => AsignacionDialog(
                      periodos: state.periodos,
                      grupos: state.grupos,
                      asignaturas: state.asignaturas,
                      inicial: f.asignacion,
                    ),
                  ),
                  onEliminar: (f) => _confirmarEliminar(context, f),
                ),
        ),
      ],
    );
  }

  Widget _vacio(bool sinRegistros) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.schedule_rounded,
            size: 48,
            color: AppColors.textMuted.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            sinRegistros
                ? 'No hay asignaciones horarias registradas'
                : 'Ninguna asignación coincide con los filtros',
            style: AppTextStyles.h3,
          ),
          const SizedBox(height: 6),
          Text(
            sinRegistros
                ? 'Utilice el botón "Nueva Asignación" o "Carga Masiva CSV" para programar horarios.'
                : 'Cambie el periodo, el día o el texto de búsqueda.',
            style: AppTextStyles.bodyMedium,
          ),
        ],
      ),
    );
  }

  Future<void> _confirmarEliminar(
    BuildContext context,
    FilaAsignacion f,
  ) async {
    final a = f.asignacion;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Eliminar esta asignación?'),
        content: Text(
          '${f.asignatura}, grupo ${f.grupo}, con ${f.docente}, '
          '${nombreDia(a.diaSemana).toLowerCase()} de '
          '${hora12hDesdeTexto(a.horaInicio)} a ${hora12hDesdeTexto(a.horaFin)}.\n\n'
          'Las clases que aún no han ocurrido se cancelarán. '
          'Las ya dictadas se conservan en el historial.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      context.read<AcademicoBloc>().add(DeleteAsignacionEvent(a.id));
    }
  }
}
