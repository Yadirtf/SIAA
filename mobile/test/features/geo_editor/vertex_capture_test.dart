import 'package:flutter_test/flutter_test.dart';
import 'package:siaa_mobile/features/geo_editor/domain/models/gps_accuracy_status.dart';
import 'package:siaa_mobile/features/geo_editor/domain/models/gps_reading.dart';
import 'package:siaa_mobile/features/geo_editor/domain/services/geodesic_calculator.dart';
import 'package:siaa_mobile/features/geo_editor/domain/services/vertex_capture_algorithm.dart';
import 'package:siaa_mobile/features/geo_editor/presentation/bloc/geo_editor_bloc.dart';
import 'package:siaa_mobile/features/geo_editor/presentation/bloc/geo_editor_event.dart';
import 'package:siaa_mobile/features/geo_editor/presentation/bloc/geo_editor_state.dart';

void main() {
  group('VertexCaptureAlgorithm — AC-01, AC-02, T-GEO-02.4', () {
    const algorithm = VertexCaptureAlgorithm(
      muestrasRequeridas: 5,
      umbralPrecisionMetros: 15.0,
    );

    test('AC-01: realiza promedio de 5 lecturas consecutivas válidas', () {
      final readings = [
        GpsReading(longitude: -74.08170, latitude: 4.60970, accuracy: 4.0),
        GpsReading(longitude: -74.08172, latitude: 4.60972, accuracy: 5.0),
        GpsReading(longitude: -74.08174, latitude: 4.60974, accuracy: 4.5),
        GpsReading(longitude: -74.08176, latitude: 4.60976, accuracy: 5.5),
        GpsReading(longitude: -74.08178, latitude: 4.60978, accuracy: 6.0),
      ];

      final result = algorithm.processReadings(readings);

      expect(result.longitude, closeTo(-74.08174, 1e-6));
      expect(result.latitude, closeTo(4.60974, 1e-6));
      expect(result.accuracy, closeTo(5.0, 1e-6));
    });

    test('AC-02: descarta lecturas que superan el umbral (15 m) y promedia las válidas', () {
      final readings = [
        GpsReading(longitude: -74.08170, latitude: 4.60970, accuracy: 4.0), // Válida
        GpsReading(longitude: -74.08999, latitude: 4.69999, accuracy: 18.5), // DESCARTAR (> 15m)
        GpsReading(longitude: -74.08174, latitude: 4.60974, accuracy: 6.0), // Válida
        GpsReading(longitude: -74.08888, latitude: 4.68888, accuracy: 25.0), // DESCARTAR (> 15m)
        GpsReading(longitude: -74.08178, latitude: 4.60978, accuracy: 5.0), // Válida
      ];

      final result = algorithm.processReadings(readings);

      // Solo deben promediarse las lecturas 1, 3 y 5
      final expectedLon = (-74.08170 + -74.08174 + -74.08178) / 3.0;
      final expectedLat = (4.60970 + 4.60974 + 4.60978) / 3.0;
      final expectedAcc = (4.0 + 6.0 + 5.0) / 3.0;

      expect(result.longitude, closeTo(expectedLon, 1e-6));
      expect(result.latitude, closeTo(expectedLat, 1e-6));
      expect(result.accuracy, closeTo(expectedAcc, 1e-6));
    });

    test('AC-02: lanza PrecisionInsuficienteException si todas las lecturas superan el umbral', () {
      final badReadings = [
        GpsReading(longitude: -74.08170, latitude: 4.60970, accuracy: 16.0),
        GpsReading(longitude: -74.08172, latitude: 4.60972, accuracy: 18.0),
        GpsReading(longitude: -74.08174, latitude: 4.60974, accuracy: 22.0),
        GpsReading(longitude: -74.08176, latitude: 4.60976, accuracy: 15.5),
        GpsReading(longitude: -74.08178, latitude: 4.60978, accuracy: 30.0),
      ];

      expect(
        () => algorithm.processReadings(badReadings),
        throwsA(isA<PrecisionInsuficienteException>()),
      );
    });
  });

  group('GpsAccuracyStatus — AC-03, AC-04, T-GEO-02.6', () {
    test('AC-03: clasifica precisión en óptima (<=10m), aceptable (10-20m) e insuficiente (>20m)', () {
      expect(GpsAccuracyStatusX.fromAccuracy(5.0), GpsAccuracyStatus.optimal);
      expect(GpsAccuracyStatusX.fromAccuracy(10.0), GpsAccuracyStatus.optimal);
      expect(GpsAccuracyStatusX.fromAccuracy(10.1), GpsAccuracyStatus.acceptable);
      expect(GpsAccuracyStatusX.fromAccuracy(20.0), GpsAccuracyStatus.acceptable);
      expect(GpsAccuracyStatusX.fromAccuracy(20.1), GpsAccuracyStatus.insufficient);
      expect(GpsAccuracyStatusX.fromAccuracy(35.0), GpsAccuracyStatus.insufficient);
    });

    test('AC-04: canCapture es false si la precisión es insuficiente (> 20m)', () {
      expect(GpsAccuracyStatus.optimal.canCapture, isTrue);
      expect(GpsAccuracyStatus.acceptable.canCapture, isTrue);
      expect(GpsAccuracyStatus.insufficient.canCapture, isFalse);
      expect(GpsAccuracyStatus.searching.canCapture, isFalse);
    });
  });

  group('GeodesicCalculator — T-GEO-02.2, AC-06', () {
    test('Calcula área esférica positiva para polígono de 3+ vértices', () {
      // Triángulo en Bogotá
      final poly = [
        [-74.08175, 4.60971],
        [-74.08165, 4.60971],
        [-74.08170, 4.60980],
      ];

      final area = GeodesicCalculator.calcularArea(poly);
      expect(area, greaterThan(0.0));
      expect(area, closeTo(55.0, 15.0)); // Área estimada del triángulo en m²

      final perimetro = GeodesicCalculator.calcularPerimetro(poly);
      expect(perimetro, greaterThan(0.0));
    });
  });

  group('GeoEditorBloc — AC-05, AC-06, AC-07', () {
    test('AC-05: permite deshacer el último vértice capturado', () {
      final bloc = GeoEditorBloc();

      // Añadimos dos vértices manualmente
      final lectura1 = [
        GpsReading(longitude: -74.08170, latitude: 4.60970, accuracy: 5.0)
      ];
      final lectura2 = [
        GpsReading(longitude: -74.08160, latitude: 4.60970, accuracy: 5.0)
      ];

      bloc.add(CapturarVerticeRequested(lecturasManuales: lectura1));
      bloc.add(CapturarVerticeRequested(lecturasManuales: lectura2));

      expectLater(
        bloc.stream.map((s) => s.vertices.length),
        emitsThrough(2),
      ).then((_) {
        // Ejecutar Deshacer
        bloc.add(const DeshacerVerticeRequested());
        expectLater(
          bloc.stream.map((s) => s.vertices.length),
          emitsThrough(1),
        );
      });
    });

    test('AC-06: cerrar polígono auto-completa el anillo y calcula área en pantalla', () async {
      final bloc = GeoEditorBloc();

      final p1 = [GpsReading(longitude: -74.08170, latitude: 4.60970, accuracy: 5.0)];
      final p2 = [GpsReading(longitude: -74.08160, latitude: 4.60970, accuracy: 5.0)];
      final p3 = [GpsReading(longitude: -74.08160, latitude: 4.60980, accuracy: 5.0)];

      bloc.add(CapturarVerticeRequested(lecturasManuales: p1));
      bloc.add(CapturarVerticeRequested(lecturasManuales: p2));
      bloc.add(CapturarVerticeRequested(lecturasManuales: p3));

      // Esperar a que se procesen los 3 vértices
      await bloc.stream.firstWhere((s) => s.vertices.length == 3);

      bloc.add(const CerrarPoligonoRequested());

      final closedState = await bloc.stream.firstWhere((s) => s.isClosed);
      expect(closedState.isClosed, isTrue);
      expect(closedState.vertices.length, 4); // 3 + 1 de cierre
      expect(closedState.vertices.first, closedState.vertices.last);
      expect(closedState.areaCalculadaM2, greaterThan(0.0));
      expect(closedState.status, GeoEditorStatus.readyToSave);
    });
  });
}
