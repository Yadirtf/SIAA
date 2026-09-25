import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:siaa_mobile/features/geo_editor/domain/models/capa_mapa.dart';
import 'package:siaa_mobile/features/geo_editor/domain/models/gps_accuracy_status.dart';
import 'package:siaa_mobile/features/geo_editor/domain/models/tagged_vertex.dart';
import 'package:siaa_mobile/features/geo_editor/domain/services/gps_location_service.dart';
import 'package:siaa_mobile/features/geo_editor/presentation/bloc/geo_editor_state.dart';
import 'package:siaa_mobile/features/geo_editor/presentation/widgets/geo_editor_bottom_panel.dart';
import 'package:siaa_mobile/features/geo_editor/presentation/widgets/location_permission_banner.dart';
import 'package:siaa_mobile/features/geo_editor/presentation/widgets/map/gps_marker.dart';
import 'package:siaa_mobile/features/geo_editor/presentation/widgets/map/vertex_marker.dart';

void main() {
  group('Piezas del Rompecabezas GeoEditor (Pruebas Modulares)', () {
    test('CapaMapa: ciclo de rotación y configuración de proveedores', () {
      expect(CapaMapa.googleHibrido.siguiente, CapaMapa.esriSatelite);
      expect(CapaMapa.esriSatelite.siguiente, CapaMapa.openStreetMap);
      expect(CapaMapa.openStreetMap.siguiente, CapaMapa.googleHibrido);

      expect(CapaMapa.googleHibrido.maxNativeZoom, 20);
      expect(CapaMapa.esriSatelite.maxNativeZoom, 18);
      expect(CapaMapa.openStreetMap.maxNativeZoom, 19);

      expect(CapaMapa.googleHibrido.urlTemplate, contains('google.com'));
      expect(CapaMapa.esriSatelite.urlTemplate, contains('arcgisonline.com'));
      expect(CapaMapa.openStreetMap.urlTemplate, contains('openstreetmap.org'));
    });

    testWidgets(
        'LocationPermissionBanner: muestra banner de servicio apagado con botón de acción',
        (tester) async {
      bool ajustesLlamados = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LocationPermissionBanner(
              estadoPermiso: EstadoPermisoUbicacion.servicioDesactivado,
              onAbrirAjustesUbicacion: () => ajustesLlamados = true,
              onAbrirAjustesAplicacion: () {},
              onSolicitarPermiso: () {},
            ),
          ),
        ),
      );

      expect(find.text('Activar GPS'), findsOneWidget);
      expect(find.byIcon(Icons.location_off), findsOneWidget);

      await tester.tap(find.text('Activar GPS'));
      expect(ajustesLlamados, isTrue);
    });

    testWidgets(
        'LocationPermissionBanner: oculto cuando permiso está concedido',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LocationPermissionBanner(
              estadoPermiso: EstadoPermisoUbicacion.concedido,
              onAbrirAjustesUbicacion: () {},
              onAbrirAjustesAplicacion: () {},
              onSolicitarPermiso: () {},
            ),
          ),
        ),
      );

      expect(find.text('Activar GPS'), findsNothing);
      expect(find.byType(ElevatedButton), findsNothing);
    });

    testWidgets(
        'VertexMarker: muestra número secuencial y respeta color por origen',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                VertexMarker(
                  index: 1,
                  vertex: TaggedVertex(
                      longitude: -74.0,
                      latitude: 4.0,
                      origen: OrigenVertice.gps),
                ),
                VertexMarker(
                  index: 2,
                  vertex: TaggedVertex(
                      longitude: -74.1,
                      latitude: 4.1,
                      origen: OrigenVertice.toqueMapa),
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('1'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
    });

    testWidgets('GpsMarker: renderiza halo y punto central para estado óptimo',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: GpsMarker(accuracy: GpsAccuracyStatus.optimal),
          ),
        ),
      );

      expect(find.byType(GpsMarker), findsOneWidget);
      expect(find.byType(Container), findsWidgets);
    });

    testWidgets(
        'GeoEditorBottomPanel: renderiza métricas y dispara callbacks de acción',
        (tester) async {
      bool undoPresionado = false;
      bool capturePresionado = false;

      final state = const GeoEditorState(
        vertices: [
          [-74.0, 4.0],
          [-74.1, 4.1],
        ],
        areaCalculadaM2: 125.4,
        perimetroMetros: 45.2,
        accuracyStatus: GpsAccuracyStatus.optimal,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GeoEditorBottomPanel(
              state: state,
              onDeshacer: () => undoPresionado = true,
              onCapturar: () => capturePresionado = true,
              onCerrarPoligono: () {},
              onGuardar: () {},
            ),
          ),
        ),
      );

      expect(find.text('125.4 m²'), findsOneWidget);
      expect(find.text('45.2 m'), findsOneWidget);
      expect(find.text('Deshacer'), findsOneWidget);
      expect(find.text('Capturar Vértice'), findsOneWidget);

      await tester.tap(find.text('Deshacer'));
      expect(undoPresionado, isTrue);

      await tester.tap(find.text('Capturar Vértice'));
      expect(capturePresionado, isTrue);
    });
  });
}
