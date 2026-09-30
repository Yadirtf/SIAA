import 'package:flutter_test/flutter_test.dart';
import 'package:siaa_mobile/features/geo_editor/data/espacio_repository.dart';
import 'package:siaa_mobile/features/geo_editor/domain/models/tagged_vertex.dart';
import 'package:siaa_mobile/features/geo_editor/presentation/bloc/geo_editor_bloc.dart';
import 'package:siaa_mobile/features/geo_editor/presentation/bloc/geo_editor_event.dart';
import 'package:siaa_mobile/features/geo_editor/presentation/bloc/geo_editor_state.dart';

void main() {
  group(
      'US-GEO-05 / T-GEO-05.4: Detección y confirmación de solapamientos en Frontend',
      () {
    test(
        'AC-01 & AC-02: Solapamiento <= 50% emite advertencia y permite confirmar con motivo',
        () async {
      bool intento1Hecho = false;
      bool intento2Confirmado = false;
      String? motivoRecibido;

      final bloc = GeoEditorBloc(
        onSaveGeometry: ({
          required String espacioId,
          required List<List<double>> coordenadas,
          required String metodoCaptura,
          double? precisionPromedioMetros,
          bool? confirmarSolapamiento,
          String? motivoSolapamiento,
        }) async {
          if (confirmarSolapamiento != true) {
            intento1Hecho = true;
            throw SolapamientoAdvertenciaException(
              mensaje: 'Se detectó solapamiento con Aula 101 (25.50%)',
              detalles: [
                'solapamiento_detectado: 25.50% de área solapada con espacio Aula 101'
              ],
            );
          } else {
            intento2Confirmado = true;
            motivoRecibido = motivoSolapamiento;
          }
        },
      );

      // Crear polígono cerrado mínimo (4 vértices)
      bloc.add(const CambiarModoCapturaRequested(ModoCapturaEditor.mapa));
      bloc.add(
          const ToqueEnMapaRequested(longitud: -74.08170, latitud: 4.60970));
      bloc.add(
          const ToqueEnMapaRequested(longitud: -74.08160, latitud: 4.60970));
      bloc.add(
          const ToqueEnMapaRequested(longitud: -74.08165, latitud: 4.60980));
      await bloc.stream.firstWhere((s) => s.vertices.length == 3);

      bloc.add(const CerrarPoligonoRequested());
      await bloc.stream.firstWhere((s) => s.isClosed);

      // Primer intento sin confirmación -> debe fallar con solapamientoAdvertencia
      bloc.add(const GuardarGeometriaBackendRequested(espacioId: 'esp-001'));
      final stateAdv = await bloc.stream
          .firstWhere((s) => s.status == GeoEditorStatus.error);

      expect(intento1Hecho, isTrue);
      expect(stateAdv.solapamientoAdvertencia, contains('Aula 101'));
      expect(stateAdv.solapamientoDetalles, isNotNull);

      // Segundo intento con confirmación explícita y motivo
      bloc.add(const GuardarGeometriaBackendRequested(
        espacioId: 'esp-001',
        confirmarSolapamiento: true,
        motivoSolapamiento: 'Tolerancia de muro divisorio',
      ));
      final stateSuccess = await bloc.stream
          .firstWhere((s) => s.status == GeoEditorStatus.success);

      expect(intento2Confirmado, isTrue);
      expect(motivoRecibido, 'Tolerancia de muro divisorio');
      expect(stateSuccess.solapamientoAdvertencia, isNull);
      expect(stateSuccess.successMessage, contains('exitosamente'));
    });

    test('AC-03: Solapamiento > 50% emite solapamientoCritico con bloqueo',
        () async {
      final bloc = GeoEditorBloc(
        onSaveGeometry: ({
          required String espacioId,
          required List<List<double>> coordenadas,
          required String metodoCaptura,
          double? precisionPromedioMetros,
          bool? confirmarSolapamiento,
          String? motivoSolapamiento,
        }) async {
          throw SolapamientoCriticoException(
            mensaje:
                'Solapamiento crítico del 80.00% detectado con el espacio Aula 101. Supera el límite del 50%.',
          );
        },
      );

      bloc.add(const CambiarModoCapturaRequested(ModoCapturaEditor.mapa));
      bloc.add(
          const ToqueEnMapaRequested(longitud: -74.08170, latitud: 4.60970));
      bloc.add(
          const ToqueEnMapaRequested(longitud: -74.08160, latitud: 4.60970));
      bloc.add(
          const ToqueEnMapaRequested(longitud: -74.08165, latitud: 4.60980));
      await bloc.stream.firstWhere((s) => s.vertices.length == 3);

      bloc.add(const CerrarPoligonoRequested());
      await bloc.stream.firstWhere((s) => s.isClosed);

      bloc.add(const GuardarGeometriaBackendRequested(espacioId: 'esp-001'));
      final stateCrit = await bloc.stream
          .firstWhere((s) => s.status == GeoEditorStatus.error);

      expect(stateCrit.solapamientoCritico, contains('Solapamiento crítico'));
      expect(stateCrit.solapamientoCritico, contains('80.00%'));
    });
  });
}
