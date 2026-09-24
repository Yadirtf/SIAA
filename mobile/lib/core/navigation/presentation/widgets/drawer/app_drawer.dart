import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:siaa_mobile/core/theme/app_theme.dart';
import 'package:siaa_mobile/features/auth/presentation/bloc/auth_bloc.dart';
import '../../../config/nav_destinations.dart';
import '../../bloc/nav_bloc.dart';
import '../../bloc/nav_event.dart';
import '../../bloc/nav_state.dart';
import 'drawer_logout_tile.dart';
import 'drawer_nav_item_tile.dart';
import 'drawer_section_title.dart';
import 'drawer_user_header.dart';
import 'role_context_selector.dart';

class AppDrawer extends StatelessWidget {
  final NavState navState;
  final String currentRoute;

  const AppDrawer({
    super.key,
    required this.navState,
    required this.currentRoute,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final authState = context.watch<AuthBloc>().state;
    final nombre =
        (authState is AuthAuthenticated && authState.nombre.isNotEmpty)
            ? authState.nombre
            : 'Usuario';

    return Drawer(
      backgroundColor:
          isDark ? SIAAColors.surfaceDark : SIAAColors.surfaceLight,
      child: SafeArea(
        child: Column(
          children: [
            DrawerUserHeader(nombre: nombre),
            RoleContextSelector(navState: navState),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: SIAASpacing.xs),
                children: [
                  if (navState.drawerExtraItems.isNotEmpty) ...[
                    const DrawerSectionTitle('Modulos'),
                    ...navState.drawerExtraItems.map(
                      (item) => DrawerNavItemTile(
                        item: item,
                        isSelected: currentRoute == item.route,
                        onTap: () {
                          Navigator.of(context).pop();
                          context
                              .read<NavBloc>()
                              .add(NavDrawerItemSelected(item.route));
                        },
                      ),
                    ),
                    const Divider(height: 1),
                  ],
                  const DrawerSectionTitle('Cuenta'),
                  DrawerNavItemTile(
                    item: NavDestinations.perfil,
                    isSelected: currentRoute == NavDestinations.perfil.route,
                    onTap: () {
                      Navigator.of(context).pop();
                      context.read<NavBloc>().add(
                            NavDrawerItemSelected(NavDestinations.perfil.route),
                          );
                    },
                  ),
                  DrawerNavItemTile(
                    item: NavDestinations.privacidad,
                    isSelected:
                        currentRoute == NavDestinations.privacidad.route,
                    onTap: () {
                      Navigator.of(context).pop();
                      context.read<NavBloc>().add(
                            NavDrawerItemSelected(
                                NavDestinations.privacidad.route),
                          );
                    },
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            const DrawerLogoutTile(),
          ],
        ),
      ),
    );
  }
}
