// mis_justificaciones_screen.dart — Justificaciones propias del docente (US-JUS-03)
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/repositories/justificacion_repository.dart';
import '../../domain/models/justificacion_model.dart';
import '../cubit/justificaciones_lista_cubit.dart';
import '../cubit/justificaciones_lista_state.dart';
import '../widgets/filtro_estado_bar.dart';
import '../widgets/justificacion_card.dart';
import 'justificacion_detalle_screen.dart';

class MisJustificacionesScreen extends StatelessWidget {
  final JustificacionRepository? repository;

  const MisJustificacionesScreen({super.key, this.repository});

  @override
  Widget build(BuildContext context) {
    final repo = repository ?? JustificacionRepository();
    return BlocProvider(
      create: (_) => JustificacionesListaCubit(repo)..cargar(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Mis Justificaciones'),
          centerTitle: true,
        ),
        body:
            BlocConsumer<JustificacionesListaCubit, JustificacionesListaState>(
          listenWhen: (a, b) =>
              b.error != null &&
              b.error != a.error &&
              b.carga == CargaLista.lista,
          listener: (context, state) => ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(state.error!))),
          builder: (context, state) {
            final cubit = context.read<JustificacionesListaCubit>();
            return Column(
              children: [
                FiltroEstadoBar(
                  seleccionado: state.filtro,
                  onCambiar: (estado) => cubit.cargar(estado: estado),
                ),
                Expanded(child: _contenido(context, state, repo)),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _contenido(
    BuildContext context,
    JustificacionesListaState state,
    JustificacionRepository repo,
  ) {
    final cubit = context.read<JustificacionesListaCubit>();
    switch (state.carga) {
      case CargaLista.inicial:
      case CargaLista.cargando:
        return const Center(child: CircularProgressIndicator());
      case CargaLista.error:
        return _mensaje(
          icono: Icons.error_outline,
          texto: state.error ?? 'No se pudieron cargar las justificaciones',
          accion: TextButton(
            onPressed: () => cubit.cargar(estado: state.filtro),
            child: const Text('Reintentar'),
          ),
        );
      case CargaLista.lista:
        break;
    }
    return RefreshIndicator(
      onRefresh: cubit.refrescar,
      child: state.items.isEmpty
          ? ListView(children: [
              const SizedBox(height: 80),
              _mensaje(
                icono: Icons.edit_note_rounded,
                texto: 'No tienes justificaciones registradas.\n'
                    'Para radicar una, abre tu historial de asistencia y '
                    'pulsa "Justificar" en la sesión correspondiente.',
              ),
            ])
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: state.items.length + (state.hayMas ? 1 : 0),
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, i) {
                if (i == state.items.length) return _cargarMas(state, cubit);
                return JustificacionCard(
                  justificacion: state.items[i],
                  onTap: () => _abrirDetalle(context, state.items[i], repo),
                );
              },
            ),
    );
  }

  Widget _cargarMas(
    JustificacionesListaState state,
    JustificacionesListaCubit cubit,
  ) {
    return Center(
      child: state.cargandoMas
          ? const CircularProgressIndicator()
          : TextButton(
              onPressed: cubit.cargarMas, child: const Text('Cargar más')),
    );
  }

  Widget _mensaje(
      {required IconData icono, required String texto, Widget? accion}) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icono, size: 56, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          Text(texto, textAlign: TextAlign.center),
          if (accion != null) accion,
        ],
      ),
    );
  }

  Future<void> _abrirDetalle(
    BuildContext context,
    Justificacion j,
    JustificacionRepository repo,
  ) async {
    final cubit = context.read<JustificacionesListaCubit>();
    await Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => JustificacionDetalleScreen(
        justificacion: j,
        repository: repo,
      ),
    ));
    if (!cubit.isClosed) await cubit.refrescar();
  }
}
