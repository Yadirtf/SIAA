import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:siaa_mobile/core/theme/app_theme.dart';
import 'package:siaa_mobile/features/auth/presentation/bloc/auth_bloc.dart';

class DrawerLogoutTile extends StatelessWidget {
  const DrawerLogoutTile({super.key});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(
        Icons.logout_rounded,
        color: SIAAColors.asistenciaAusente,
        size: 22,
      ),
      title: const Text(
        'Cerrar sesion',
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: SIAAColors.asistenciaAusente,
        ),
      ),
      onTap: () {
        Navigator.of(context).pop();
        context.read<AuthBloc>().add(AuthLogoutRequested());
      },
      contentPadding: const EdgeInsets.symmetric(
        horizontal: SIAASpacing.lg,
        vertical: SIAASpacing.sm,
      ),
    );
  }
}
