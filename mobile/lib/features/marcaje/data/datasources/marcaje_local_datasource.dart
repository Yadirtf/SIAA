// marcaje_local_datasource.dart — Persistencia de cola offline de marcajes (US-MAR-11)
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:uuid/uuid.dart';
import '../../domain/models/marcaje_request_model.dart';
import '../../domain/models/offline_marcaje_item.dart';

class MarcajeLocalDataSource {
  static const _storageKey = 'siaa_cola_marcajes_offline_v1';
  final FlutterSecureStorage _storage;
  final Uuid _uuid;

  // Fallback en memoria si SecureStorage tiene problemas en pruebas
  static final Map<String, String> _memoryCache = {};

  MarcajeLocalDataSource({
    FlutterSecureStorage? storage,
    Uuid? uuid,
  })  : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(resetOnError: true),
              iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
            ),
        _uuid = uuid ?? const Uuid();

  /// Agrega un intento de marcaje a la cola cifrada local con estado PENDIENTE
  Future<OfflineMarcajeItem> encolarMarcaje(MarcajeRequestModel request) async {
    final cola = await obtenerTodos();
    final item = OfflineMarcajeItem(
      localId: _uuid.v4(),
      request: request,
      creadoEn: DateTime.now(),
      estado: EstadoSincronizacion.pendiente,
    );

    cola.add(item);
    await _guardarLista(cola);
    return item;
  }

  /// Obtiene los elementos que aún no han sido sincronizados exitosamente
  Future<List<OfflineMarcajeItem>> obtenerPendientes() async {
    final todos = await obtenerTodos();
    return todos.where((item) => item.estado == EstadoSincronizacion.pendiente).toList();
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
      return list.map((e) => OfflineMarcajeItem.fromMap(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  /// Actualiza el estado o resultado de un item específico en la cola
  Future<void> actualizarItem(OfflineMarcajeItem itemActualizado) async {
    final todos = await obtenerTodos();
    final idx = todos.indexWhere((it) => it.localId == itemActualizado.localId);
    if (idx != -1) {
      todos[idx] = itemActualizado;
      await _guardarLista(todos);
    }
  }

  /// Elimina un item de la cola (por ejemplo tras confirmación de sincronización)
  Future<void> eliminarItem(String localId) async {
    final todos = await obtenerTodos();
    todos.removeWhere((it) => it.localId == localId);
    await _guardarLista(todos);
  }

  /// Limpia la cola completamente
  Future<void> limpiarCola() async {
    _memoryCache.remove(_storageKey);
    try {
      await _storage.delete(key: _storageKey);
    } catch (_) {}
  }

  Future<void> _guardarLista(List<OfflineMarcajeItem> items) async {
    final raw = jsonEncode(items.map((e) => e.toMap()).toList());
    _memoryCache[_storageKey] = raw;
    try {
      await _storage.write(key: _storageKey, value: raw);
    } catch (_) {}
  }
}
