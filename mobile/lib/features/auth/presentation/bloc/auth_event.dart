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
