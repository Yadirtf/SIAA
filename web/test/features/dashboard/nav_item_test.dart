import 'package:flutter_test/flutter_test.dart';
import 'package:siaa_web/features/dashboard/presentation/models/nav_item.dart';

void main() {
  Set<NavSection> visibles(List<String> permisos) =>
      NavItem.visiblesPara(permisos).map((i) => i.section).toSet();

  test('justificaciones, reportes y auditoría exigen su permiso', () {
    final sinPermisos = visibles(const []);
    expect(sinPermisos, isNot(contains(NavSection.justificaciones)));
    expect(sinPermisos, isNot(contains(NavSection.reportes)));
    expect(sinPermisos, isNot(contains(NavSection.auditoria)));

    final todos = visibles(const [
      'justificacion:leer',
      'reporte:leer',
      'auditoria:leer',
    ]);
    expect(
      todos,
      containsAll([
        NavSection.justificaciones,
        NavSection.reportes,
        NavSection.auditoria,
      ]),
    );
  });

  test('aprobar o exportar sin leer no muestra la entrada', () {
    final s = visibles(const ['justificacion:aprobar', 'reporte:exportar']);
    expect(s, isNot(contains(NavSection.justificaciones)));
    expect(s, isNot(contains(NavSection.reportes)));
  });
}
