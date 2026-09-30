// drawer_notificaciones_tile.dart — Entrada de la bandeja con contador de no leídas (US-NOT-01)
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../features/notificaciones/presentation/cubit/bandeja_cubit.dart';
import '../../../../../features/notificaciones/presentation/cubit/bandeja_state.dart';
import '../../../config/nav_destinations.dart';
import '../../bloc/nav_bloc.dart';
import '../../bloc/nav_event.dart';
import 'drawer_nav_item_tile.dart';

class DrawerNotificacionesTile extends StatelessWidget {
  final bool isSelected;

  const DrawerNotificacionesTile({super.key, required this.isSelected});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BandejaCubit, BandejaState>(
      buildWhen: (a, b) => a.noLeidas != b.noLeidas,
      builder: (context, state) => DrawerNavItemTile(
        item: NavDestinations.notificaciones,
        isSelected: isSelected,
        trailing: state.noLeidas == 0
            ? null
            : Badge(label: Text('${state.noLeidas}')),
        onTap: () {
          Navigator.of(context).pop();
          context.read<NavBloc>().add(
                NavDrawerItemSelected(NavDestinations.notificaciones.route),
              );
        },
      ),
    );
  }
}
