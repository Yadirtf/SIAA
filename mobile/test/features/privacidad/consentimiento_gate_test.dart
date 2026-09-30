// consentimiento_gate_test.dart — Compuerta de consentimiento (US-LEG-01, CA-011)
import 'package:flutter_test/flutter_test.dart';
import 'package:siaa_mobile/features/privacidad/data/consentimiento_gate.dart';
import 'package:siaa_mobile/features/privacidad/domain/models/estado_consentimiento.dart';

EstadoConsentimiento estado({
  String vigente = '2.0',
  bool requiere = true,
  String? decision,
  String? decidida,
}) =>
    EstadoConsentimiento(
      versionVigente: vigente,
      requiereAceptacion: requiere,
      decision: decision,
      versionDecidida: decidida,
    );

void main() {
  group('EstadoConsentimiento', () {
    test('pendiente: sin decisión debe preguntar', () {
      final c = EstadoConsentimiento.fromJson(const {
        'versionVigente': '1.0',
        'requiereAceptacion': true,
        'decision': null,
        'versionDecidida': null,
        'decididoEn': null,
      });
      expect(c.debePreguntar, isTrue);
      expect(c.otorgado, isFalse);
      expect(c.rechazadoVigente, isFalse);
    });

    test('aceptado: no pregunta y otorga', () {
      final c = EstadoConsentimiento.fromJson(const {
        'versionVigente': '1.0',
        'requiereAceptacion': false,
        'decision': 'ACEPTADO',
        'versionDecidida': '1.0',
        'decididoEn': '2026-09-30T10:00:00Z',
      });
      expect(c.otorgado, isTrue);
      expect(c.debePreguntar, isFalse);
      expect(c.decididoEn, DateTime.utc(2026, 9, 30, 10));
    });

    test('rechazado sobre la versión vigente: no re-pregunta pero no otorga',
        () {
      final c = estado(decision: 'RECHAZADO', decidida: '2.0');
      expect(c.rechazadoVigente, isTrue);
      expect(c.debePreguntar, isFalse);
      expect(c.otorgado, isFalse);
    });

    test('nueva versión: aceptación antigua vuelve a preguntar', () {
      expect(
          estado(decision: 'ACEPTADO', decidida: '1.0').debePreguntar, isTrue);
      expect(
          estado(decision: 'RECHAZADO', decidida: '1.0').debePreguntar, isTrue);
    });
  });

  group('ConsentimientoGate', () {
    late String? guardada;
    late ConsentimientoGate gate;

    setUp(() {
      guardada = null;
      gate = ConsentimientoGate(
        leerVersion: () async => guardada,
        guardarVersion: (v) async => guardada = v,
      );
    });

    test('desconocido no permite ubicación pero sí sincronizar', () {
      expect(gate.estado, EstadoGateConsentimiento.desconocido);
      expect(gate.permiteUbicacion, isFalse);
      expect(gate.permiteSincronizar, isTrue);
    });

    test('restaurar con aceptación guardada habilita (arranque offline)',
        () async {
      guardada = '1.0';
      await gate.restaurar();
      expect(gate.permiteUbicacion, isTrue);
    });

    test('aplicar aceptado persiste la versión; pendiente/rechazado la borran',
        () async {
      await gate.aplicar(estado(requiere: false, decision: 'ACEPTADO'));
      expect(gate.estado, EstadoGateConsentimiento.otorgado);
      expect(guardada, '2.0');

      await gate.aplicar(estado(decision: 'ACEPTADO', decidida: '1.0'));
      expect(gate.estado, EstadoGateConsentimiento.pendiente);
      expect(guardada, isNull);
      expect(gate.permiteSincronizar, isFalse);

      await gate.aplicar(estado(decision: 'RECHAZADO', decidida: '2.0'));
      expect(gate.estado, EstadoGateConsentimiento.rechazado);
      expect(gate.permiteUbicacion, isFalse);
    });

    test('marcarRequerido (403) revoca el permiso local', () async {
      await gate.aplicar(estado(requiere: false));
      await gate.marcarRequerido();
      expect(gate.estado, EstadoGateConsentimiento.pendiente);
      expect(gate.permiteUbicacion, isFalse);
      expect(guardada, isNull);
    });

    test('reiniciar (logout) vuelve a desconocido', () async {
      await gate.aplicar(estado(requiere: false));
      await gate.reiniciar();
      expect(gate.estado, EstadoGateConsentimiento.desconocido);
      expect(guardada, isNull);
    });
  });
}
