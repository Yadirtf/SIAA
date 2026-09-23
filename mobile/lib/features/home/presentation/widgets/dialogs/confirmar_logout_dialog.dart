import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../auth/presentation/bloc/auth_bloc.dart';

/// Diálogo modal de confirmación de cierre de sesión.
class ConfirmarLogoutDialog extends StatelessWidget {
  const ConfirmarLogoutDialog({super.key});

  static Future<void> mostrar(BuildContext context) {
    return showDialog(
      context: context,
      builder: (_) => const ConfirmarLogoutDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Cerrar sesión'),
      content: const Text('¿Está seguro de que desea salir del sistema SIAA?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: SIAAColors.asistenciaAusente),
          onPressed: () {
            Navigator.of(context).pop();
            context.read<AuthBloc>().add(AuthLogoutRequested());
          },
          child: const Text('Salir', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}
