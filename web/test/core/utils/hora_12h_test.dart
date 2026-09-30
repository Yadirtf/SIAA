import 'package:flutter_test/flutter_test.dart';
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
}
