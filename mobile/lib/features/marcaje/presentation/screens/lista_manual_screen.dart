// lista_manual_screen.dart — Pase de lista manual del docente (US-MAR-14): presente/ausente
// por estudiante, motivo obligatorio y resumen del servidor al guardar.
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../shared/widgets/estado_vista.dart';
import '../../data/datasources/marcaje_grupal_remote_datasource.dart';
import '../cubit/lista_manual_cubit.dart';
import '../cubit/lista_manual_state.dart';
import '../widgets/grupal/estudiante_lista_tile.dart';
import '../widgets/grupal/lista_manual_formulario.dart';
import '../widgets/grupal/resultado_lista_manual_view.dart';

class ListaManualScreen extends StatelessWidget {
  final String sesionId;
  final String asignatura;
  final MarcajeGrupalRemoteDataSource? remote;

  const ListaManualScreen({
    super.key,
    required this.sesionId,
    this.asignatura = '',
    this.remote,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          ListaManualCubit(sesionId: sesionId, remote: remote)..cargar(),
      child: Scaffold(
        appBar: AppBar(
          title: Text(asignatura.isEmpty ? 'Lista manual' : asignatura),
        ),
        body: BlocBuilder<ListaManualCubit, ListaManualState>(
          builder: (context, state) => _cuerpo(context, state),
        ),
      ),
    );
  }

  Widget _cuerpo(BuildContext context, ListaManualState state) {
    final cubit = context.read<ListaManualCubit>();
    if (state.resultado != null) {
      return ResultadoListaManualView(
        resultado: state.resultado!,
        onListo: () => Navigator.of(context).maybePop(),
      );
    }
    switch (state.carga) {
      case CargaListaManual.cargando:
        return const Center(child: CircularProgressIndicator());
      case CargaListaManual.error:
        return EstadoError(
          mensaje: state.error ?? 'No pudimos cargar la lista.',
          onReintentar: cubit.cargar,
        );
      case CargaListaManual.lista:
        if (state.estudiantes.isEmpty) {
          return const EstadoVacio(
            icono: Icons.group_off_rounded,
            mensaje: 'Este grupo aún no tiene estudiantes inscritos.',
          );
        }
        return ListView(
          padding: const EdgeInsets.only(bottom: 24),
          children: [
            _Encabezado(state: state, onTodos: cubit.marcarTodos),
            for (final e in state.estudiantes)
              EstudianteListaTile(
                key: ValueKey(e.id),
                estudiante: e,
                presente: state.presente(e.id),
                habilitado: !state.enviando,
                onCambio: (v) => cubit.cambiarPresente(e.id, v),
              ),
            const Divider(height: 24),
            ListaManualFormulario(
              state: state,
              onMotivo: cubit.cambiarMotivo,
              onEnviar: cubit.enviar,
            ),
          ],
        );
    }
  }
}

class _Encabezado extends StatelessWidget {
  final ListaManualState state;
  final ValueChanged<bool> onTodos;

  const _Encabezado({required this.state, required this.onTodos});

  @override
  Widget build(BuildContext context) {
    final todos =
        state.editables > 0 && state.marcadosPresentes == state.editables;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 4),
      child: Row(children: [
        Expanded(
          child: Text(
            '${state.marcadosPresentes} de ${state.editables} presentes por marcar',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        if (state.editables > 0)
          TextButton(
            onPressed: state.enviando ? null : () => onTodos(!todos),
            child: Text(todos ? 'Ninguno' : 'Todos presentes'),
          ),
      ]),
    );
  }
}
