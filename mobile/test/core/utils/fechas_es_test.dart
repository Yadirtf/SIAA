// fechas_es_test.dart — Formato de horas en 12 h con a. m./p. m.
import 'package:flutter_test/flutter_test.dart';
import 'package:siaa_mobile/core/utils/fechas_es.dart';

void main() {
  group('hora12hDe', () {
    test('distingue mañana, tarde, mediodía y medianoche', () {
      expect(hora12hDe(6, 30), '6:30 a. m.');
      expect(hora12hDe(18, 30), '6:30 p. m.');
      expect(hora12hDe(12, 0), '12:00 p. m.');
      expect(hora12hDe(0, 5), '12:05 a. m.');
    });
  });

  group('hora12hDesdeTexto', () {
    test('convierte la hora de 24 h que envía el backend', () {
      expect(hora12hDesdeTexto('18:30'), '6:30 p. m.');
      expect(hora12hDesdeTexto('07:05'), '7:05 a. m.');
    });

    test('deja igual un texto que no es hora', () {
      expect(hora12hDesdeTexto('--:--'), '--:--');
      expect(hora12hDesdeTexto('25:00'), '25:00');
    });
  });

  test('hora12h usa la hora local, no la UTC', () {
    final utc = DateTime.parse('2026-10-01T23:30:00Z');
    final local = utc.toLocal();
    expect(hora12h(utc), hora12hDe(local.hour, local.minute));
  });

  test('fechaHora incluye a. m./p. m.', () {
    expect(fechaHora(DateTime(2026, 10, 1, 18, 30)), '01/10/2026 6:30 p. m.');
  });

  test('horasEnTexto12h convierte nombres de sesión antiguos', () {
    expect(horasEnTexto12h('2026-10-01 18:30-19:30'),
        '2026-10-01 6:30 p. m.-7:30 p. m.');
    expect(horasEnTexto12h('Cálculo 7:00 a. m.'), 'Cálculo 7:00 a. m.');
  });
}
