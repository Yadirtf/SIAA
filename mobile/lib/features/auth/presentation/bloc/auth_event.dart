// auth_event.dart — Eventos del BLoC de autenticación (US-AUT-01, US-AUT-04, US-ROL-04)
import 'package:equatable/equatable.dart';

// ─── EVENTOS ──────────────────────────────────────────────────────────────────

abstract class AuthEvent extends Equatable {
  const AuthEvent();
  @override
  List<Object?> get props => [];
}

class AuthLoginRequested extends AuthEvent {
  final String correo;
  final String password;
  const AuthLoginRequested({required this.correo, required this.password});
  @override
  List<Object?> get props => [correo];
}

class AuthRecuperarSolicitado extends AuthEvent {
  final String correo;
  const AuthRecuperarSolicitado({required this.correo});
  @override
  List<Object?> get props => [correo];
}

class AuthNuevoPasswordConfirmado extends AuthEvent {
  final String token;
  final String password;
  const AuthNuevoPasswordConfirmado(
      {required this.token, required this.password});
}

class AuthLogoutRequested extends AuthEvent {}

class AuthSessionChecked extends AuthEvent {}

/// Cambio de contexto de rol (RF-ROL-004): POST /auth/contexto emite un token con los
/// permisos del rol elegido. [rol] es el nombre del backend (p. ej. COORDINADOR).
class AuthContextoSolicitado extends AuthEvent {
  final String rol;
  const AuthContextoSolicitado(this.rol);
  @override
  List<Object?> get props => [rol];
}

/// Código TOTP (o de respaldo) para el desafío pendiente (US-AUT-05).
class AuthSegundoFactorEnviado extends AuthEvent {
  final String codigo;
  const AuthSegundoFactorEnviado(this.codigo);
  @override
  List<Object?> get props => [codigo];
}

/// Abandona el segundo factor y vuelve al formulario.
class AuthSegundoFactorCancelado extends AuthEvent {}

/// Verificación local superada en la pantalla de desbloqueo (US-AUT-06 AC-01):
/// se restaura la sesión guardada sin reescribir credenciales.
class AuthDesbloqueoSuperado extends AuthEvent {}

/// El usuario elige su contraseña o agotó los 3 intentos (US-AUT-06 AC-03):
/// se descarta la sesión guardada y se exige el formulario completo.
class AuthDesbloqueoDescartado extends AuthEvent {}
