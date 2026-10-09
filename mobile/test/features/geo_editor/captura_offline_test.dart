// captura_offline_test.dart — Cableado de la captura offline de cartografía (US-GEO-10)
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:siaa_mobile/core/geo/offline_cartografia_service.dart';
import 'package:siaa_mobile/features/geo_editor/data/cartografia_sync_service.dart';
import 'package:siaa_mobile/features/geo_editor/data/espacio_repository.dart';
import 'package:siaa_mobile/features/geo_editor/presentation/bloc/geo_editor_bloc.dart';
import 'package:siaa_mobile/features/geo_editor/presentation/bloc/geo_editor_event.dart';
import 'package:siaa_mobile/features/geo_editor/presentation/bloc/geo_editor_state.dart';
import 'package:siaa_mobile/features/geo_editor/presentation/screens/capturas_pendientes_screen.dart';

class _RepoFake extends EspacioRepository {
  int versionServidor = 1;
  Object? errorAlGuardar;
  final guardadas = <List<List<double>>>[];

  _RepoFake() : super(client: Dio());

  @override
  Future<EspacioModel> obtenerEspacioPorId(String id) async => EspacioModel(
        id: id,
        sedeId: 's-1',
        codigo: 'A-101',
        nombre: 'Aula 101',
        capacidad: 30,
        tipo: 'AULA',
        estado: 'ACTIVO',
        nivelValidacion: 'AULA',
        bufferMetros: 10,
        areaMetrosCuadrados: 0,
        tieneGeometria: true,
        versionGeometria: versionServidor,
      );

  @override
  Future<EspacioModel> guardarGeometria({
    required String espacioId,
    required List<List<double>> coordenadas,
    required String metodoCaptura,
    double? precisionPromedioMetros,
    bool confirmarSolapamiento = false,
    String? motivoSolapamiento,
  }) async {
    if (errorAlGuardar != null) throw errorAlGuardar!;
    guardadas.add(coordenadas);
    return obtenerEspacioPorId(espacioId);
  }
}

CapturaOfflineEspacio _captura({int version = 1}) => CapturaOfflineEspacio(
      id: 'c-1',
      espacioId: 'esp-1',
      espacioCodigo: 'A-101',
      espacioNombre: 'Aula 101',
      vertices: const [
        [-74.0, 4.6],
        [-73.9999, 4.6],
        [-73.9999, 4.6001],
        [-74.0, 4.6],
      ],
      metodoCaptura: 'TOQUE_MAPA',
      capturadoEn: DateTime(2026, 10, 9, 8),
      versionEsperada: version,
    );

void main() {
  group('CartografiaSyncService', () {
    late _RepoFake repo;
    late OfflineCartografiaService cola;
    late CartografiaSyncService sync;

    setUp(() {
      repo = _RepoFake();
      cola = OfflineCartografiaService();
      sync = CartografiaSyncService(cola: cola, repositorio: repo);
    });

    test('envía la captura si el servidor sigue en la versión capturada',
        () async {
      await cola.guardarCapturaOffline(_captura());
      final r = await sync.sincronizar();
      expect(r.sincronizados, 1);
      expect(repo.guardadas.single.length, 4);
    });

    test('AC-04: versión mayor en el servidor es conflicto y no se envía',
        () async {
      repo.versionServidor = 3;
      await cola.guardarCapturaOffline(_captura());
      final r = await sync.sincronizar();
      expect(r.conflictos, 1);
      expect(repo.guardadas, isEmpty,
          reason: 'nunca se sobrescribe en silencio');
      expect((await cola.obtenerPorId('c-1'))?.versionServidor, 3);
    });

    test('AC-03: rechazo de validación y corte de red', () async {
      await cola.guardarCapturaOffline(_captura());
      repo.errorAlGuardar = SinConexionGeometriaException();
      expect((await sync.sincronizar()).procesados, 0);
      expect((await cola.obtenerPendientes()).length, 1);

      repo.errorAlGuardar = Exception('El polígono se autointersecta');
      final r = await sync.sincronizar();
      expect(r.erroresValidacion, 1);
      final c = await cola.obtenerPorId('c-1');
      expect(c?.mensajeError, 'El polígono se autointersecta');
      expect(c?.vertices.length, 4);
    });
  });

  group('GeoEditorBloc', () {
    Future<GeoEditorBloc> cerrado({
      required bool red,
      required List<String> llamadas,
      Object? errorEnLinea,
    }) async {
      final bloc = GeoEditorBloc(
        hayConexion: () async => red,
        onSaveGeometry: ({
          required espacioId,
          required coordenadas,
          required metodoCaptura,
          precisionPromedioMetros,
          confirmarSolapamiento = false,
          motivoSolapamiento,
        }) async {
          llamadas.add('linea');
          if (errorEnLinea != null) throw errorEnLinea;
        },
        onSaveOffline: ({
          required espacioId,
          required coordenadas,
          required metodoCaptura,
          precisionPromedioMetros,
        }) async =>
            llamadas.add('offline:$espacioId:${coordenadas.length}'),
      );
      bloc.add(CargarGeometriaExistenteRequested(_captura().vertices));
      await bloc.stream.firstWhere((s) => s.isClosed);
      return bloc;
    }

    test('AC-01: sin red guarda en el dispositivo sin intentar el envío',
        () async {
      final llamadas = <String>[];
      final bloc = await cerrado(red: false, llamadas: llamadas);
      addTearDown(bloc.close);
      bloc.add(const GuardarGeometriaBackendRequested(espacioId: 'esp-1'));
      final s = await bloc.stream
          .firstWhere((s) => s.status == GeoEditorStatus.success);
      expect(llamadas, ['offline:esp-1:4']);
      expect(s.successMessage, contains('guardada en el dispositivo'));
    });

    test('si la red cae durante el envío, también se guarda localmente',
        () async {
      final llamadas = <String>[];
      final bloc = await cerrado(
          red: true,
          llamadas: llamadas,
          errorEnLinea: SinConexionGeometriaException());
      addTearDown(bloc.close);
      bloc.add(const GuardarGeometriaBackendRequested(espacioId: 'esp-1'));
      await bloc.stream.firstWhere((s) => s.status == GeoEditorStatus.success);
      expect(llamadas, ['linea', 'offline:esp-1:4']);
    });
  });

  testWidgets('AC-04: el usuario decide reemplazar con su captura',
      (tester) async {
    final repo = _RepoFake()..versionServidor = 2;
    final cola = OfflineCartografiaService();
    await tester.runAsync(() async {
      await cola.guardarCapturaOffline(_captura());
      await CartografiaSyncService(cola: cola, repositorio: repo).sincronizar();
    });

    await tester.pumpWidget(MaterialApp(
      home: CapturasPendientesScreen(cola: cola, repositorio: repo),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Resolver conflicto'), findsOneWidget);

    await tester.tap(find.text('Resolver conflicto'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Reemplazar con la mía'));
    await tester.pumpAndSettle();

    expect(repo.guardadas.length, 1);
    expect(find.text('Quitar de la lista'), findsOneWidget);
  });
}
