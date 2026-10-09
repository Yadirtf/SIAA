// Pruebas de la cola offline de cartografía (US-GEO-10 AC-01..AC-04, RF-GEO-013).
import 'package:flutter_test/flutter_test.dart';
import 'package:siaa_mobile/core/geo/offline_cartografia_service.dart';

CapturaOfflineEspacio _captura(String id, {int version = 1, int n = 3}) =>
    CapturaOfflineEspacio(
      id: id,
      espacioId: 'esp-$id',
      espacioCodigo: 'A-$id',
      vertices: [
        for (var i = 0; i < n; i++) [-74.0650 + i * 0.0001, 4.6500],
      ],
      metodoCaptura: 'TOQUE_MAPA',
      capturadoEn: DateTime(2026, 10, 9, 8),
      versionEsperada: version,
    );

void main() {
  group('US-GEO-10: OfflineCartografiaService', () {
    late OfflineCartografiaService service;

    setUp(() => service = OfflineCartografiaService());

    test('AC-01: guarda la captura con estado pendienteSincronizacion',
        () async {
      await service.guardarCapturaOffline(_captura('1', n: 4));
      final pendientes = await service.obtenerPendientes();

      expect(pendientes.length, 1);
      expect(pendientes.first.estado,
          EstadoSincronizacion.pendienteSincronizacion);
      expect(pendientes.first.vertices.length, 4);
    });

    test('AC-01: persiste en el almacén seguro y sobrevive a un reinicio',
        () async {
      String? almacen;
      Future<String?> leer() async => almacen;
      Future<void> escribir(String v) async => almacen = v;

      await OfflineCartografiaService(leer: leer, escribir: escribir)
          .guardarCapturaOffline(_captura('p', n: 5));
      expect(almacen, contains('esp-p'));

      final reabierto =
          OfflineCartografiaService(leer: leer, escribir: escribir);
      final c = await reabierto.obtenerPorId('p');
      expect(c?.vertices.length, 5);
      expect(c?.espacioCodigo, 'A-p');
    });

    test('AC-02: sincroniza cuando hay red', () async {
      await service.guardarCapturaOffline(_captura('2'));

      final resultado = await service.sincronizarPendientes(
        isOnline: true,
        syncHandler: (c) async =>
            const EnvioCaptura(ResultadoEnvioCaptura.aceptada),
      );

      expect(resultado.sincronizados, 1);
      expect(resultado.pendientesRestantes, isEmpty);
      expect(resultado.resumen, contains('1 sincronizada'));
      expect((await service.obtenerPorId('2'))?.estado,
          EstadoSincronizacion.sincronizado);
    });

    test('sin red no envía nada y la captura sigue pendiente', () async {
      await service.guardarCapturaOffline(_captura('x'));
      var llamadas = 0;
      final sinRed = await service.sincronizarPendientes(
        isOnline: false,
        syncHandler: (c) async {
          llamadas++;
          return const EnvioCaptura(ResultadoEnvioCaptura.aceptada);
        },
      );
      final cortada = await service.sincronizarPendientes(
        isOnline: true,
        syncHandler: (c) async =>
            const EnvioCaptura(ResultadoEnvioCaptura.sinConexion),
      );
      expect(llamadas, 0);
      expect(sinRed.procesados + cortada.procesados, 0);
      expect((await service.obtenerPendientes()).length, 1);
    });

    test('AC-03: rechazo del servidor conserva los vértices para corrección',
        () async {
      await service.guardarCapturaOffline(_captura('3'));

      final resultado = await service.sincronizarPendientes(
        isOnline: true,
        syncHandler: (c) async => const EnvioCaptura(
            ResultadoEnvioCaptura.rechazada,
            mensaje: 'GEOMETRIA_INVALIDA: polígono autointersecante'),
      );

      expect(resultado.erroresValidacion, 1);
      final guardado = await service.obtenerPorId('3');
      expect(guardado?.estado, EstadoSincronizacion.errorValidacion);
      expect(guardado?.vertices.length, 3,
          reason: 'Los vértices no deben perderse');
      expect(guardado?.mensajeError, contains('GEOMETRIA_INVALIDA'));
    });

    test(
        'AC-04: conflicto queda para decisión del usuario y puede reintentarse',
        () async {
      await service.guardarCapturaOffline(_captura('4'));

      final resultado = await service.sincronizarPendientes(
        isOnline: true,
        syncHandler: (c) async => const EnvioCaptura(
            ResultadoEnvioCaptura.conflicto,
            versionServidor: 2),
      );

      expect(resultado.conflictos, 1);
      final guardado = await service.obtenerPorId('4');
      expect(guardado?.estado, EstadoSincronizacion.conflicto);
      expect(guardado?.versionServidor, 2);
      expect(guardado?.mensajeError, contains('Conflicto'));

      await service.reintentar('4', versionEsperada: 2);
      final reintento = await service.obtenerPorId('4');
      expect(reintento?.estado, EstadoSincronizacion.pendienteSincronizacion);
      expect(reintento?.versionEsperada, 2);
    });
  });
}
