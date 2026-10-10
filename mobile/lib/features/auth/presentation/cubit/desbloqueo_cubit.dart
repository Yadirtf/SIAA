// desbloqueo_cubit.dart — Verificación local al reabrir la app (US-AUT-06 AC-01..AC-03)
// Ofrece biometría si está configurada; si no, el PIN/patrón del dispositivo (AC-02).
// Tras 3 fallos biométricos exige la contraseña completa (AC-03).
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/auth/biometric_auth_service.dart';

enum EtapaDesbloqueo {
  preparando,
  esperando,
  verificando,
  superado,
  requiereContrasena
}

class DesbloqueoState extends Equatable {
  final EtapaDesbloqueo etapa;
  final bool biometriaDisponible;
  final bool credencialDisponible;
  final String? mensaje;

  const DesbloqueoState({
    this.etapa = EtapaDesbloqueo.preparando,
    this.biometriaDisponible = false,
    this.credencialDisponible = false,
    this.mensaje,
  });

  DesbloqueoState copyWith({EtapaDesbloqueo? etapa, String? mensaje}) =>
      DesbloqueoState(
        etapa: etapa ?? this.etapa,
        biometriaDisponible: biometriaDisponible,
        credencialDisponible: credencialDisponible,
        mensaje: mensaje,
      );

  @override
  List<Object?> get props =>
      [etapa, biometriaDisponible, credencialDisponible, mensaje];
}

class DesbloqueoCubit extends Cubit<DesbloqueoState> {
  final BiometricAuthService _servicio;

  DesbloqueoCubit({BiometricAuthService? servicio})
      : _servicio = servicio ?? BiometricAuthService(),
        super(const DesbloqueoState());

  /// Detecta los mecanismos locales y lanza la biometría de inmediato si existe.
  Future<void> iniciar() async {
    final biometria = await _servicio.isBiometricsAvailable();
    final credencial = await _servicio.isDeviceCredentialAvailable();
    emit(DesbloqueoState(
      etapa: EtapaDesbloqueo.esperando,
      biometriaDisponible: biometria,
      credencialDisponible: credencial,
      mensaje: biometria
          ? null
          : 'Este dispositivo no tiene biometría configurada. '
              'Use el PIN del dispositivo o su contraseña.',
    ));
    if (biometria) await verificarBiometria();
  }

  Future<void> verificarBiometria() async {
    if (state.etapa == EtapaDesbloqueo.verificando) return;
    emit(state.copyWith(etapa: EtapaDesbloqueo.verificando));
    _resolver(await _servicio.authenticate(
      reason: 'Confirme su identidad para reabrir SIAA',
    ));
  }

  Future<void> verificarCredencialDispositivo() async {
    if (state.etapa == EtapaDesbloqueo.verificando) return;
    emit(state.copyWith(etapa: EtapaDesbloqueo.verificando));
    _resolver(await _servicio.autenticarConCredencialDispositivo());
  }

  void _resolver(BiometricAuthResult r) {
    if (isClosed) return;
    if (r.success) {
      emit(state.copyWith(etapa: EtapaDesbloqueo.superado));
    } else if (r.requiresPasswordFallback) {
      // AC-03: tres fallos biométricos (o una sesión ya inexistente) exigen contraseña.
      emit(state.copyWith(
          etapa: EtapaDesbloqueo.requiereContrasena, mensaje: r.errorMessage));
    } else {
      emit(state.copyWith(
        etapa: EtapaDesbloqueo.esperando,
        mensaje: r.cancelado ? null : r.errorMessage,
      ));
    }
  }
}
