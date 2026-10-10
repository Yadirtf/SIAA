import 'package:flutter_test/flutter_test.dart';
import 'package:siaa_web/features/dashboard/presentation/models/nav_item.dart';

void main() {
  Set<NavSection> visibles(List<String> permisos) =>
      NavItem.visiblesPara(permisos).map((i) => i.section).toSet();

  test('tablero y ocupación exigen reporte:leer', () {
    expect(visibles(const []), isNot(contains(NavSection.tablero)));
    expect(
      visibles(const ['reporte:leer']),
      containsAll([NavSection.tablero, NavSection.ocupacion]),
    );
  });

  test('la asistencia estudiantil la ve el docente (marcaje:leer)', () {
    final docente = visibles(const ['marcaje:leer', 'horario:leer']);
    expect(docente, contains(NavSection.asistenciaEstudiantil));
    expect(docente, isNot(contains(NavSection.tablero)));
  });
}
