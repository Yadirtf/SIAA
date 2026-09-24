// app_shell.dart - Shell coordinador de navegacion por rol (SIAA Movil)
// RF-ROL-001, RF-ROL-003, RF-ROL-004
// Coordinador puro: Ensambla AppBar, Drawer, Pantalla del Registro y BottomNavBar.
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../features/auth/presentation/bloc/auth_bloc.dart';
import '../bloc/nav_bloc.dart';
import '../bloc/nav_event.dart';
import '../bloc/nav_state.dart';
import '../router/nav_screen_registry.dart';
import '../widgets/app_bottom_nav_bar.dart';
import '../widgets/app_shell_app_bar.dart';
import '../widgets/drawer/app_drawer.dart';

class AppShell extends StatelessWidget {
  const AppShell({super.key});

  static const routeName = '/shell';

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, authState) {
        if (authState is AuthAuthenticated) {
          context.read<NavBloc>().add(NavInicializado(
                rolesUsuario: authState.roles,
                permisosUsuario: authState.permisos,
              ));
        } else if (authState is AuthUnauthenticated) {
          Navigator.of(context).pushReplacementNamed('/login');
        }
      },
      child: BlocBuilder<NavBloc, NavState>(
        builder: (context, navState) {
          final bottomItems = navState.bottomItems;

          // Determinar ruta activa
          final currentRoute = _resolveCurrentRoute(navState);

          final safeBottomIndex = bottomItems.isEmpty
              ? 0
              : navState.tabIndex.clamp(0, bottomItems.length - 1);

          final bottomNavIndex =
              navState.activeDrawerRoute != null ? -1 : safeBottomIndex;

          return Scaffold(
            appBar: AppShellAppBar(navState: navState),
            drawer: AppDrawer(
              navState: navState,
              currentRoute: currentRoute,
            ),
            body: NavScreenRegistry.buildScreenForRoute(currentRoute),
            bottomNavigationBar: bottomItems.isEmpty
                ? null
                : AppBottomNavBar(
                    items: bottomItems,
                    currentIndex: bottomNavIndex < 0 ? 0 : bottomNavIndex,
                    onTap: (index) =>
                        context.read<NavBloc>().add(NavTabCambiado(index)),
                  ),
          );
        },
      ),
    );
  }

  String _resolveCurrentRoute(NavState navState) {
    if (navState.activeDrawerRoute != null) {
      return navState.activeDrawerRoute!;
    }
    if (navState.bottomItems.isNotEmpty) {
      final safeIndex =
          navState.tabIndex.clamp(0, navState.bottomItems.length - 1);
      return navState.bottomItems[safeIndex].route;
    }
    return '/shell/perfil';
  }
}
