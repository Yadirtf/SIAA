// teselas_cache_test.dart — Caché de teselas del modo mapa sin conexión (US-GEO-03 AC-04)
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:siaa_mobile/features/geo_editor/data/teselas/almacen_teselas.dart';
import 'package:siaa_mobile/features/geo_editor/data/teselas/repositorio_teselas.dart';
import 'package:siaa_mobile/features/geo_editor/domain/models/clave_tesela.dart';
import 'package:siaa_mobile/features/geo_editor/domain/services/teselas_area.dart';

import 'fakes_teselas.dart';

// Campus de referencia en Bogotá (~250 m x 250 m).
const area =
    AreaGeo(sur: 4.6350, oeste: -74.0860, norte: 4.6372, este: -74.0838);
const clave = ClaveTesela(capa: 'esriSatelite', z: 18, x: 77, y: 120);

void main() {
  group('TeselasArea', () {
    test('columna y fila coinciden con el esquema XYZ', () {
      expect(TeselasArea.columna(-180, 1), 0);
      expect(TeselasArea.columna(179.9, 1), 1);
      expect(TeselasArea.fila(85, 1), 0);
      expect(TeselasArea.fila(-85, 1), 1);
      // Bogotá a zoom 18 (verificado con la fórmula de OSM).
      expect(TeselasArea.columna(-74.0839, 18), 77125);
      expect(TeselasArea.fila(4.6372, 18), 127691);
    });

    test('contar coincide con la enumeración y crece con el zoom', () {
      final n = TeselasArea.contar(area, 15, 18);
      expect(TeselasArea.enArea('c', area, 15, 18).length, n);
      expect(TeselasArea.contar(area, 18, 18),
          greaterThan(TeselasArea.contar(area, 15, 15)));
    });

    test('zoomMaximoDentroDeLimite recorta el detalle o rechaza el área', () {
      final z = TeselasArea.zoomMaximoDentroDeLimite(area, 15, 19, 40);
      expect(z, isNotNull);
      expect(TeselasArea.contar(area, 15, z!), lessThanOrEqualTo(40));
      const pais = AreaGeo(sur: -4, oeste: -79, norte: 12, este: -67);
      expect(TeselasArea.zoomMaximoDentroDeLimite(pais, 15, 19, 3000), isNull);
    });

    test('url sustituye z, x e y', () {
      expect(TeselasArea.url('https://t/{z}/{y}/{x}', clave),
          'https://t/18/120/77');
    });
  });

  group('RepositorioTeselas', () {
    late AlmacenMemoria almacen;
    late ClienteFalso cliente;
    late DateTime ahora;
    late RepositorioTeselas repo;

    setUp(() {
      almacen = AlmacenMemoria();
      cliente = ClienteFalso();
      ahora = DateTime(2026, 10, 9);
      repo = RepositorioTeselas(
          almacen: almacen, cliente: cliente, ahora: () => ahora);
    });

    test('en línea descarga y guarda la tesela', () async {
      final b = await repo.obtener(clave, 'u1');
      expect(String.fromCharCodes(b), 'u1');
      expect(await almacen.existe(clave), isTrue);
    });

    test('una tesela reciente se sirve sin red', () async {
      await repo.obtener(clave, 'u1');
      cliente.pedidas.clear();
      final b = await repo.obtener(clave, 'u1');
      expect(String.fromCharCodes(b), 'u1');
      expect(cliente.pedidas, isEmpty);
    });

    test('sin conexión usa la copia vencida en lugar de fallar', () async {
      await repo.obtener(clave, 'u1');
      ahora = ahora.add(const Duration(days: 90));
      cliente.sinRed = true;
      final b = await repo.obtener(clave, 'u1');
      expect(String.fromCharCodes(b), 'u1');
      expect(cliente.pedidas, hasLength(2)); // intentó refrescar
    });

    test('sin conexión y sin copia la tesela falla', () async {
      cliente.sinRed = true;
      expect(() => repo.obtener(clave, 'u1'), throwsStateError);
    });

    test('predescargar omite las guardadas y cuenta las fallidas', () async {
      final claves = TeselasArea.enArea('osm', area, 16, 17).toList();
      await almacen.guardar(claves.first, Uint8List.fromList([1]));
      cliente.fallan.add(TeselasArea.url('{z}/{x}/{y}', claves.last));
      final progreso = <int>[];

      final r = await repo.predescargar(
        capa: 'osm',
        plantillaUrl: '{z}/{x}/{y}',
        area: area,
        zMin: 16,
        zMax: 17,
        onProgreso: (h, _) => progreso.add(h),
      );

      expect(r.total, claves.length);
      expect(r.yaGuardadas, 1);
      expect(r.fallidas, 1);
      expect(r.descargadas, claves.length - 2);
      expect(progreso.last, claves.length);
      expect(await repo.contarGuardadas(claves), claves.length - 1);
    });
  });

  test('AlmacenTeselasArchivo persiste en disco', () async {
    final dir = await Directory.systemTemp.createTemp('teselas_test');
    addTearDown(() => dir.delete(recursive: true));
    final almacen = AlmacenTeselasArchivo(raiz: () async => dir);

    expect(await almacen.existe(clave), isFalse);
    expect(await almacen.leer(clave), isNull);
    await almacen.guardar(clave, Uint8List.fromList([7, 8, 9]));
    expect(await almacen.existe(clave), isTrue);
    expect((await almacen.leer(clave))!.bytes, [7, 8, 9]);

    final otro = AlmacenTeselasArchivo(raiz: () async => dir);
    expect((await otro.leer(clave))!.bytes, [7, 8, 9]);
  });
}
