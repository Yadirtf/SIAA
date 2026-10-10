// marcaje_grupal_screen.dart — Control del docente: ventana de marcaje para estudiantes
// (US-MAR-13) y acceso al pase de lista manual (US-MAR-14). Todo viene del servidor.
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../shared/widgets/estado_vista.dart';
import '../../data/datasources/marcaje_grupal_remote_datasource.dart';
import '../cubit/marcaje_grupal_cubit.dart';
import '../cubit/marcaje_grupal_state.dart';
import '../widgets/grupal/lista_manual_card.dart';
import '../widgets/grupal/sesion_grupal_header.dart';
import '../widgets/grupal/ventana_estudiantil_card.dart';
import 'lista_manual_screen.dart';

class MarcajeGrupalScreen extends StatelessWidget {
  final MarcajeGrupalRemoteDataSource? grupal;
  final CargadorSesionActiva? cargarSesion;

  const MarcajeGrupalScreen({super.key, this.grupal, this.cargarSesion});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          MarcajeGrupalCubit(grupal: grupal, cargarSesion: cargarSesion)
            ..cargar(),
      child: _MarcajeGrupalView(grupal: grupal),
    );
  }
}

class _MarcajeGrupalView extends StatelessWidget {
  final MarcajeGrupalRemoteDataSource? grupal;

  const _MarcajeGrupalView({this.grupal});

  Future<void> _abrirListaManual(
      BuildContext context, MarcajeGrupalState state) async {
    final sesion = state.sesion;
    if (sesion == null) return;
    final cubit = context.read<MarcajeGrupalCubit>();
    await Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => ListaManualScreen(
        sesionId: sesion.id,
        asignatura: sesion.asignatura,
        remote: grupal,
      ),
    ));
    if (!cubit.isClosed) await cubit.cargar();
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<MarcajeGrupalCubit>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Marcaje del grupo'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Actualizar',
            onPressed: cubit.cargar,
          ),
        ],
      ),
      body: BlocConsumer<MarcajeGrupalCubit, MarcajeGrupalState>(
        listenWhen: (a, b) => a.avisoId != b.avisoId && b.aviso != null,
        listener: (context, state) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(
              content: Text(state.aviso!),
              backgroundColor: state.avisoEsError
                  ? Colors.red.shade800
                  : Colors.green.shade700,
            ));
        },
        builder: (context, state) {
          switch (state.carga) {
            case CargaGrupal.cargando:
              return const Center(child: CircularProgressIndicator());
            case CargaGrupal.error:
              return EstadoError(
                mensaje: state.error ?? 'No pudimos cargar tu clase.',
                onReintentar: cubit.cargar,
              );
            case CargaGrupal.sinSesion:
              return RefreshIndicator(
                onRefresh: cubit.cargar,
                child: ListView(children: const [
                  SizedBox(height: 80),
                  EstadoVacio(
                    icono: Icons.event_busy_rounded,
                    mensaje: 'No tienes una clase en curso en este momento.',
                    detalle:
                        'Cuando empiece tu clase podrás habilitar el marcaje de tus estudiantes.',
                  ),
                ]),
              );
            case CargaGrupal.lista:
              return RefreshIndicator(
                onRefresh: cubit.cargar,
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    SesionGrupalHeader(sesion: state.sesion!),
                    const SizedBox(height: 12),
                    VentanaEstudiantilCard(
                      state: state,
                      onDuracion: cubit.seleccionarDuracion,
                      onAbrir: cubit.abrirVentana,
                      onCerrar: cubit.cerrarVentana,
                      onVencida: cubit.ventanaVencida,
                    ),
                    const SizedBox(height: 12),
                    ListaManualCard(
                      onIniciar: () => _abrirListaManual(context, state),
                    ),
                  ],
                ),
              );
          }
        },
      ),
    );
  }
}
