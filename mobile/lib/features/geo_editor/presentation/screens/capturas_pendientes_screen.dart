// capturas_pendientes_screen.dart — Capturas de cartografía hechas sin conexión (US-GEO-10)
// Muestra el resultado de cada sincronización (AC-02), abre en el editor las rechazadas
// para corregirlas (AC-03) y presenta los conflictos para que el usuario decida (AC-04).
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/geo/offline_cartografia_service.dart';
import '../../../home/presentation/navigation/geo_editor_navigator.dart';
import '../../data/cartografia_sync_service.dart';
import '../../data/espacio_repository.dart';
import '../cubit/capturas_pendientes_cubit.dart';
import '../widgets/captura_pendiente_tile.dart';
import '../widgets/dialogs/conflicto_captura_dialog.dart';

class CapturasPendientesScreen extends StatelessWidget {
  final OfflineCartografiaService? cola;
  final EspacioRepository? repositorio;

  const CapturasPendientesScreen({super.key, this.cola, this.repositorio});

  @override
  Widget build(BuildContext context) {
    final repo = repositorio ?? EspacioRepository();
    return BlocProvider(
      create: (_) => CapturasPendientesCubit(
        cola: cola,
        sync: CartografiaSyncService(cola: cola, repositorio: repo),
      )..cargar(),
      child: BlocConsumer<CapturasPendientesCubit, CapturasPendientesState>(
        listenWhen: (a, b) => b.mensaje != null && a.mensaje != b.mensaje,
        listener: (context, state) => ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(state.mensaje!))),
        builder: (context, state) => Scaffold(
          appBar: AppBar(
            title: const Text('Capturas sin conexión'),
            actions: [
              IconButton(
                tooltip: 'Sincronizar ahora',
                icon: const Icon(Icons.sync_rounded),
                onPressed: state.sincronizando
                    ? null
                    : context.read<CapturasPendientesCubit>().sincronizar,
              ),
            ],
          ),
          body: Column(children: [
            if (state.sincronizando) const LinearProgressIndicator(),
            Expanded(child: _lista(context, state, repo)),
          ]),
        ),
      ),
    );
  }

  Widget _lista(BuildContext context, CapturasPendientesState state,
      EspacioRepository repo) {
    if (state.capturas.isEmpty) {
      return const Center(
        child: Text('No hay capturas guardadas sin conexión.'),
      );
    }
    final cubit = context.read<CapturasPendientesCubit>();
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        for (final c in state.capturas)
          CapturaPendienteTile(
            captura: c,
            onDescartar: () => cubit.descartar(c),
            onCorregir: () => _abrirEditor(context, c, repo),
            onResolverConflicto: () => _resolver(context, c, repo),
          ),
      ],
    );
  }

  Future<void> _resolver(BuildContext context, CapturaOfflineEspacio c,
      EspacioRepository repo) async {
    final cubit = context.read<CapturasPendientesCubit>();
    final decision = await ConflictoCapturaDialog.mostrar(context, c);
    if (!context.mounted) return;
    switch (decision) {
      case DecisionConflicto.mantenerMia:
        await cubit.mantenerMiCaptura(c);
      case DecisionConflicto.descartarMia:
        await cubit.descartar(c);
      case DecisionConflicto.revisarEnEditor:
        await _abrirEditor(context, c, repo);
      case null:
        break;
    }
  }

  /// Abre el editor con los vértices de la captura sobre el espacio vigente en el
  /// servidor; sin red usa los datos guardados con la captura.
  Future<void> _abrirEditor(BuildContext context, CapturaOfflineEspacio c,
      EspacioRepository repo) async {
    final cubit = context.read<CapturasPendientesCubit>();
    EspacioModel espacio;
    try {
      espacio = await repo.obtenerEspacioPorId(c.espacioId);
    } catch (_) {
      espacio = EspacioModel(
        id: c.espacioId,
        sedeId: '',
        codigo: c.espacioCodigo,
        nombre: c.espacioNombre,
        capacidad: 0,
        tipo: 'AULA',
        estado: 'ACTIVO',
        nivelValidacion: 'AULA',
        bufferMetros: 0,
        areaMetrosCuadrados: 0,
        tieneGeometria: false,
        versionGeometria: c.versionEsperada,
      );
    }
    if (!context.mounted) return;
    await GeoEditorNavigator.navegar(
      context: context,
      espacio: espacio,
      espacioRepo: repo,
      captura: c,
      cola: cola,
      onRetorno: cubit.cargar,
    );
  }
}
