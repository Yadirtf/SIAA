// marcaje_sync_trigger.dart — Disparadores de sincronización de la cola offline (US-MAR-11)
// Sincroniza al arrancar, al recuperar conectividad, al volver la app a primer plano y
// periódicamente mientras está en primer plano (para atender los reintentos con backoff).
// La exclusión mutua la garantiza MarcajeSyncService: nunca corren dos sincronizaciones.
// Los disparos que ocurren a la vez en muchos dispositivos (red recuperada, periódico)
// esperan un jitter aleatorio antes de llamar al servidor (US-PLT-05 AC-05, R-05).
import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/widgets.dart';

class MarcajeSyncTrigger {
  final Future<void> Function() _sincronizar;
  final Future<bool> Function() _haySesion;
  final Stream<List<ConnectivityResult>> _conectividad;
  final Duration periodo;

  /// Espera aleatoria previa a los disparos masivos; null = sin espera.
  final Future<void> Function()? _esperarJitter;

  StreamSubscription<List<ConnectivityResult>>? _suscripcion;
  AppLifecycleListener? _ciclo;
  Timer? _temporizador;

  MarcajeSyncTrigger({
    required Future<void> Function() sincronizar,
    required Future<bool> Function() haySesion,
    Stream<List<ConnectivityResult>>? conectividad,
    this.periodo = const Duration(minutes: 1),
    Future<void> Function()? esperarJitter,
  })  : _sincronizar = sincronizar,
        _esperarJitter = esperarJitter,
        _haySesion = haySesion,
        _conectividad = conectividad ?? Connectivity().onConnectivityChanged;

  void iniciar({bool escucharCicloDeVida = true}) {
    detener();
    _suscripcion = _conectividad.listen((resultados) {
      if (resultados.any((r) => r != ConnectivityResult.none)) {
        disparar(conJitter: true);
      }
    });
    if (escucharCicloDeVida) {
      _ciclo = AppLifecycleListener(
        onResume: () {
          disparar();
          _programarPeriodico();
        },
        onPause: _cancelarPeriodico,
      );
    }
    _programarPeriodico();
    disparar();
  }

  /// Lanza una sincronización si hay sesión iniciada; los errores se absorben.
  /// Con [conJitter] espera primero el desfase aleatorio configurado.
  Future<void> disparar({bool conJitter = false}) async {
    try {
      if (conJitter) await _esperarJitter?.call();
      if (!await _haySesion()) return;
      await _sincronizar();
    } catch (_) {
      // La cola conserva el estado; el próximo disparador lo reintentará.
    }
  }

  void _programarPeriodico() {
    _cancelarPeriodico();
    _temporizador = Timer.periodic(periodo, (_) => disparar(conJitter: true));
  }

  void _cancelarPeriodico() {
    _temporizador?.cancel();
    _temporizador = null;
  }

  void detener() {
    _suscripcion?.cancel();
    _suscripcion = null;
    _ciclo?.dispose();
    _ciclo = null;
    _cancelarPeriodico();
  }
}
