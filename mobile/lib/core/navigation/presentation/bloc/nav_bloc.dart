// nav_bloc.dart - BLoC orquestador de navegacion por rol (SIAA Movil)
// RF-ROL-001, RF-ROL-004
import 'package:bloc/bloc.dart';
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
  }

  void _onInicializado(NavInicializado event, Emitter<NavState> emit) {
    final rolInicial =
        _permissionService.primerRolConConfig(event.rolesUsuario);
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
    final nav = _permissionService.resolverNavegacion(
      event.nuevoRolSlug,
      state.permisosUsuario,
    );

    emit(state.copyWith(
      rolActivo: event.nuevoRolSlug,
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

  void _onDrawerItemSelected(
    NavDrawerItemSelected event,
    Emitter<NavState> emit,
  ) {
    emit(state.copyWith(activeDrawerRoute: event.route));
  }
}
