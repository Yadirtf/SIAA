// marcaje_local_datasource_test.dart — Pruebas unitarias de persistencia de cola offline (US-MAR-11)
import 'package:flutter_test/flutter_test.dart';
import 'package:siaa_mobile/features/marcaje/data/datasources/marcaje_local_datasource.dart';
import 'package:siaa_mobile/features/marcaje/domain/models/marcaje_request_model.dart';
import 'package:siaa_mobile/features/marcaje/domain/models/offline_marcaje_item.dart';

void main() {
  late MarcajeLocalDataSource dataSource;

  setUp(() async {
    dataSource = MarcajeLocalDataSource();
    await dataSource.limpiarCola();
  });

  tearDown(() async {
    await dataSource.limpiarCola();
  });

  test('encola marcaje y lo recupera como pendiente', () async {
    final req = MarcajeRequestModel(
      sesionId: 'ses-test-1',
      tipo: 'ENTRADA',
      latitud: 4.60,
      longitud: -74.06,
      precisionMetros: 10.0,
      timestampDispositivo: DateTime.now(),
      dispositivoId: 'dev-1',
      versionApp: '1.0.0',
    );

    final item = await dataSource.encolarMarcaje(req);

    expect(item.localId, isNotEmpty);
    expect(item.estado, equals(EstadoSincronizacion.pendiente));

    final pendientes = await dataSource.obtenerPendientes();
    expect(pendientes.length, equals(1));
    expect(pendientes.first.localId, equals(item.localId));
  });

  test('actualiza estado de marcaje tras sincronización exitosa', () async {
    final req = MarcajeRequestModel(
      sesionId: 'ses-test-2',
      tipo: 'ENTRADA',
      latitud: 4.60,
      longitud: -74.06,
      precisionMetros: 10.0,
      timestampDispositivo: DateTime.now(),
      dispositivoId: 'dev-1',
      versionApp: '1.0.0',
    );

    final item = await dataSource.encolarMarcaje(req);
    final actualizado = item.copyWith(estado: EstadoSincronizacion.sincronizado);
    await dataSource.actualizarItem(actualizado);

    final pendientes = await dataSource.obtenerPendientes();
    expect(pendientes, isEmpty);

    final todos = await dataSource.obtenerTodos();
    expect(todos.first.estado, equals(EstadoSincronizacion.sincronizado));
  });

  test('elimina item de la cola por localId', () async {
    final req = MarcajeRequestModel(
      sesionId: 'ses-test-3',
      tipo: 'SALIDA',
      latitud: 4.60,
      longitud: -74.06,
      precisionMetros: 8.0,
      timestampDispositivo: DateTime.now(),
      dispositivoId: 'dev-1',
      versionApp: '1.0.0',
    );

    final item = await dataSource.encolarMarcaje(req);
    await dataSource.eliminarItem(item.localId);

    final todos = await dataSource.obtenerTodos();
    expect(todos, isEmpty);
  });
}
