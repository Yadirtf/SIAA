// Servicio de almacenamiento y sincronización offline de cartografía.
// Satisface US-GEO-10 (AC-01..AC-04) y RF-GEO-013.
// Las capturas se guardan cifradas en el almacenamiento seguro del sistema
// (Keystore en Android, Keychain en iOS) y sobreviven al cierre de la app.
import 'dart:async';
import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'captura_offline_espacio.dart';

export 'captura_offline_espacio.dart';

class OfflineCartografiaService {
  static const _clave = 'siaa_cartografia_offline';

  /// Instancia compartida por el editor, la lista de pendientes y el disparador.
  static final OfflineCartografiaService instancia = OfflineCartografiaService(
    leer: () => const FlutterSecureStorage().read(key: _clave),
    escribir: (v) => const FlutterSecureStorage().write(key: _clave, value: v),
  );

  final Future<String?> Function()? _leer;
  final Future<void> Function(String valor)? _escribir;
  Map<String, CapturaOfflineEspacio>? _cache;
  bool _sincronizando = false;
  final _cambios = StreamController<void>.broadcast();

  /// Sin funciones de lectura/escritura solo se conserva en memoria (pruebas).
  OfflineCartografiaService({
    Future<String?> Function()? leer,
    Future<void> Function(String valor)? escribir,
  })  : _leer = leer,
        _escribir = escribir;

  /// Emite cada vez que la cola cambia (para refrescar la lista de pendientes).
  Stream<void> get cambios => _cambios.stream;

  Future<Map<String, CapturaOfflineEspacio>> _almacen() async {
    final cache = _cache;
    if (cache != null) return cache;
    final cargado = <String, CapturaOfflineEspacio>{};
    try {
      final crudo = await _leer?.call();
      if (crudo != null && crudo.isNotEmpty) {
        for (final item in jsonDecode(crudo) as List<dynamic>) {
          final c =
              CapturaOfflineEspacio.fromJson(item as Map<String, dynamic>);
          cargado[c.id] = c;
        }
      }
    } catch (_) {
      // Almacén ilegible: se parte de una cola vacía en lugar de bloquear el editor.
    }
    return _cache = cargado;
  }

  Future<void> _persistir() async {
    final datos = jsonEncode(_cache!.values.map((c) => c.toJson()).toList());
    await _escribir?.call(datos);
    if (!_cambios.isClosed) _cambios.add(null);
  }

  // AC-01: Guarda la geometría localmente con estado PENDIENTE_SINCRONIZACION
  Future<void> guardarCapturaOffline(CapturaOfflineEspacio captura) async {
    captura.estado = EstadoSincronizacion.pendienteSincronizacion;
    (await _almacen())[captura.id] = captura;
    await _persistir();
  }

  Future<List<CapturaOfflineEspacio>> obtenerTodas() async {
    final lista = (await _almacen()).values.toList()
      ..sort((a, b) => b.capturadoEn.compareTo(a.capturadoEn));
    return lista;
  }

  Future<List<CapturaOfflineEspacio>> obtenerPendientes() async {
    return (await obtenerTodas())
        .where((c) => c.estado == EstadoSincronizacion.pendienteSincronizacion)
        .toList();
  }

  Future<CapturaOfflineEspacio?> obtenerPorId(String id) async {
    return (await _almacen())[id];
  }

  Future<void> eliminar(String id) async {
    if ((await _almacen()).remove(id) != null) await _persistir();
  }

  /// AC-04: el usuario decide mantener su captura; se reenvía aceptando la versión
  /// que hoy tiene el servidor como punto de partida.
  Future<void> reintentar(String id, {int? versionEsperada}) async {
    final c = (await _almacen())[id];
    if (c == null) return;
    c.estado = EstadoSincronizacion.pendienteSincronizacion;
    c.mensajeError = null;
    if (versionEsperada != null) c.versionEsperada = versionEsperada;
    await _persistir();
  }

  // AC-02, AC-03, AC-04: Sincroniza las geometrías pendientes cuando hay conexión.
  Future<ResultadoSincronizacion> sincronizarPendientes({
    required bool isOnline,
    required Future<EnvioCaptura> Function(CapturaOfflineEspacio captura)
        syncHandler,
  }) async {
    var sincOk = 0, errVal = 0, conf = 0;
    if (isOnline && !_sincronizando) {
      _sincronizando = true;
      try {
        for (final captura in await obtenerPendientes()) {
          EnvioCaptura envio;
          try {
            envio = await syncHandler(captura);
          } catch (e) {
            // Fallo inesperado: la captura sigue pendiente, sin perder vértices.
            envio = EnvioCaptura(ResultadoEnvioCaptura.sinConexion,
                mensaje: e.toString());
          }
          // Sin red a mitad de la cola: sigue pendiente para el próximo disparo.
          if (envio.resultado == ResultadoEnvioCaptura.sinConexion) continue;
          switch (envio.resultado) {
            case ResultadoEnvioCaptura.aceptada:
              captura.estado = EstadoSincronizacion.sincronizado;
              captura.mensajeError = null;
              sincOk++;
            case ResultadoEnvioCaptura.conflicto:
              captura.estado = EstadoSincronizacion.conflicto;
              captura.versionServidor = envio.versionServidor;
              captura.mensajeError =
                  'Conflicto: el espacio fue modificado en el '
                  'servidor (versión ${envio.versionServidor}) después de su captura.';
              conf++;
            case ResultadoEnvioCaptura.rechazada:
              // AC-03: queda accesible para corrección, sin pérdida de vértices.
              captura.estado = EstadoSincronizacion.errorValidacion;
              captura.mensajeError = envio.mensaje;
              errVal++;
            case ResultadoEnvioCaptura.sinConexion:
              break;
          }
          await _persistir();
        }
      } finally {
        _sincronizando = false;
      }
    }
    final restantes = (await obtenerTodas())
        .where((c) => c.estado != EstadoSincronizacion.sincronizado)
        .toList();
    return ResultadoSincronizacion(
      sincronizados: sincOk,
      erroresValidacion: errVal,
      conflictos: conf,
      pendientesRestantes: restantes,
    );
  }
}
