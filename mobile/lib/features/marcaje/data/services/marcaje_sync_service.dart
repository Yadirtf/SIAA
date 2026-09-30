// marcaje_sync_service.dart — Sincronización por lotes de la cola offline (US-MAR-11)
// Usa POST /marcajes/sync (origen OFFLINE, evaluado con timestampDispositivo) en lotes
// de ≤ 50, mapea resultados por orden y aplica backoff exponencial por item.
import 'dart:async';
import 'package:dio/dio.dart';
import '../../../privacidad/data/consentimiento_gate.dart';
import '../../../privacidad/data/consentimiento_requerido.dart';
import '../../domain/models/item_sync_resultado_model.dart';
import '../../domain/models/marcaje_request_model.dart';
import '../../domain/models/offline_marcaje_item.dart';
import '../../domain/models/resumen_sincronizacion.dart';
import '../datasources/marcaje_local_datasource.dart';
import '../datasources/marcaje_remote_datasource.dart';
import 'attestation_service.dart';
import 'politica_reintentos.dart';

class MarcajeSyncService {
  // Compartidos por todas las instancias: la cola persistida es única en el dispositivo.
  static Future<ResumenSincronizacion>? _enCurso;
  static final _cambios = StreamController<ResumenSincronizacion>.broadcast();

  /// Emite tras cada ejecución que modificó la cola (para refrescar la UI).
  static Stream<ResumenSincronizacion> get actualizaciones => _cambios.stream;

  final MarcajeRemoteDataSource _remote;
  final MarcajeLocalDataSource _local;
  final AttestationService _attestation;
  final PoliticaReintentos _politica;
  final DateTime Function() _reloj;
  final Future<void> Function() _onConsentimientoRequerido;

  MarcajeSyncService({
    required MarcajeRemoteDataSource remote,
    required MarcajeLocalDataSource local,
    AttestationService? attestation,
    PoliticaReintentos politica = const PoliticaReintentos(),
    DateTime Function()? reloj,
    Future<void> Function()? onConsentimientoRequerido,
  })  : _remote = remote,
        _local = local,
        _attestation = attestation ?? AttestationService(),
        _politica = politica,
        _reloj = reloj ?? DateTime.now,
        _onConsentimientoRequerido = onConsentimientoRequerido ??
            ConsentimientoGate.instance.marcarRequerido;

  /// Ejecuta una sincronización; si ya hay una en curso devuelve esa misma.
  Future<ResumenSincronizacion> sincronizar() {
    final actual = _enCurso;
    if (actual != null) return actual;
    final nueva = _ejecutar().whenComplete(() => _enCurso = null);
    _enCurso = nueva;
    return nueva;
  }

  /// Notifica a la UI un cambio de la cola hecho fuera de una sincronización.
  static void notificarCambio() => _cambios.add(ResumenSincronizacion.vacio);

  Future<ResumenSincronizacion> _ejecutar() async {
    final ahora = _reloj();
    final podados = await _local.podarSincronizados(ahora);
    final items = await _local.obtenerSincronizables(ahora);
    var resumen = ResumenSincronizacion.vacio;

    const tam = MarcajeRemoteDataSource.maxItemsPorLote;
    for (var i = 0; i < items.length; i += tam) {
      final lote =
          items.sublist(i, i + tam > items.length ? items.length : i + tam);
      final resultado = await _procesarLote(lote);
      resumen += resultado.resumen;
      if (!resultado.continuar) break;
    }

    if (podados > 0 || items.isNotEmpty) _cambios.add(resumen);
    return resumen;
  }

