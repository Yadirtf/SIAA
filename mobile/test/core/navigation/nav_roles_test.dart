// nav_roles_test.dart — Destinos exactos por rol con los permisos reales del backend
// (internal/domain/rbac/permissions.go) y ninguno apuntando a PlaceholderScreen.
import 'package:flutter_test/flutter_test.dart';
import 'package:siaa_mobile/core/navigation/config/rol_slug.dart';
import 'package:siaa_mobile/core/navigation/navigation.dart';
import 'package:siaa_mobile/shared/widgets/placeholder_screen.dart';

const _docente = [
  'marcaje:crear',
  'marcaje:leer',
  'horario:leer',
  'justificacion:crear',
  'justificacion:leer',
];
const _estudiante = ['marcaje:crear', 'marcaje:leer', 'horario:leer'];
const _monitor = ['marcaje:leer', 'horario:leer', 'reporte:leer'];
const _coordinador = [
  'marcaje:leer',
  'aula:leer',
  'horario:crear',
  'horario:leer',
  'asignacion:crear',
  'asignacion:editar',
  'parametro:leer',
  'usuario:leer',
  'justificacion:aprobar',
  'justificacion:leer',
  'reporte:exportar',
  'reporte:leer',
];
const _admin = [
  'marcaje:leer',
  'marcaje:ajustar',
  'marcaje:anular',
  'aula:leer',
  'aula:crear',
  'aula:editar',
  'aula:editar-geometria',
  'aula:eliminar',
  'sede:administrar',
  'bloque:administrar',
  'horario:crear',
  'horario:leer',
  'asignacion:crear',
  'asignacion:editar',
  'parametro:leer',
  'parametro:editar',
  'usuario:crear',
  'usuario:editar',
  'usuario:leer',
  'justificacion:aprobar',
  'justificacion:leer',
  'reporte:exportar',
  'reporte:leer',
  'auditoria:leer',
  'rol:leer',
];
const _auditor = [
  'marcaje:leer',
  'aula:leer',
  'horario:leer',
  'justificacion:leer',
  'reporte:exportar',
  'reporte:leer',
  'auditoria:leer',
];
const _superadmin = [
  ..._admin,
  'marcaje:crear',
  'justificacion:crear',
  'usuario:eliminar'
];

Future<NavState> _navDe(String rol, List<String> permisos) async {
  final bloc = NavBloc();
  bloc.add(NavInicializado(rolesUsuario: [rol], permisosUsuario: permisos));
  final state = await bloc.stream.first;
  await bloc.close();
  return state;
}

List<String> _rutas(List<NavItem> items) => items.map((i) => i.route).toList();

void _sinPlaceholders(NavState s) {
  for (final item in [
    ...s.bottomItems,
    ...s.drawerExtraItems,
    ...NavDestinations.comunes
  ]) {
    expect(NavScreenRegistry.buildScreenForRoute(item.route),
        isNot(isA<PlaceholderScreen>()),
        reason: '${item.route} no debe llevar a un placeholder');
    expect(item.permiso == null || s.permisosUsuario.contains(item.permiso),
        isTrue,
        reason: '${item.route} exige ${item.permiso}');
  }
}

void main() {
  test('DOCENTE: Inicio, Horario, Historial, Justificar + Marcaje grupal',
      () async {
    final s = await _navDe('DOCENTE', _docente);
    expect(s.rolActivo, 'docente');
    expect(_rutas(s.bottomItems), [
      '/shell/inicio',
      '/shell/horario',
      '/shell/historial',
      '/shell/justificaciones'
    ]);
    expect(_rutas(s.drawerExtraItems), ['/shell/marcaje-grupal']);
    expect(_rutas(s.bottomItems), isNot(contains('/shell/marcajes-admin')));
    _sinPlaceholders(s);
  });

  test('ESTUDIANTE: Inicio, Horario, Historial', () async {
    final s = await _navDe('ESTUDIANTE', _estudiante);
    expect(_rutas(s.bottomItems),
        ['/shell/inicio', '/shell/horario', '/shell/historial']);
    expect(s.drawerExtraItems, isEmpty);
    _sinPlaceholders(s);
  });

  test('MONITOR: Marcajes y Reportes', () async {
    final s = await _navDe('MONITOR', _monitor);
    expect(_rutas(s.bottomItems), ['/shell/marcajes-admin', '/shell/reportes']);
    expect(s.drawerExtraItems, isEmpty);
    _sinPlaceholders(s);
  });

  test(
      'COORDINADOR: Marcajes, Revisión, Reportes + Espacios, Solapamientos, Parámetros',
      () async {
    final s = await _navDe('COORDINADOR', _coordinador);
    expect(_rutas(s.bottomItems), [
      '/shell/marcajes-admin',
      '/shell/aprobar-justificaciones',
      '/shell/reportes'
    ]);
    expect(_rutas(s.drawerExtraItems),
        ['/shell/espacios', '/shell/solapamientos', '/shell/parametros']);
    _sinPlaceholders(s);
  });

  test('ADMIN_INSTITUCIONAL se normaliza a "admin" y ve su matriz completa',
      () async {
    final s = await _navDe('ADMIN_INSTITUCIONAL', _admin);
    expect(s.rolActivo, 'admin');
    expect(_rutas(s.bottomItems),
        ['/shell/espacios', '/shell/editor-gps', '/shell/marcajes-admin']);
    expect(_rutas(s.drawerExtraItems), [
      '/shell/solapamientos',
      '/shell/reportes',
      '/shell/aprobar-justificaciones',
      '/shell/parametros',
    ]);
    _sinPlaceholders(s);
  });

  test('AUDITOR: Marcajes, Reportes, Espacios + Solapamientos', () async {
    final s = await _navDe('AUDITOR', _auditor);
    expect(_rutas(s.bottomItems),
        ['/shell/marcajes-admin', '/shell/reportes', '/shell/espacios']);
    expect(_rutas(s.drawerExtraItems), ['/shell/solapamientos']);
    _sinPlaceholders(s);
  });

  test('SUPERADMIN: vista global', () async {
    final s = await _navDe('SUPERADMIN', _superadmin);
    expect(_rutas(s.bottomItems), [
      '/shell/espacios',
      '/shell/editor-gps',
      '/shell/marcajes-admin',
      '/shell/reportes',
    ]);
    expect(_rutas(s.drawerExtraItems), [
      '/shell/solapamientos',
      '/shell/aprobar-justificaciones',
      '/shell/parametros'
    ]);
    _sinPlaceholders(s);
  });

  test('NavInicializado respeta el rol activo del token', () async {
    final bloc = NavBloc();
    bloc.add(const NavInicializado(
      rolesUsuario: ['DOCENTE', 'COORDINADOR'],
      permisosUsuario: _coordinador,
      rolActivo: 'COORDINADOR',
    ));
    final s = await bloc.stream.first;
    expect(s.rolActivo, 'coordinador');
    expect(s.bottomItems.first, NavDestinations.marcajesAdmin);
    await bloc.close();
  });

  test('rol_slug traduce entre backend y navegación', () {
    expect(rolSlugDe('ADMIN_INSTITUCIONAL'), 'admin');
    expect(rolSlugDe('docente'), 'docente');
    expect(rolBackendDe('admin'), 'ADMIN_INSTITUCIONAL');
    expect(rolBackendDe('coordinador', disponibles: ['DOCENTE', 'COORDINADOR']),
        'COORDINADOR');
    expect(etiquetaRol('MONITOR'), 'Monitor / Auxiliar');
  });
}
