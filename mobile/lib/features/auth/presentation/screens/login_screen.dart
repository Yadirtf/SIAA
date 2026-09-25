// Pantalla de login - T-AUT-01.7, US-AUT-01
// Diseno modularizado con LoginHeader y LoginFormCard desacoplados.
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/navigation/nav_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import '../bloc/auth_bloc.dart';
import '../widgets/dispositivo_pendiente_dialog.dart';
import '../widgets/login_form_card.dart';
import '../widgets/login_header.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  static const routeName = '/login';

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthAuthenticated) {
            // Inicializar el NavBloc con los roles y permisos resueltos
            // por el backend antes de navegar al shell (RF-ROL-003).
            context.read<NavBloc>().add(NavInicializado(
                  rolesUsuario: state.roles,
                  permisosUsuario: state.permisos,
                ));
            Navigator.of(context).pushReplacementNamed('/shell');
          }
          if (state is AuthDispositivoPendiente) {
            DispositivoPendienteDialog.show(
              context,
              mensaje: state.mensaje,
            );
          }
          if (state is AuthError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(children: [
                  const Icon(Icons.error_outline, color: Colors.white),
                  const SizedBox(width: 8),
                  Expanded(child: Text(state.message)),
                ]),
                backgroundColor: SIAAColors.asistenciaAusente,
                behavior: SnackBarBehavior.floating,
                shape: const RoundedRectangleBorder(
                  borderRadius: SIAASpacing.radiusSm,
                ),
              ),
            );
          }
        },
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [
                      SIAAColors.backgroundDark,
                      const Color(0xFF0D2347),
                      SIAAColors.backgroundDark,
                    ]
                  : [
                      SIAAColors.primary50,
                      SIAAColors.backgroundLight,
                      const Color(0xFFEFF6FF),
                    ],
            ),
          ),
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(SIAASpacing.xl),
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 440),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        LoginHeader(),
                        SizedBox(height: SIAASpacing.xxl),
                        LoginFormCard(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
