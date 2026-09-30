import 'package:flutter_test/flutter_test.dart';
import 'package:siaa_web/core/utils/busqueda_texto.dart';

void main() {
  test('normalizarBusqueda ignora tildes y mayúsculas', () {
    expect(normalizarBusqueda('  Ingeniería ÑANDÚ '), 'ingenieria nandu');
  });

  test('filtrarPorTexto exige todas las palabras en cualquier orden', () {
    final items = ['A-101 · Aula Magna', 'B-202 · Laboratorio', 'A-102 · Sala'];
    expect(filtrarPorTexto(items, (s) => s, 'magna a-101'), [items[0]]);
    expect(filtrarPorTexto(items, (s) => s, 'laboratório'), [items[1]]);
    expect(filtrarPorTexto(items, (s) => s, ''), items);
    expect(filtrarPorTexto(items, (s) => s, '', limite: 2), items.take(2));
  });
}
