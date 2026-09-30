// mi_horario_screen.dart - Mi horario: vista semanal por día, compacta (US-ACA-01..09, §9.1)
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../shared/widgets/estado_vista.dart';
import '../../../auth/presentation/permisos_sesion.dart';
import '../../domain/repositories/horario_repository.dart';
import '../bloc/horario_bloc.dart';
import '../bloc/horario_event.dart';
import '../bloc/horario_state.dart';
import '../widgets/dias_selector.dart';
import '../widgets/horario_card.dart';
import '../widgets/semana_header.dart';

class MiHorarioScreen extends StatelessWidget {
  final HorarioRepository? repository;

  const MiHorarioScreen({super.key, this.repository});

  @override
  Widget build(BuildContext context) {
    // El backend ya limita al docente a sus sesiones; el id solo acota la consulta.
    final usuarioId = usuarioIdSesion(context);
    return BlocProvider(
      create: (_) => HorarioBloc(repository: repository)
        ..add(CargarHorarioEvent(docenteId: usuarioId)),
      child: const _MiHorarioView(),
    );
  }
}

class _MiHorarioView extends StatelessWidget {
  const _MiHorarioView();

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<HorarioBloc>();
    return BlocBuilder<HorarioBloc, HorarioState>(
      builder: (context, state) {
        final listo = state.estado == EstadoCargaHorario.listo;
        return Column(
          children: [
            SemanaHeader(
              lunes: state.lunes,
              onAnterior: () => bloc.add(const CambiarSemanaEvent(-1)),
              onSiguiente: () => bloc.add(const CambiarSemanaEvent(1)),
            ),
            DiasSelector(
              lunes: state.lunes,
              fechaSeleccionada: state.diaSeleccionado,
              conteo: listo ? state.sesionesEn : null,
              onDiaSeleccionado: (d) => bloc.add(CambiarDiaEvent(d)),
            ),
            const Divider(height: 1),
            Expanded(child: _cuerpo(context, state)),
          ],
        );
      },
    );
  }

  Widget _cuerpo(BuildContext context, HorarioState state) {
    final bloc = context.read<HorarioBloc>();
    switch (state.estado) {
      case EstadoCargaHorario.inicial:
      case EstadoCargaHorario.cargando:
        return const Center(child: CircularProgressIndicator());
      case EstadoCargaHorario.error:
        return EstadoError(
          mensaje: state.error ?? 'No se pudo cargar el horario.',
          onReintentar: () => bloc.add(const RecargarHorarioEvent()),
        );
      case EstadoCargaHorario.listo:
        final sesiones = state.sesionesDelDia;
        return RefreshIndicator(
          onRefresh: () async => bloc.add(const RecargarHorarioEvent()),
          child: sesiones.isEmpty
              ? ListView(children: const [
                  SizedBox(height: 80),
                  EstadoVacio(
                    icono: Icons.event_available_outlined,
                    mensaje: 'Sin clases programadas para este día',
                  ),
                ])
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: sesiones.length,
                  itemBuilder: (_, i) => HorarioCard(sesion: sesiones[i]),
                ),
        );
    }
  }
}