  Future<_ResultadoLote> _procesarLote(List<OfflineMarcajeItem> lote) async {
    final requests = <MarcajeRequestModel>[];
    for (final item in lote) {
      requests.add(await _prepararRequest(item));
    }

    List<ItemSyncResultadoModel> resultados;
    try {
      resultados = await _remote.sincronizarLote(requests);
    } on DioException catch (e) {
      return _aplicarErrorLote(lote, e);
    } catch (e) {
      return _reprogramarTodos(
          lote, 'Error inesperado al sincronizar: $e', false);
    }

    final ahora = _reloj();
    final actualizados = <OfflineMarcajeItem>[];
    var resumen = ResumenSincronizacion.vacio;
    for (var i = 0; i < lote.length; i++) {
      final item = lote[i];
      final r = i < resultados.length ? resultados[i] : null;
      final coincide = r != null &&
          (r.sesionId.isEmpty || r.sesionId == item.request.sesionId);
      if (r == null || !coincide || r.esErrorReintentable) {
        final msg =
            r?.error ?? 'El servidor no devolvió resultado para este marcaje';
        final nuevo = _politica.registrarFallo(item, msg, ahora);
        actualizados.add(nuevo);
        resumen += _contar(nuevo);
        continue;
      }
      final nuevo = item.copyWith(
        estado: r.exitoso
            ? EstadoSincronizacion.sincronizado
            : EstadoSincronizacion.rechazado,
        resultadoServidor: r.aResultado(),
        requiereRevision: r.requiereRevision,
        sincronizadoEn: ahora,
        limpiarError: true,
        limpiarProximoIntento: true,
      );
      actualizados.add(nuevo);
      resumen += _contar(nuevo);
    }
    await _local.actualizarItems(actualizados);
    return _ResultadoLote(resumen, true);
  }

  /// Token fresco al sincronizar: los tokens caducan (10 min) y el hash usa la idempotencyKey.
  Future<MarcajeRequestModel> _prepararRequest(OfflineMarcajeItem item) async {
    final req = item.request;
    String? token;
    if (item.exigirAttestation) {
      token = await _attestation.obtenerToken(
        sesionId: req.sesionId,
        tipo: req.tipo,
        idempotencyKey: req.idempotencyKey,
      );
    }
    return req.conIntegridad(req.integridad.conToken(token));
  }

  Future<_ResultadoLote> _aplicarErrorLote(
    List<OfflineMarcajeItem> lote,
    DioException e,
  ) async {
    final status = e.response?.statusCode;
    if (status == null) {
      // Sin respuesta (red caída, timeout): los lotes restantes también fallarían.
      return _reprogramarTodos(lote, 'Sin conexión con el servidor', false);
    }
    if (status == 403 && ConsentimientoRequeridoException.esRespuesta(e)) {
      // US-LEG-01: la cola queda intacta (sin contar intento) hasta aceptar el aviso.
      await _onConsentimientoRequerido();
      return const _ResultadoLote(ResumenSincronizacion.vacio, false);
    }
    if (status == 401) {
      // Sesión expirada y no renovable: se deja la cola intacta hasta volver a autenticar.
      return const _ResultadoLote(ResumenSincronizacion.vacio, false);
    }
    if (status >= 500 || status == 408 || status == 429) {
      return _reprogramarTodos(
          lote, 'Error temporal del servidor ($status)', true);
    }
    final msg = _mensajeServidor(e) ?? 'El servidor rechazó el lote ($status)';
    final actualizados =
        lote.map((it) => _politica.registrarFalloDefinitivo(it, msg)).toList();
    await _local.actualizarItems(actualizados);
    return _ResultadoLote(ResumenSincronizacion(fallidos: lote.length), true);
  }

  Future<_ResultadoLote> _reprogramarTodos(
    List<OfflineMarcajeItem> lote,
    String mensaje,
    bool continuar,
  ) async {
    final ahora = _reloj();
    final actualizados =
        lote.map((it) => _politica.registrarFallo(it, mensaje, ahora)).toList();
    await _local.actualizarItems(actualizados);
    return _ResultadoLote(
      actualizados.fold(
          ResumenSincronizacion.vacio, (a, it) => a + _contar(it)),
      continuar,
    );
  }

  ResumenSincronizacion _contar(OfflineMarcajeItem it) {
    switch (it.estado) {
      case EstadoSincronizacion.sincronizado:
        return const ResumenSincronizacion(aceptados: 1);
      case EstadoSincronizacion.rechazado:
        return const ResumenSincronizacion(rechazados: 1);
      case EstadoSincronizacion.pendiente:
        return const ResumenSincronizacion(reprogramados: 1);
      case EstadoSincronizacion.fallido:
        return const ResumenSincronizacion(fallidos: 1);
    }
  }

  String? _mensajeServidor(DioException e) {
    final data = e.response?.data;
    if (data is Map) {
      final m = data['mensaje'] ?? data['message'] ?? data['error'];
      if (m is String && m.isNotEmpty) return m;
    }
    return null;
  }
}

class _ResultadoLote {
  final ResumenSincronizacion resumen;
  final bool continuar;

  const _ResultadoLote(this.resumen, this.continuar);
}
