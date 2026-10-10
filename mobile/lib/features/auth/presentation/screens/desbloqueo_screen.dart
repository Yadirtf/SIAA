// desbloqueo_screen.dart — Reapertura de sesión con biometría local (US-AUT-06)
// Se muestra en el arranque cuando AuthBloc emite AuthDesbloqueoRequerido. La verificación
// ocurre en el sistema operativo; la app solo recibe el resultado (AC-04).
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/auth/biometric_auth_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../bloc/auth_bloc.dart';
import '../cubit/desbloqueo_cubit.dart';

class DesbloqueoScreen extends StatelessWidget {
  /// Inyectable en pruebas; en producción usa local_auth.
  final BiometricAuthService? servicio;

  const DesbloqueoScreen({super.key, this.servicio});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => DesbloqueoCubit(servicio: servicio)..iniciar(),
      child: BlocConsumer<DesbloqueoCubit, DesbloqueoState>(
        listener: _alCambiar,
        builder: (context, state) => Scaffold(
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: _contenido(context, state),
            ),
          ),
        ),
      ),
    );
  }

  void _alCambiar(BuildContext context, DesbloqueoState state) {
    final auth = context.read<AuthBloc>();
    if (state.etapa == EtapaDesbloqueo.superado) {
      auth.add(AuthDesbloqueoSuperado());
    } else if (state.etapa == EtapaDesbloqueo.requiereContrasena) {
      if (state.mensaje != null) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(state.mensaje!)));
      }
      auth.add(AuthDesbloqueoDescartado());
    }
  }

  Widget _contenido(BuildContext context, DesbloqueoState state) {
    final cubit = context.read<DesbloqueoCubit>();
    final ocupado = state.etapa == EtapaDesbloqueo.preparando ||
        state.etapa == EtapaDesbloqueo.verificando ||
        state.etapa == EtapaDesbloqueo.superado;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Icon(Icons.fingerprint_rounded,
            size: 72, color: SIAAColors.primary500),
        const SizedBox(height: 16),
        Text(
          'Desbloquear SIAA',
          textAlign: TextAlign.center,
          style: SIAATypography.displayLarge.copyWith(fontSize: 26),
        ),
        const SizedBox(height: 8),
        const Text(
          'Confirme su identidad para continuar con su sesión. '
          'La verificación se hace solo en este dispositivo.',
          textAlign: TextAlign.center,
        ),
        if (state.mensaje != null) ...[
          const SizedBox(height: 16),
          Text(state.mensaje!,
              textAlign: TextAlign.center,
              style: TextStyle(color: Theme.of(context).colorScheme.error)),
        ],
        const SizedBox(height: 32),
        if (ocupado)
          const Center(child: CircularProgressIndicator())
        else ...[
          if (state.biometriaDisponible)
            FilledButton.icon(
              onPressed: cubit.verificarBiometria,
              icon: const Icon(Icons.fingerprint_rounded),
              label: const Text('Usar huella o rostro'),
            ),
          if (state.credencialDisponible) ...[
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: cubit.verificarCredencialDispositivo,
              icon: const Icon(Icons.pin_outlined),
              label: const Text('Usar PIN del dispositivo'),
            ),
          ],
        ],
        const SizedBox(height: 12),
        TextButton(
          onPressed: state.etapa == EtapaDesbloqueo.verificando
              ? null
              : () => context.read<AuthBloc>().add(AuthDesbloqueoDescartado()),
          child: const Text('Ingresar con mi contraseña'),
        ),
      ],
    );
  }
}
