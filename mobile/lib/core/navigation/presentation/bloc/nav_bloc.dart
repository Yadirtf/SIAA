// nav_bloc.dart - BLoC orquestador de navegacion por rol (SIAA Movil)
// RF-ROL-001, RF-ROL-004
import 'package:bloc/bloc.dart';
import '../../config/nav_destinations.dart';
import '../../config/rol_slug.dart';
import '../../domain/services/nav_permission_service.dart';
import 'nav_event.dart';
import 'nav_state.dart';

class NavBloc extends Bloc<NavEvent, NavState> {
  final NavPermissionService _permissionService;

  NavBloc({NavPermissionService? permissionService})
      : _permissionService = permissionService ?? const NavPermissionService(),
        super(const NavState()) {
    on<NavInicializado>(_onInicializado);
    on<NavContextoCambiado>(_onContextoCambiado);
    on<NavTabCambiado>(_onTabCambiado);
    on<NavDrawerItemSelected>(_onDrawerItemSelected);
    on<NavRutaSolicitada>(_onRutaSolicitada);
  }

  void _onInicializado(NavInicializado event, Emitter<NavState> emit) {
    final activo = event.rolActivo;
    final rolInicial = activo != null && activo.isNotEmpty
        ? rolSlugDe(activo)
        : _permissionService.primerRolConConfig(event.rolesUsuario);
    final nav = _permissionService.resolverNavegacion(
      rolInicial,
      event.permisosUsuario,
    );

    emit(state.copyWith(
      rolesDisponibles: event.rolesUsuario,
      permisosUsuario: event.permisosUsuario,
      rolActivo: rolInicial,
      bottomItems: nav.$1,
      drawerExtraItems: nav.$2,
      tabIndex: 0,
      clearDrawerRoute: true,
    ));
  }

  void _onContextoCambiado(NavContextoCambiado event, Emitter<NavState> emit) {
    final slug = rolSlugDe(event.nuevoRolSlug);
    final nav = _permissionService.resolverNavegacion(
      slug,
      state.permisosUsuario,
    );

    emit(state.copyWith(
      rolActivo: slug,
      bottomItems: nav.$1,
      drawerExtraItems: nav.$2,
      tabIndex: 0,
      clearDrawerRoute: true,
    ));
  }

  void _onTabCambiado(NavTabCambiado event, Emitter<NavState> emit) {
    emit(state.copyWith(
      tabIndex: event.nuevoIndex,
      clearDrawerRoute: true,
    ));
  }

  void _onRutaSolicitada(NavRutaSolicitada event, Emitter<NavState> emit) {
    final tab = state.bottomItems.indexWhere((i) => i.route == event.route);
    if (tab >= 0) {
      emit(state.copyWith(
        tabIndex: tab,
        clearDrawerRoute: true,
        sesionIdObjetivo: event.sesionId,
        clearSesionObjetivo: event.sesionId == null,
      ));
      return;
    }
    final permitida =
        state.drawerExtraItems.any((i) => i.route == event.route) ||
            NavDestinations.comunes.any((i) => i.route == event.route) ||
            NavDestinations.sinMenu.any((i) => i.route == event.route);
    if (!permitida) return;
    emit(state.copyWith(
      activeDrawerRoute: event.route,
      sesionIdObjetivo: event.sesionId,
      clearSesionObjetivo: event.sesionId == null,
    ));
  }

  void _onDrawerItemSelected(
    NavDrawerItemSelected event,
    Emitter<NavState> emit,
  ) {
    emit(state.copyWith(activeDrawerRoute: event.route));
  }
}
