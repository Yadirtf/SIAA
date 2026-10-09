// biometria_switch_tile.dart — Interruptor "Reabrir con biometría" del perfil (US-AUT-06)
// Se oculta si el dispositivo no tiene biometría ni PIN propio.
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/auth/biometric_auth_service.dart';
import '../../../../core/auth/preferencia_biometria.dart';
import '../cubit/preferencia_biometria_cubit.dart';

class BiometriaSwitchTile extends StatelessWidget {
  final BiometricAuthService? servicio;
  final PreferenciaBiometria? preferencia;

  const BiometriaSwitchTile({super.key, this.servicio, this.preferencia});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => PreferenciaBiometriaCubit(
        servicio: servicio,
        preferencia: preferencia,
      )..cargar(),
      child: BlocBuilder<PreferenciaBiometriaCubit, PreferenciaBiometriaState>(
        builder: (context, state) {
          if (!state.disponible) return const SizedBox.shrink();
          final subtitulo = state.mensaje ??
              (state.soloCredencial
                  ? 'Pedir el PIN del dispositivo al abrir la app'
                  : 'Pedir huella o rostro al abrir la app, sin contraseña');
          return SwitchListTile(
            contentPadding: EdgeInsets.zero,
            secondary: const Icon(Icons.fingerprint_rounded),
            title: const Text('Reabrir con biometría'),
            subtitle: Text(subtitulo),
            value: state.habilitada,
            onChanged: state.cargando
                ? null
                : context.read<PreferenciaBiometriaCubit>().cambiar,
          );
        },
      ),
    );
  }
}
