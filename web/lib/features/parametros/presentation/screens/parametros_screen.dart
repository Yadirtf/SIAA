import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/catalogo_parametros.dart';
import '../../domain/models/parametro_model.dart';
import '../bloc/parametros_bloc.dart';
import '../bloc/parametros_event.dart';
import '../bloc/parametros_state.dart';
import '../widgets/ambito_selector.dart';
import '../widgets/parametros_encabezado.dart';
import '../widgets/parametros_mensajes.dart';
import '../widgets/resumen_ambito.dart';
import '../widgets/seccion_parametros.dart';

/// Pantalla administrativa de parametrización jerárquica.
/// US-PAR-01: permite editar parámetros por nivel.
/// US-PAR-02: muestra la cascada resuelta para cualquier ámbito.
/// US-PAR-03: cada clave indica su nivel de origen.
/// Cada parámetro explica qué controla (icono de información) y la parte
/// superior muestra cómo queda una clase con los valores vigentes.
class ParametrosScreen extends StatefulWidget {
  const ParametrosScreen({super.key});

  @override
  State<ParametrosScreen> createState() => _ParametrosScreenState();
}

const _nombresNivel = {
  'GLOBAL': 'Global (toda la institución)',
  'SEDE': 'Sede',
  'FACULTAD': 'Facultad',
  'BLOQUE': 'Bloque',
  'AULA': 'Aula',
};

class _ParametrosScreenState extends State<ParametrosScreen> {
  AmbitoSeleccion _seleccion = const AmbitoSeleccion(
    nivel: 'GLOBAL',
    nivelId: '',
  );

  @override
  void initState() {
    super.initState();
    _resolver(_seleccion);
  }

  void _resolver(AmbitoSeleccion sel) {
    setState(() => _seleccion = sel);
    context.read<ParametrosBloc>().add(
      CargarParametrosEfectivosEvent(
        sedeId: sel.sedeId,
        facultadId: sel.facultadId,
        bloqueId: sel.bloqueId,
        espacioId: sel.espacioId,
      ),
    );
  }

  void _limpiarMensaje() =>
      context.read<ParametrosBloc>().add(const LimpiarMensajeParametroEvent());

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const ParametrosEncabezado(),
        AmbitoSelector(seleccionActual: _seleccion, onChanged: _resolver),
        BlocBuilder<ParametrosBloc, ParametrosState>(
          buildWhen: (p, c) =>
              (p is ParametrosLoaded && c is ParametrosLoaded) &&
              (p.successMessage != c.successMessage ||
                  p.errorMessage != c.errorMessage),
          builder: (context, state) {
            if (state is! ParametrosLoaded) return const SizedBox.shrink();
            final mensaje = state.errorMessage ?? state.successMessage;
            if (mensaje == null) return const SizedBox.shrink();
            return ParametrosAviso(
              message: mensaje,
              isError: state.errorMessage != null,
              onDismiss: _limpiarMensaje,
            );
          },
        ),
        Expanded(
          child: BlocBuilder<ParametrosBloc, ParametrosState>(
            builder: (context, state) => switch (state) {
              ParametrosLoading() => const Center(
                child: CircularProgressIndicator(
                  color: AppColors.primaryAccent,
                ),
              ),
              ParametrosFailure(:final error) => ParametrosErrorView(
                error: error,
                onRetry: () => _resolver(_seleccion),
              ),
              ParametrosLoaded() => _contenido(state),
              _ => const SizedBox.shrink(),
            },
          ),
        ),
      ],
    );
  }

  Widget _contenido(ParametrosLoaded state) {
    final params = state.snapshot.parametros;
    final porGrupo = <GrupoParametro, List<ParametroEfectivoModel>>{};
    for (final p in params) {
      porGrupo.putIfAbsent(infoParametro(p.clave).grupo, () => []).add(p);
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      children: [
        ResumenAmbito(
          parametros: params,
          ambito: _seleccion.nivel,
          nombreAmbito: _nombresNivel[_seleccion.nivel] ?? _seleccion.nivel,
        ),
        const SizedBox(height: 16),
        for (final grupo in GrupoParametro.values)
          if (porGrupo[grupo] case final lista?)
            SeccionParametros(
              grupo: grupo,
              parametros: lista,
              ambito: _seleccion.nivel,
              ambitoId: _seleccion.nivelId,
              guardando: state.isSaving,
            ),
      ],
    );
  }
}
