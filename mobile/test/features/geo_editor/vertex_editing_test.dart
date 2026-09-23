import 'package:flutter_test/flutter_test.dart';
import 'package:siaa_mobile/features/geo_editor/domain/models/geometria_historial_item.dart';
import 'package:siaa_mobile/features/geo_editor/domain/models/tagged_vertex.dart';
import 'package:siaa_mobile/features/geo_editor/presentation/bloc/geo_editor_bloc.dart';
import 'package:siaa_mobile/features/geo_editor/presentation/bloc/geo_editor_event.dart';
import 'package:siaa_mobile/features/geo_editor/presentation/bloc/geo_editor_state.dart';

void main() {
  group('US-GEO-07: Edición de vértices individuales y recálculo en vivo', () {
    late GeoEditorBloc bloc;

    setUp(() {
      bloc = GeoEditorBloc();
    });

    tearDown(() {
      bloc.close();
    });

    test('AC-01: Mover vértice actualiza coordenadas y recalcula área en vivo (T-GEO-07.3)', () async {
      // Polígono cuadrado inicial: (0,0) -> (10,0) -> (10,10) -> (0,10) -> (0,0)
      final verticesIniciales = [
        [-74.081750, 4.638190],
        [-74.081650, 4.638190],
        [-74.081650, 4.638250],
        [-74.081750, 4.638250],
        [-74.081750, 4.638190],
      ];

      bloc.add(CargarGeometriaExistenteRequested(verticesIniciales));
      await Future.delayed(Duration.zero);

      final areaOriginal = bloc.state.areaCalculadaM2;
      expect(areaOriginal, greaterThan(0.0));
      expect(bloc.state.isClosed, isTrue);

      // Mover el vértice 2 hacia afuera para agrandar el polígono
      bloc.add(const MoverVerticeRequested(
        index: 2,
        nuevaLongitud: -74.081600,
        nuevaLatitud: 4.638300,
      ));
      await Future.delayed(Duration.zero);

      expect(bloc.state.vertices[2][0], equals(-74.081600));
      expect(bloc.state.vertices[2][1], equals(4.638300));
      expect(bloc.state.areaCalculadaM2, isNot(equals(areaOriginal)));
      expect(bloc.state.verticeSeleccionadoIndex, equals(2));
    });

    test('AC-02: Insertar vértice en arista de polígono', () async {
      final vertices = [
        [-74.081750, 4.638190],
        [-74.081650, 4.638190],
        [-74.081650, 4.638250],
        [-74.081750, 4.638250],
        [-74.081750, 4.638190],
      ];

      bloc.add(CargarGeometriaExistenteRequested(vertices));
      await Future.delayed(Duration.zero);

      final countOriginal = bloc.state.vertices.length;

      // Insertar vértice entre punto 0 y punto 1
      bloc.add(const InsertarVerticeEnSegmentoRequested(
        indexDespuesDe: 0,
        longitud: -74.081700,
        latitud: 4.638190,
      ));
      await Future.delayed(Duration.zero);

      expect(bloc.state.vertices.length, equals(countOriginal + 1));
      expect(bloc.state.vertices[1][0], equals(-74.081700));
      expect(bloc.state.vertices[1][1], equals(4.638190));
    });

    test('AC-03: Eliminar vértice cuando hay más de 3 vértices permitidos', () async {
      final vertices = [
        [-74.081750, 4.638190],
        [-74.081650, 4.638190],
        [-74.081650, 4.638250],
        [-74.081700, 4.638250],
        [-74.081750, 4.638250],
        [-74.081750, 4.638190],
      ]; // 5 vértices distintos + cierre

      bloc.add(CargarGeometriaExistenteRequested(vertices));
      await Future.delayed(Duration.zero);

      final countAntes = bloc.state.vertices.length;

      bloc.add(const EliminarVerticeRequested(2));
      await Future.delayed(Duration.zero);

      expect(bloc.state.vertices.length, equals(countAntes - 1));
      expect(bloc.state.errorMessage, isNull);
    });

    test('AC-03: Impedir eliminar vértice si solo quedan 3 vértices distintos', () async {
      // Triángulo cerrado: 3 vértices distintos + cierre (longitud = 4)
      final vertices = [
        [-74.081750, 4.638190],
        [-74.081650, 4.638190],
        [-74.081650, 4.638250],
        [-74.081750, 4.638190],
      ];

      bloc.add(CargarGeometriaExistenteRequested(vertices));
      await Future.delayed(Duration.zero);

      bloc.add(const EliminarVerticeRequested(1));
      await Future.delayed(Duration.zero);

      // Debe rechazar la eliminación y mostrar mensaje de error
      expect(bloc.state.status, equals(GeoEditorStatus.error));
      expect(bloc.state.errorMessage, contains('al menos 3 vértices'));
      expect(bloc.state.vertices.length, equals(4)); // No se eliminó
    });
  });

  group('US-GEO-06: Historial y visor de versiones de geometría en móvil', () {
    test('AC-04: Cargar historial y superponer versión previa en el mapa', () async {
      final mockHistorial = [
        GeometriaHistorialItem(
          id: 'hist-01',
          espacioId: 'esp-01',
          version: 1,
          coordenadas: [
            [-74.081750, 4.638190],
            [-74.081650, 4.638190],
            [-74.081650, 4.638250],
            [-74.081750, 4.638190],
          ],
          areaMetrosCuadrados: 55.4,
          metodoCaptura: 'RECORRIDO_PERIMETRAL',
          creadoPor: 'admin01',
          creadoEn: DateTime(2026, 9, 21),
        ),
      ];

      final bloc = GeoEditorBloc(
        onFetchHistorial: (id) async => mockHistorial,
      );

      // Solicitar historial
      bloc.add(const CargarVersionesHistoricasRequested('esp-01'));
      await Future.delayed(Duration.zero);

      expect(bloc.state.versionesHistoricas.length, equals(1));
      expect(bloc.state.versionesHistoricas.first.version, equals(1));

      // Seleccionar previsualización
      bloc.add(const SeleccionarVersionPreviewRequested(1));
      await Future.delayed(Duration.zero);

      expect(bloc.state.versionPreview, isNotNull);
      expect(bloc.state.versionPreview?.version, equals(1));

      // Limpiar previsualización
      bloc.add(const SeleccionarVersionPreviewRequested(null));
      await Future.delayed(Duration.zero);

      expect(bloc.state.versionPreview, isNull);

      await bloc.close();
    });
  });
}
