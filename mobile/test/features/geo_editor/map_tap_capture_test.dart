import 'package:flutter_test/flutter_test.dart';
import 'package:siaa_mobile/features/geo_editor/domain/models/gps_reading.dart';
import 'package:siaa_mobile/features/geo_editor/domain/models/tagged_vertex.dart';
import 'package:siaa_mobile/features/geo_editor/presentation/bloc/geo_editor_bloc.dart';
import 'package:siaa_mobile/features/geo_editor/presentation/bloc/geo_editor_event.dart';
import 'package:siaa_mobile/features/geo_editor/presentation/bloc/geo_editor_state.dart';

void main() {
  group('US-GEO-03: Captura por toque sobre mapa satelital', () {
    test('AC-01: Al tocar sobre el mapa se añade un vértice en [longitud, latitud]', () async {
      final bloc = GeoEditorBloc();

      bloc.add(const CambiarModoCapturaRequested(ModoCapturaEditor.mapa));
      await bloc.stream.firstWhere((s) => s.modoCaptura == ModoCapturaEditor.mapa);

      bloc.add(const ToqueEnMapaRequested(longitud: -74.08170, latitud: 4.60970));

      final state = await bloc.stream.firstWhere((s) => s.vertices.isNotEmpty);
      expect(state.vertices.length, 1);
      expect(state.vertices.first, [-74.08170, 4.60970]);
      expect(state.verticesEtiquetados.length, 1);
      expect(state.verticesEtiquetados.first.origen, OrigenVertice.toqueMapa);
      expect(state.verticesEtiquetados.first.precision, isNull);
    });

    test('AC-02: Polígono dibujado exclusivamente por toque registra TOQUE_MAPA y precisionPromedioCalculada == null', () async {
      String? metodoGuardado;
      double? precisionGuardada;

      final bloc = GeoEditorBloc(
        onSaveGeometry: ({
          required String espacioId,
          required List<List<double>> coordenadas,
          required String metodoCaptura,
          double? precisionPromedioMetros,
          bool? confirmarSolapamiento,
          String? motivoSolapamiento,
        }) async {
          metodoGuardado = metodoCaptura;
          precisionGuardada = precisionPromedioMetros;
        },
      );

      bloc.add(const CambiarModoCapturaRequested(ModoCapturaEditor.mapa));
      bloc.add(const ToqueEnMapaRequested(longitud: -74.08170, latitud: 4.60970));
      bloc.add(const ToqueEnMapaRequested(longitud: -74.08160, latitud: 4.60970));
      bloc.add(const ToqueEnMapaRequested(longitud: -74.08165, latitud: 4.60980));

      await bloc.stream.firstWhere((s) => s.vertices.length == 3);

      expect(bloc.state.metodoCapturaEfectivo, 'TOQUE_MAPA');
      expect(bloc.state.precisionPromedioCalculada, isNull);

      bloc.add(const CerrarPoligonoRequested());
      await bloc.stream.firstWhere((s) => s.isClosed);

      bloc.add(const GuardarGeometriaBackendRequested(espacioId: 'esp-001'));
      await bloc.stream.firstWhere((s) => s.status == GeoEditorStatus.success);

      expect(metodoGuardado, 'TOQUE_MAPA');
      expect(precisionGuardada, isNull);
    });

    test('AC-03: Alternar entre recorrido y mapa conserva vértices y registra MIXTO al combinar ambos', () async {
      String? metodoGuardado;
      double? precisionGuardada;

      final bloc = GeoEditorBloc(
        onSaveGeometry: ({
          required String espacioId,
          required List<List<double>> coordenadas,
          required String metodoCaptura,
          double? precisionPromedioMetros,
          bool? confirmarSolapamiento,
          String? motivoSolapamiento,
        }) async {
          metodoGuardado = metodoCaptura;
          precisionGuardada = precisionPromedioMetros;
        },
      );

      // 1. Capturar punto 1 por GPS en modo recorrido
      final p1 = [GpsReading(longitude: -74.08170, latitude: 4.60970, accuracy: 4.0)];
      bloc.add(CapturarVerticeRequested(lecturasManuales: p1));
      await bloc.stream.firstWhere((s) => s.vertices.length == 1);
      expect(bloc.state.metodoCapturaEfectivo, 'RECORRIDO_PERIMETRAL');

      // 2. Alternar a modo mapa (AC-03: conserva vértices)
      bloc.add(const CambiarModoCapturaRequested(ModoCapturaEditor.mapa));
      final modoMapaState = await bloc.stream.firstWhere((s) => s.modoCaptura == ModoCapturaEditor.mapa);
      expect(modoMapaState.vertices.length, 1);

      // 3. Capturar punto 2 por toque en mapa
      bloc.add(const ToqueEnMapaRequested(longitud: -74.08160, latitud: 4.60970));
      await bloc.stream.firstWhere((s) => s.vertices.length == 2);
      expect(bloc.state.metodoCapturaEfectivo, 'MIXTO');

      // 4. Capturar punto 3 por toque en mapa
      bloc.add(const ToqueEnMapaRequested(longitud: -74.08165, latitud: 4.60980));
      await bloc.stream.firstWhere((s) => s.vertices.length == 3);

      expect(bloc.state.metodoCapturaEfectivo, 'MIXTO');
      // Solo el vértice 1 tiene precisión (4.0)
      expect(bloc.state.precisionPromedioCalculada, closeTo(4.0, 1e-6));

      // 5. Cerrar y guardar
      bloc.add(const CerrarPoligonoRequested());
      await bloc.stream.firstWhere((s) => s.isClosed);

      bloc.add(const GuardarGeometriaBackendRequested(espacioId: 'esp-001'));
      await bloc.stream.firstWhere((s) => s.status == GeoEditorStatus.success);

      expect(metodoGuardado, 'MIXTO');
      expect(precisionGuardada, closeTo(4.0, 1e-6));
    });

    test('AC-05: Deshacer retira vértice tanto de vertices como de verticesEtiquetados', () async {
      final bloc = GeoEditorBloc();

      bloc.add(const ToqueEnMapaRequested(longitud: -74.08170, latitud: 4.60970));
      bloc.add(const ToqueEnMapaRequested(longitud: -74.08160, latitud: 4.60970));
      await bloc.stream.firstWhere((s) => s.vertices.length == 2);

      bloc.add(const DeshacerVerticeRequested());
      final state = await bloc.stream.firstWhere((s) => s.vertices.length == 1);

      expect(state.vertices.length, 1);
      expect(state.verticesEtiquetados.length, 1);
      expect(state.vertices.first, [-74.08170, 4.60970]);
    });
  });
}
