// teselas_offline_cubit_test.dart — Aviso sin conexión y descarga de zona (US-GEO-03 AC-04)
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:siaa_mobile/features/geo_editor/data/teselas/repositorio_teselas.dart';
import 'package:siaa_mobile/features/geo_editor/domain/models/capa_mapa.dart';
import 'package:siaa_mobile/features/geo_editor/domain/models/clave_tesela.dart';
import 'package:siaa_mobile/features/geo_editor/domain/services/teselas_area.dart';
import 'package:siaa_mobile/features/geo_editor/presentation/cubit/teselas_offline_cubit.dart';
import 'package:siaa_mobile/features/geo_editor/presentation/cubit/teselas_offline_state.dart';
import 'package:siaa_mobile/features/geo_editor/presentation/widgets/map/aviso_teselas_offline.dart';
import 'package:siaa_mobile/features/geo_editor/presentation/widgets/map/tesela_cache_provider.dart';

import 'fakes_teselas.dart';

const area =
    AreaGeo(sur: 4.6360, oeste: -74.0848, norte: 4.6372, este: -74.0836);
const capa = CapaMapa.esriSatelite;

void main() {
  late AlmacenMemoria almacen;
  late ClienteFalso cliente;
  late bool enLinea;
  late TeselasOfflineCubit cubit;

  setUp(() {
    almacen = AlmacenMemoria();
    cliente = ClienteFalso();
    enLinea = true;
    cubit = TeselasOfflineCubit(
      repositorio: RepositorioTeselas(almacen: almacen, cliente: cliente),
      hayConexion: () async => enLinea,
      espera: Duration.zero,
    );
  });

  tearDown(() => cubit.close());

  Future<void> guardarVisibles({int? solo}) async {
    final z = TeselasOfflineCubit.zoomNativo(capa, 18.4);
    var claves = TeselasArea.enArea(capa.name, area, z, z).toList();
    if (solo != null) claves = claves.take(solo).toList();
    for (final c in claves) {
      await almacen.guardar(c, Uint8List.fromList([1]));
    }
  }

  test('en línea no muestra aviso', () async {
    await cubit.evaluar(capa, area, 18.4);
    expect(cubit.state.enLinea, isTrue);
    expect(AvisoTeselasOffline.textoAviso(cubit.state), isNull);
  });

  test('sin conexión y sin caché informa la limitación', () async {
    enLinea = false;
    await cubit.evaluar(capa, area, 18.4);
    expect(cubit.state.cobertura, CoberturaTeselas.ninguna);
    expect(AvisoTeselasOffline.textoAviso(cubit.state),
        contains('sin teselas guardadas'));
  });

  test('sin conexión con la zona guardada usa la caché', () async {
    await guardarVisibles();
    enLinea = false;
    await cubit.evaluar(capa, area, 18.4);
    expect(cubit.state.cobertura, CoberturaTeselas.completa);
    expect(AvisoTeselasOffline.textoAviso(cubit.state),
        contains('teselas guardadas'));
  });

  test('cobertura parcial', () async {
    await guardarVisibles(solo: 1);
    enLinea = false;
    await cubit.evaluar(capa, area, 18.4);
    expect(cubit.state.cobertura, CoberturaTeselas.parcial);
  });

  test('descargar zona sin conexión explica que se necesita red', () async {
    enLinea = false;
    await cubit.descargarZona(capa, area, 18);
    expect(cubit.state.mensaje, contains('Se necesita conexión'));
    expect(cliente.pedidas, isEmpty);
  });

  test('área demasiado grande se rechaza antes de descargar', () async {
    const ciudad = AreaGeo(sur: 4.0, oeste: -75.0, norte: 5.5, este: -73.5);
    await cubit.descargarZona(capa, ciudad, 16);
    expect(cubit.state.mensaje, contains('demasiado grande'));
    expect(cliente.pedidas, isEmpty);
  });

  test('descargar zona guarda las teselas y deja la zona usable sin red',
      () async {
    await cubit.descargarZona(capa, area, 18);
    expect(cubit.state.descargando, isFalse);
    expect(cubit.state.mensaje, contains('Zona guardada'));
    expect(cliente.pedidas, isNotEmpty);
    expect(
        cliente.pedidas.first, startsWith('https://server.arcgisonline.com'));

    enLinea = false;
    await cubit.evaluar(capa, area, 18.4);
    expect(cubit.state.cobertura, CoberturaTeselas.completa);
  });

  test('camaraMovida agrupa la evaluación', () async {
    enLinea = false;
    cubit.camaraMovida(capa, area, 18.4);
    expect(cubit.state.cobertura, CoberturaTeselas.desconocida);
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(cubit.state.cobertura, CoberturaTeselas.ninguna);
  });

  test('proveedor estable por capa', () {
    final p = cubit.proveedorPara(capa);
    expect(identical(p, cubit.proveedorPara(capa)), isTrue);
    expect(p, isA<TeselaCacheTileProvider>());
    expect(identical(p, cubit.proveedorPara(CapaMapa.openStreetMap)), isFalse);
  });

  testWidgets('el aviso se pinta sin conexión', (tester) async {
    enLinea = false;
    await tester.runAsync(() => cubit.evaluar(capa, area, 18.4));
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: AvisoTeselasOffline(cubit: cubit)),
    ));
    expect(find.textContaining('sin teselas guardadas'), findsOneWidget);
    expect(find.byIcon(Icons.cloud_off_rounded), findsOneWidget);
  });

  test('TeselaCacheImage compara por tesela y url', () {
    final repo = RepositorioTeselas(almacen: almacen, cliente: cliente);
    const c = ClaveTesela(capa: 'x', z: 1, x: 0, y: 0);
    expect(TeselaCacheImage(repositorio: repo, clave: c, url: 'u'),
        TeselaCacheImage(repositorio: repo, clave: c, url: 'u'));
  });
}
