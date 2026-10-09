import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:siaa_web/core/network/api_client.dart';
import 'package:siaa_web/features/geo/data/geometria_remote_datasource.dart';
import 'package:siaa_web/features/geo/data/models/geo_models.dart';
import 'package:siaa_web/features/geo/presentation/bloc/geo_bloc.dart';
import 'package:siaa_web/features/geo/presentation/editor/editor_geometria_cubit.dart';
import 'package:siaa_web/features/geo/presentation/editor/editor_geometria_dialog.dart';

import 'fake_geo_repository.dart';

const _espacio = EspacioModel(
  id: 'e2',
  sedeId: 's1',
  codigo: 'AUL-202',
  nombre: 'Aula 202',
  capacidad: 30,
  tipo: 'AULA',
  estado: 'DISPONIBLE',
  bufferMetros: 3,
  areaMetrosCuadrados: 495,
  activo: true,
  versionGeometria: 2,
  vertices: [
    [-76.6512, 1.1478],
    [-76.6510, 1.1478],
    [-76.6510, 1.1476],
    [-76.6512, 1.1476],
  ],
);

/// Avanza animaciones de diálogo sin esperar a que las teselas del mapa
/// (que nunca cargan en pruebas) se asienten.
Future<void> avanzar(WidgetTester tester) async {
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  late List<http.Request> peticiones;
  late EditorGeometriaCubit cubit;

  setUp(() {
    peticiones = [];
    SharedPreferences.setMockInitialValues({'siaa_access_token': 'tok'});
  });

  Future<void> abrir(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1600, 1100);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    cubit = EditorGeometriaCubit(
      espacio: _espacio,
      dataSource: GeometriaRemoteDataSource(
        client: ApiClient(
          client: MockClient((req) async {
            peticiones.add(req);
            return http.Response(jsonEncode({'id': 'e2'}), 200);
          }),
        ),
      ),
    );
    final geoBloc = GeoBloc(repository: FakeGeoRepository());
    addTearDown(cubit.close);
    addTearDown(geoBloc.close);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => showDialog<void>(
                context: context,
                barrierDismissible: false,
                builder: (_) => MultiBlocProvider(
                  providers: [
                    BlocProvider.value(value: cubit),
                    BlocProvider.value(value: geoBloc),
                  ],
                  child: const EditorGeometria(),
                ),
              ),
              child: const Text('abrir'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('abrir'));
    await avanzar(tester);
  }

  String area(WidgetTester tester) =>
      tester.widget<Text>(find.byKey(const Key('area-en-vivo'))).data!;

  testWidgets('sin cambios se cierra sin preguntar', (tester) async {
    await abrir(tester);
    expect(find.text('Editar vértices'), findsOneWidget);
    await tester.tap(find.byTooltip('Cerrar sin guardar'));
    await avanzar(tester);
    expect(find.byType(EditorGeometria), findsNothing);
  });

  testWidgets('AC-01/AC-05: área en vivo y confirmación al salir', (
    tester,
  ) async {
    await abrir(tester);
    final antes = area(tester);
    cubit.moverVertice(1, -76.6508, 1.1478);
    await avanzar(tester);
    expect(area(tester), isNot(antes));

    await tester.tap(find.byTooltip('Cerrar sin guardar'));
    await avanzar(tester);
    expect(find.text('¿Descartar los cambios?'), findsOneWidget);
    await tester.tap(find.text('Seguir editando'));
    await avanzar(tester);
    expect(find.byType(EditorGeometria), findsOneWidget);

    await tester.tap(find.byTooltip('Cerrar sin guardar'));
    await avanzar(tester);
    await tester.tap(find.text('Descartar cambios'));
    await avanzar(tester);
    expect(find.byType(EditorGeometria), findsNothing);
    expect(peticiones, isEmpty, reason: 'descartar no altera nada');
  });

  testWidgets('AC-03: "Eliminar vértice" solo con selección y más de 3', (
    tester,
  ) async {
    await abrir(tester);
    ButtonStyleButton boton() => tester.widget<ButtonStyleButton>(
      find.byKey(const Key('eliminar-vertice')),
    );
    expect(boton().onPressed, isNull);
    cubit.seleccionar(0);
    await avanzar(tester);
    expect(boton().onPressed, isNotNull);
    await tester.tap(find.byKey(const Key('eliminar-vertice')));
    await avanzar(tester);
    expect(cubit.state.vertices.length, 3);
    cubit.seleccionar(0);
    await avanzar(tester);
    expect(boton().onPressed, isNull);
  });
}
