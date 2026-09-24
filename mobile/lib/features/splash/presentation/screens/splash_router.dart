// splash_router.dart - Enrutador inicial basado en estado de sesion
// RF-ROL-001, RF-ROL-003
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/navigation/presentation/bloc/nav_bloc.dart';
import '../../../../core/navigation/presentation/bloc/nav_event.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import 'splash_screen.dart';

/// Router inicial que escucha AuthBloc y redirige a /shell o /login.
class SplashRouter extends StatelessWidget {
  const SplashRouter({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthAuthenticated) {
          // Inicializar NavBloc con los roles y permisos resueltos por el backend (RF-ROL-003).
          context.read<NavBloc>().add(NavInicializado(
                rolesUsuario: state.roles,
                permisosUsuario: state.permisos,
              ));
          Navigator.of(context).pushReplacementNamed('/shell');
        } else if (state is AuthUnauthenticated) {
          Navigator.of(context).pushReplacementNamed('/login');
        }
      },
      child: const SplashScreen(),
    );
  }
}
