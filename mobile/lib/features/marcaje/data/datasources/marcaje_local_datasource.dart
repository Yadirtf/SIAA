// marcaje_local_datasource.dart — Persistencia de cola offline de marcajes (US-MAR-11)
import 'dart:async';
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:uuid/uuid.dart';
import '../../domain/models/marcaje_request_model.dart';
import '../../domain/models/offline_marcaje_item.dart';

class MarcajeLocalDataSource {
  static const _storageKey = 'siaa_cola_marcajes_offline_v1';

  /// Antigüedad a partir de la cual se eliminan los marcajes ya aceptados.
  static const retencionAceptados = Duration(days: 7);

  final FlutterSecureStorage _storage;
  final Uuid _uuid;

  // Fallback en memoria si SecureStorage tiene problemas en pruebas
  static final Map<String, String> _memoryCache = {};

  // Serializa las operaciones leer-modificar-escribir sobre la cola compartida.
  static Future<void> _cerrojo = Future.value();

  MarcajeLocalDataSource({
    FlutterSecureStorage? storage,
    Uuid? uuid,
  })  : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(resetOnError: true),
              iOptions:
                  IOSOptions(accessibility: KeychainAccessibility.first_unlock),
            ),
        _uuid = uuid ?? const Uuid();

  /// Agrega un intento de marcaje a la cola cifrada local con estado PENDIENTE
  Future<OfflineMarcajeItem> encolarMarcaje(
    MarcajeRequestModel request, {
    bool exigirAttestation = false,
  }) {
    return _exclusivo(() async {
      final cola = await obtenerTodos();
      final item = OfflineMarcajeItem(
        localId: _uuid.v4(),
        request: request,
        creadoEn: DateTime.now(),
        estado: EstadoSincronizacion.pendiente,
        exigirAttestation: exigirAttestation,
      );
      cola.add(item);
      await _guardarLista(cola);
      return item;
    });
  }

  /// Obtiene los elementos que aún no han sido sincronizados (incluye los en espera de backoff)
  Future<List<OfflineMarcajeItem>> obtenerPendientes() async {
    final todos = await obtenerTodos();
    return todos
        .where((item) => item.estado == EstadoSincronizacion.pendiente)
        .toList();
  }

  /// Elementos pendientes cuyo backoff ya venció en [ahora].
  Future<List<OfflineMarcajeItem>> obtenerSincronizables(DateTime ahora) async {
    final todos = await obtenerTodos();
    return todos.where((item) => item.esSincronizable(ahora)).toList();
  }

  /// Obtiene todos los marcajes en la cola local
  Future<List<OfflineMarcajeItem>> obtenerTodos() async {
    String? raw;
    if (_memoryCache.containsKey(_storageKey)) {
      raw = _memoryCache[_storageKey];
    } else {
      try {
        raw = await _storage.read(key: _storageKey);
        if (raw != null) _memoryCache[_storageKey] = raw;
      } catch (_) {
        raw = _memoryCache[_storageKey];
      }
    }

    if (raw == null || raw.isEmpty) {
      return [];
    }

    try {
      final List<dynamic> list = jsonDecode(raw) as List<dynamic>;
      final items = <OfflineMarcajeItem>[];
      for (final e in list) {
        try {
          items.add(OfflineMarcajeItem.fromMap(e as Map<String, dynamic>));
        } catch (_) {
          // Un item corrupto no debe impedir leer el resto de la cola.
        }
      }
      return items;
    } catch (_) {
      return [];
    }
  }

  /// Actualiza el estado o resultado de un item específico en la cola
  Future<void> actualizarItem(OfflineMarcajeItem itemActualizado) {
    return actualizarItems([itemActualizado]);
  }

  /// Reemplaza por localId varios items en una sola escritura.
  Future<void> actualizarItems(List<OfflineMarcajeItem> actualizados) {
    if (actualizados.isEmpty) return Future.value();
    final porId = {for (final it in actualizados) it.localId: it};
    return _exclusivo(() async {
      final todos = await obtenerTodos();
      final nuevos = todos.map((it) => porId[it.localId] ?? it).toList();
      await _guardarLista(nuevos);
    });
  }

  /// Elimina los aceptados más antiguos que [retencion] (por fecha de sincronización).
  Future<int> podarSincronizados(
    DateTime ahora, {
    Duration retencion = retencionAceptados,
  }) {
    return _exclusivo(() async {
      final todos = await obtenerTodos();
      final limite = ahora.subtract(retencion);
      final conservados = todos.where((it) {
        if (it.estado != EstadoSincronizacion.sincronizado) return true;
        final referencia = it.sincronizadoEn ?? it.creadoEn;
        return referencia.isAfter(limite);
      }).toList();
      final eliminados = todos.length - conservados.length;
      if (eliminados > 0) await _guardarLista(conservados);
      return eliminados;
    });
  }

  /// Elimina un item de la cola (por ejemplo tras confirmación de sincronización)
  Future<void> eliminarItem(String localId) {
    return _exclusivo(() async {
      final todos = await obtenerTodos();
      todos.removeWhere((it) => it.localId == localId);
      await _guardarLista(todos);
    });
  }

  /// Limpia la cola completamente
  Future<void> limpiarCola() {
    return _exclusivo(() async {
      _memoryCache.remove(_storageKey);
      try {
        await _storage.delete(key: _storageKey);
      } catch (_) {}
    });
  }

  Future<T> _exclusivo<T>(Future<T> Function() operacion) {
    final resultado = _cerrojo.then((_) => operacion());
    _cerrojo = resultado.then((_) {}, onError: (_) {});
    return resultado;
  }

  Future<void> _guardarLista(List<OfflineMarcajeItem> items) async {
    final raw = jsonEncode(items.map((e) => e.toMap()).toList());
    _memoryCache[_storageKey] = raw;
    try {
      await _storage.write(key: _storageKey, value: raw);
    } catch (_) {}
  }
}
