// notificaciones_modelos_test.dart — Bandeja, preferencias y rutas (US-NOT-01/02, US-MAR-12)
import 'package:flutter_test/flutter_test.dart';
import 'package:siaa_mobile/features/notificaciones/domain/models/destino_notificacion.dart';
import 'package:siaa_mobile/features/notificaciones/domain/models/notificacion_model.dart';
import 'package:siaa_mobile/features/notificaciones/domain/models/preferencias_notificacion.dart';

void main() {
  group('DestinoNotificacion', () {
    test('mapea cada ruta del contrato a su ruta del shell', () {
      final m = DestinoNotificacion.desdeDatos(
          const {'ruta': '/marcaje', 'sesionId': 'ses-1'});
      expect(m?.pantalla, PantallaNotificacion.marcaje);
      expect(m?.rutaShell, '/shell/inicio');
      expect(m?.sesionId, 'ses-1');
      expect(
        DestinoNotificacion.desdeDatos(const {'ruta': '/justificaciones'})
            ?.rutaShell,
        '/shell/justificaciones',
      );
      expect(
        DestinoNotificacion.desdeDatos(const {'ruta': '/horario'})?.rutaShell,
        '/shell/horario',
      );
    });

    test('ruta desconocida o ausente no navega', () {
      expect(DestinoNotificacion.desdeDatos(const {'ruta': '/admin'}), isNull);
      expect(DestinoNotificacion.desdeDatos(const {}), isNull);
      expect(DestinoNotificacion.desdeDatos(null), isNull);
    });
  });

  test('NotificacionModel parsea la bandeja', () {
    final n = NotificacionModel.fromJson(const {
      'id': 'n1',
      'tipo': 'RESULTADO_JUSTIFICACION',
      'titulo': 'Justificación aprobada',
      'cuerpo': 'Su justificación fue aprobada',
      'datos': {'ruta': '/justificaciones', 'justificacionId': 'j1'},
      'creadaEn': '2026-09-30T13:00:00Z',
      'leida': false,
    });
    expect(n.id, 'n1');
    expect(n.leida, isFalse);
    expect(n.creadaEn, DateTime.utc(2026, 9, 30, 13));
    expect(n.destino?.pantalla, PantallaNotificacion.justificaciones);
    expect(n.destino?.justificacionId, 'j1');
    expect(n.marcarLeida().leida, isTrue);
  });

  group('PreferenciasNotificacion', () {
    final p = PreferenciasNotificacion.fromJson(const {
      'recordatorioSesion': true,
      'cierreVentana': false,
      'resultadoJustificacion': true,
      'cambioHorario': false,
      'obligatorias': ['cambioHorario'],
    });

    test('las obligatorias siempre quedan activas', () {
      expect(p.esObligatoria('cambioHorario'), isTrue);
      expect(p.valor('cambioHorario'), isTrue);
      expect(p.con('cambioHorario', false), same(p));
    });

    test('las opcionales se cambian y el PUT omite "obligatorias"', () {
      final n = p.con('cierreVentana', true).con('recordatorioSesion', false);
      expect(n.toJson(), {
        'recordatorioSesion': false,
        'cierreVentana': true,
        'resultadoJustificacion': true,
        'cambioHorario': true,
      });
    });
  });
}
