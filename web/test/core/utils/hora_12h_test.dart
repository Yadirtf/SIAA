import 'package:flutter_test/flutter_test.dart';
import 'package:siaa_web/core/utils/formatos.dart';
import 'package:siaa_web/core/utils/hora_12h.dart';

void main() {
  test('convierte 24 h a 12 h con a. m./p. m.', () {
    expect(hora12h(0, 5), '12:05 a. m.');
    expect(hora12h(6, 30), '6:30 a. m.');
    expect(hora12h(12, 0), '12:00 p. m.');
    expect(hora12h(18, 30), '6:30 p. m.');
    expect(hora12h(23, 59), '11:59 p. m.');
  });

  test('desde texto HH:mm y deja igual lo que no es hora', () {
    expect(hora12hDesdeTexto('06:30'), '6:30 a. m.');
    expect(hora12hDesdeTexto('18:30'), '6:30 p. m.');
    expect(hora12hDesdeTexto(''), '');
    expect(hora12hDesdeTexto('25:00'), '25:00');
  });

  test('horasEnTexto12h convierte nombres de sesión antiguos', () {
    expect(
      horasEnTexto12h('2026-10-01 18:30-19:30'),
      '2026-10-01 6:30 p. m.-7:30 p. m.',
    );
    // Lo que ya está en 12 h no se toca.
    expect(
      horasEnTexto12h('6:30 p. m. - 7:30 p. m.'),
      '6:30 p. m. - 7:30 p. m.',
    );
  });

  test('Formatos muestra fecha y hora con a. m./p. m.', () {
    final d = DateTime(2026, 10, 1, 18, 5, 9);
    expect(Formatos.fechaHora(d), '2026-10-01 6:05 p. m.');
    expect(Formatos.fechaHoraSegundos(d), '2026-10-01 6:05:09 p. m.');
    expect(
      Formatos.fechaHora(DateTime(2026, 10, 1, 0, 15)),
      '2026-10-01 12:15 a. m.',
    );
    expect(Formatos.fechaHora(null), '—');
  });
}
