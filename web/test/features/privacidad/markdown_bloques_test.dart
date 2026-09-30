import 'package:flutter_test/flutter_test.dart';
import 'package:siaa_web/features/privacidad/presentation/widgets/markdown_bloques.dart';

void main() {
  test('reconoce encabezados, párrafos y listas', () {
    const md = '''
# Aviso de privacidad

Tratamos sus datos
conforme a la Ley 1581.

## Finalidades
- Registrar la asistencia
* Auditar marcajes
  con evidencia técnica
1. Primero
2) Segundo
''';
    expect(parsearMarkdown(md), const [
      BloqueMd(TipoBloqueMd.encabezado, 'Aviso de privacidad', nivel: 1),
      BloqueMd(
        TipoBloqueMd.parrafo,
        'Tratamos sus datos conforme a la Ley 1581.',
      ),
      BloqueMd(TipoBloqueMd.encabezado, 'Finalidades', nivel: 2),
      BloqueMd(TipoBloqueMd.vineta, 'Registrar la asistencia'),
      BloqueMd(TipoBloqueMd.vineta, 'Auditar marcajes con evidencia técnica'),
      BloqueMd(TipoBloqueMd.numerada, 'Primero', nivel: 1),
      BloqueMd(TipoBloqueMd.numerada, 'Segundo', nivel: 2),
    ]);
  });

  test('énfasis en línea sin romper snake_case', () {
    final t = parsearEnLinea(
      'Use **SIAA** y *no* toque retencion_coordenadas_dias',
    );
    expect(
      t.map((e) => e.texto).join(),
      'Use SIAA y no toque retencion_coordenadas_dias',
    );
    expect(t[1].negrita, isTrue);
    expect(t[3].cursiva, isTrue);
    expect(t.last.negrita || t.last.cursiva, isFalse);
  });
}
