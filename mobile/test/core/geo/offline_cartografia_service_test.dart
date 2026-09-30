import 'package:flutter_test/flutter_test.dart';
import 'package:siaa_mobile/core/geo/offline_cartografia_service.dart';

void main() {
  group('US-GEO-10: OfflineCartografiaService', () {
    late OfflineCartografiaService service;

    setUp(() {
      service = OfflineCartografiaService();
    });

    test('AC-01: Guardar captura offline con estado pendienteSincronizacion', () async {
      final captura = CapturaOfflineEspacio(
        id: 'cap-1',
        espacioId: 'esp-101',
        vertices: [
          [-74.0650, 4.6500],
          [-74.0649, 4.6500],
          [-74.0649, 4.6501],
          [-74.0650, 4.6501],
        ],
        metodoCaptura: 'RECORRIDO_PERIMETRAL',
        capturadoEn: DateTime.now(),
      );

      await service.guardarCapturaOffline(captura);
      final pendientes = await service.obtenerPendientes();

      expect(pendientes.length, 1);
      expect(pendientes.first.estado, EstadoSincronizacion.pendienteSincronizacion);
      expect(pendientes.first.vertices.length, 4);
    });

    test('AC-02: Sincronizar automáticamente cuando hay red', () async {
      final captura = CapturaOfflineEspacio(
        id: 'cap-2',
        espacioId: 'esp-102',
        vertices: [
          [-74.0650, 4.6500],
          [-74.0649, 4.6500],
          [-74.0649, 4.6501],
        ],
        metodoCaptura: 'TOQUE_MAPA',
        capturadoEn: DateTime.now(),
        versionEsperada: 1,
      );
      await service.guardarCapturaOffline(captura);

      final resultado = await service.sincronizarPendientes(
        isOnline: true,
        syncHandler: (c) async => 1, // Servidor acepta versión 1
      );

      expect(resultado.sincronizados, 1);
      expect(resultado.pendientesRestantes.length, 0);

      final guardado = await service.obtenerPorId('cap-2');
      expect(guardado?.estado, EstadoSincronizacion.sincronizado);
    });

    test('AC-03: Conservar vértices intactos ante fallo de validación del servidor', () async {
      final captura = CapturaOfflineEspacio(
        id: 'cap-3',
        espacioId: 'esp-103',
        vertices: [
          [-74.0650, 4.6500],
          [-74.0649, 4.6500],
          [-74.0649, 4.6501],
        ],
        metodoCaptura: 'TOQUE_MAPA',
        capturadoEn: DateTime.now(),
      );
      await service.guardarCapturaOffline(captura);

      final resultado = await service.sincronizarPendientes(
        isOnline: true,
        syncHandler: (c) async => throw Exception('GEOMETRIA_INVALIDA: polígono autointersecante'),
      );

      expect(resultado.erroresValidacion, 1);
      expect(resultado.sincronizados, 0);

      final guardado = await service.obtenerPorId('cap-3');
      expect(guardado?.estado, EstadoSincronizacion.errorValidacion);
      expect(guardado?.vertices.length, 3, reason: 'Los vértices no deben perderse');
      expect(guardado?.mensajeError, contains('GEOMETRIA_INVALIDA'));
    });

    test('AC-04: Detectar conflicto si el espacio fue modificado en el servidor', () async {
      final captura = CapturaOfflineEspacio(
        id: 'cap-4',
        espacioId: 'esp-104',
        vertices: [
          [-74.0650, 4.6500],
          [-74.0649, 4.6500],
          [-74.0649, 4.6501],
        ],
        metodoCaptura: 'TOQUE_MAPA',
        capturadoEn: DateTime.now(),
        versionEsperada: 1,
      );
      await service.guardarCapturaOffline(captura);

      final resultado = await service.sincronizarPendientes(
        isOnline: true,
        syncHandler: (c) async => 2, // Servidor ya está en versión 2
      );

      expect(resultado.conflictos, 1);
      expect(resultado.sincronizados, 0);

      final guardado = await service.obtenerPorId('cap-4');
      expect(guardado?.estado, EstadoSincronizacion.conflicto);
      expect(guardado?.mensajeError, contains('Conflicto'));
    });
  });
}
