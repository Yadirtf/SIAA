import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:siaa_web/core/network/api_client.dart';
import 'package:siaa_web/features/geo/data/geometria_remote_datasource.dart';
import 'package:siaa_web/features/geo/data/models/geo_models.dart';
import 'package:siaa_web/features/geo/presentation/editor/editor_geometria_cubit.dart';
import 'package:siaa_web/features/geo/presentation/editor/editor_geometria_state.dart';

void main() {
  late List<http.Request> peticiones;
  const espacio = EspacioModel(
    id: 'e1',
    sedeId: 's1',
    codigo: 'AUL-101',
    nombre: 'Aula 101',
    capacidad: 30,
    tipo: 'AULA',
    estado: 'DISPONIBLE',
    bufferMetros: 3,
    areaMetrosCuadrados: 0,
    activo: true,
  );

  EditorGeometriaCubit crear(http.Response Function(http.Request) responder) {
    final client = MockClient((req) async {
      peticiones.add(req);
      return responder(req);
    });
    return EditorGeometriaCubit(
      espacio: espacio,
      dataSource: GeometriaRemoteDataSource(client: ApiClient(client: client)),
    );
  }

  void tresEsquinas(EditorGeometriaCubit c) {
    c.agregarVertice(-76.1, 1.1);
    c.agregarVertice(-76.2, 1.1);
    c.agregarVertice(-76.2, 1.2);
  }

  setUp(() {
    peticiones = [];
    SharedPreferences.setMockInitialValues({'siaa_access_token': 'tok'});
  });

  test('agrega, deshace y limpia vértices', () {
    final c = crear((_) => http.Response('{}', 200));
    tresEsquinas(c);
    expect(c.state.vertices.length, 3);
    expect(c.state.puedeGuardar, isTrue);
    c.deshacer();
    expect(c.state.vertices.last, [-76.2, 1.1]);
    c.limpiar();
    expect(c.state.vertices, isEmpty);
  });

  test('no guarda con menos de 3 esquinas', () async {
    final c = crear((_) => http.Response('{}', 200));
    c.agregarVertice(-76.1, 1.1);
    await c.guardar();
    expect(c.state.error, isNotNull);
    expect(peticiones, isEmpty);
  });

  test('guarda con PUT, TOQUE_MAPA y orden [lon, lat]', () async {
    final c = crear(
      (_) => http.Response(jsonEncode({'id': 'e1', 'codigo': 'AUL-101'}), 200),
    );
    tresEsquinas(c);
    await c.guardar();
    final req = peticiones.single;
    expect(req.method, 'PUT');
    expect(req.url.path, endsWith('/espacios/e1/geometria'));
    final body = jsonDecode(req.body) as Map<String, dynamic>;
    expect(body['metodoCaptura'], 'TOQUE_MAPA');
    expect(body['coordenadas'][0], [-76.1, 1.1]);
    expect(c.state.guardado?.id, 'e1');
  });

  test('un solapamiento pide confirmación y luego reenvía', () async {
    var llamada = 0;
    final c = crear((_) {
      llamada++;
      if (llamada == 1) {
        return http.Response(
          jsonEncode({
            'codigo': 'VALIDACION',
            'mensaje': 'Requiere confirmación',
            'detalles': [
              {
                'campo': 'confirmarSolapamiento',
                'error': "solapamiento_detectado: 12.00% con 'Aula 102'",
              },
            ],
          }),
          422,
        );
      }
      return http.Response(jsonEncode({'id': 'e1'}), 200);
    });
    tresEsquinas(c);
    await c.guardar();
    expect(c.state.solapamiento, contains('Aula 102'));
    expect(c.state.guardado, isNull);

    await c.guardar(confirmarSolapamiento: true, motivo: 'Pasillo compartido');
    final body = jsonDecode(peticiones.last.body) as Map<String, dynamic>;
    expect(body['confirmarSolapamiento'], isTrue);
    expect(body['motivoSolapamiento'], 'Pasillo compartido');
    expect(c.state.guardado?.id, 'e1');
  });

  test('otro error del backend se muestra como mensaje', () async {
    final c = crear(
      (_) => http.Response(
        jsonEncode({
          'codigo': 'GEOMETRIA_INVALIDA',
          'mensaje': 'Polígono cruzado',
        }),
        422,
      ),
    );
    tresEsquinas(c);
    await c.guardar();
    expect(c.state.error, 'Polígono cruzado');
    expect(c.state.guardando, isFalse);
  });

  group('edición de vértices (US-GEO-07)', () {
    const conPoligono = EspacioModel(
      id: 'e2',
      sedeId: 's1',
      codigo: 'AUL-202',
      nombre: 'Aula 202',
      capacidad: 30,
      tipo: 'AULA',
      estado: 'DISPONIBLE',
      bufferMetros: 3,
      areaMetrosCuadrados: 0,
      activo: true,
      versionGeometria: 4,
      vertices: [
        [-76.6512, 1.1478],
        [-76.6510, 1.1478],
        [-76.6510, 1.1476],
        [-76.6512, 1.1476],
      ],
    );

    EditorGeometriaCubit editor(
      http.Response Function(http.Request) responder,
    ) => EditorGeometriaCubit(
      espacio: conPoligono,
      dataSource: GeometriaRemoteDataSource(
        client: ApiClient(
          client: MockClient((req) async {
            peticiones.add(req);
            return responder(req);
          }),
        ),
      ),
    );

    test('abre en modo editar, sin cambios y sin poder guardar', () {
      final c = editor((_) => http.Response('{}', 200));
      expect(c.state.modo, ModoEditor.editar);
      expect(c.state.modificado, isFalse);
      expect(c.state.puedeGuardar, isFalse);
      expect(c.state.areaM2, closeTo(495, 10));
    });

    test('AC-01: mover un vértice recalcula el área en vivo', () {
      final c = editor((_) => http.Response('{}', 200));
      final antes = c.state.areaM2;
      c.moverVertice(1, -76.6508, 1.1478);
      expect(c.state.vertices[1], [-76.6508, 1.1478]);
      expect(c.state.areaM2, greaterThan(antes));
      expect(c.state.modificado, isTrue);
      expect(c.state.seleccionado, 1);
    });

    test('AC-02: insertar en una arista agrega el vértice tras su inicio', () {
      final c = editor((_) => http.Response('{}', 200));
      c.insertarVertice(0, -76.6511, 1.1479);
      expect(c.state.vertices.length, 5);
      expect(c.state.vertices[1], [-76.6511, 1.1479]);
    });

    test('AC-03: elimina con más de 3 vértices y lo impide con 3', () {
      final c = editor((_) => http.Response('{}', 200));
      c.seleccionar(2);
      expect(c.state.puedeEliminarVertice, isTrue);
      c.eliminarVertice();
      expect(c.state.vertices.length, 3);
      c.seleccionar(0);
      expect(c.state.puedeEliminarVertice, isFalse);
      c.eliminarVertice();
      expect(c.state.vertices.length, 3);
      expect(c.state.error, contains('al menos 3'));
    });

    test('restaurar descarta las ediciones', () {
      final c = editor((_) => http.Response('{}', 200));
      c.moverVertice(0, -76.6513, 1.1479);
      c.restaurar();
      expect(c.state.modificado, isFalse);
    });

    test('AC-04: guarda con la versión leída como precondición', () async {
      final c = editor(
        (_) => http.Response(
          jsonEncode({'id': 'e2', 'codigo': 'AUL-202', 'versionGeometria': 5}),
          200,
        ),
      );
      c.moverVertice(0, -76.6513, 1.1479);
      await c.guardar();
      final body = jsonDecode(peticiones.single.body) as Map<String, dynamic>;
      expect(body['versionEsperada'], 4);
      expect(body['coordenadas'].length, 4);
      expect(c.state.guardado?.versionGeometria, 5);
    });

    test('un 409 CONFLICTO_VERSION se muestra sin perder la edición', () async {
      final c = editor(
        (_) => http.Response(
          jsonEncode({
            'codigo': 'CONFLICTO_VERSION',
            'mensaje': 'La geometría del espacio cambió (versión vigente 5).',
          }),
          409,
        ),
      );
      c.moverVertice(0, -76.6513, 1.1479);
      await c.guardar();
      expect(c.state.error, contains('cambió'));
      expect(c.state.guardado, isNull);
      expect(c.state.vertices[0], [-76.6513, 1.1479]);
    });
  });
}
