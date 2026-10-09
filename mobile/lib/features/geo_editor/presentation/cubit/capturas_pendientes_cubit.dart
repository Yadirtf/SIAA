// capturas_pendientes_cubit.dart — Cola de capturas offline de cartografía (US-GEO-10)
// Lista el resultado de cada captura (AC-02), permite corregir las rechazadas (AC-03)
// y que el usuario decida ante un conflicto, sin sobrescrituras silenciosas (AC-04).
import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/geo/offline_cartografia_service.dart';
import '../../data/cartografia_sync_service.dart';

class CapturasPendientesState extends Equatable {
  final List<CapturaOfflineEspacio> capturas;
  final bool sincronizando;
  final String? mensaje;

  /// Contador que cambia con cada lectura de la cola (las capturas son mutables).
  final int revision;

  const CapturasPendientesState({
    this.capturas = const [],
    this.sincronizando = false,
    this.mensaje,
    this.revision = 0,
  });

  @override
  List<Object?> get props => [capturas, sincronizando, mensaje, revision];
}

class CapturasPendientesCubit extends Cubit<CapturasPendientesState> {
  final OfflineCartografiaService _cola;
  final CartografiaSyncService _sync;
  StreamSubscription<void>? _sub;

  CapturasPendientesCubit({
    OfflineCartografiaService? cola,
    CartografiaSyncService? sync,
  })  : _cola = cola ?? OfflineCartografiaService.instancia,
        _sync = sync ?? CartografiaSyncService(cola: cola),
        super(const CapturasPendientesState()) {
    _sub = _cola.cambios.listen((_) => cargar());
  }

  Future<void> cargar({String? mensaje}) async {
    final capturas = await _cola.obtenerTodas();
    if (isClosed) return;
    emit(CapturasPendientesState(
      capturas: capturas,
      sincronizando: state.sincronizando,
      mensaje: mensaje ?? state.mensaje,
      revision: state.revision + 1,
    ));
  }

  Future<void> sincronizar() async {
    if (state.sincronizando) return;
    emit(CapturasPendientesState(
        capturas: state.capturas,
        sincronizando: true,
        revision: state.revision));
    String mensaje;
    try {
      final r = await _sync.sincronizar();
      final quedan = r.pendientesRestantes
          .any((c) => c.estado == EstadoSincronizacion.pendienteSincronizacion);
      mensaje = r.procesados > 0
          ? r.resumen
          : quedan
              ? 'No se pudo contactar al servidor; las capturas siguen pendientes.'
              : 'No hay capturas pendientes de sincronizar.';
    } catch (e) {
      mensaje = 'No fue posible sincronizar: $e';
    }
    if (isClosed) return;
    emit(CapturasPendientesState(
        capturas: state.capturas, mensaje: mensaje, revision: state.revision));
    await cargar();
  }

  /// AC-04: el usuario decide conservar su captura sobre la versión del servidor.
  Future<void> mantenerMiCaptura(CapturaOfflineEspacio c) async {
    await _cola.reintentar(c.id, versionEsperada: c.versionServidor);
    await sincronizar();
  }

  /// Descarta la captura local (conflicto resuelto a favor del servidor o ya sincronizada).
  Future<void> descartar(CapturaOfflineEspacio c) => _cola.eliminar(c.id);

  @override
  Future<void> close() async {
    await _sub?.cancel();
    return super.close();
  }
}
