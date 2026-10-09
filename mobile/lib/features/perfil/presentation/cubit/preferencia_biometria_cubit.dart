// preferencia_biometria_cubit.dart — Activar/desactivar la reapertura con biometría (US-AUT-06)
// Activarla exige una verificación local previa para confirmar que el titular la configura.
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/auth/biometric_auth_service.dart';
import '../../../../core/auth/preferencia_biometria.dart';

class PreferenciaBiometriaState extends Equatable {
  final bool cargando;

  /// El dispositivo tiene biometría o, al menos, PIN/patrón propio.
  final bool disponible;
  final bool soloCredencial;
  final bool habilitada;
  final String? mensaje;

  const PreferenciaBiometriaState({
    this.cargando = true,
    this.disponible = false,
    this.soloCredencial = false,
    this.habilitada = false,
    this.mensaje,
  });

  PreferenciaBiometriaState copyWith(
          {bool? cargando, bool? habilitada, String? mensaje}) =>
      PreferenciaBiometriaState(
        cargando: cargando ?? this.cargando,
        disponible: disponible,
        soloCredencial: soloCredencial,
        habilitada: habilitada ?? this.habilitada,
        mensaje: mensaje,
      );

  @override
  List<Object?> get props =>
      [cargando, disponible, soloCredencial, habilitada, mensaje];
}

class PreferenciaBiometriaCubit extends Cubit<PreferenciaBiometriaState> {
  final BiometricAuthService _servicio;
  final PreferenciaBiometria _preferencia;

  PreferenciaBiometriaCubit({
    BiometricAuthService? servicio,
    PreferenciaBiometria? preferencia,
  })  : _servicio = servicio ?? BiometricAuthService(),
        _preferencia = preferencia ?? PreferenciaBiometria(),
        super(const PreferenciaBiometriaState());

  Future<void> cargar() async {
    final biometria = await _servicio.isBiometricsAvailable();
    final credencial =
        biometria || await _servicio.isDeviceCredentialAvailable();
    final habilitada = await _preferencia.habilitada();
    if (isClosed) return;
    emit(PreferenciaBiometriaState(
      cargando: false,
      disponible: credencial,
      soloCredencial: !biometria && credencial,
      habilitada: habilitada,
    ));
  }

  Future<void> cambiar(bool habilitar) async {
    if (state.cargando || !state.disponible) return;
    emit(state.copyWith(cargando: true));
    if (habilitar) {
      final r = state.soloCredencial
          ? await _servicio.autenticarConCredencialDispositivo(
              reason: 'Confirme su identidad para activar el desbloqueo local')
          : await _servicio.authenticate(
              reason: 'Confirme su identidad para activar la biometría');
      if (!r.success) {
        if (!isClosed) {
          emit(state.copyWith(
            cargando: false,
            mensaje: r.cancelado ? null : 'No se activó: ${r.errorMessage}',
          ));
        }
        return;
      }
    }
    await _preferencia.guardar(habilitar);
    if (!isClosed) emit(state.copyWith(cargando: false, habilitada: habilitar));
  }
}
