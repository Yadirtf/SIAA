import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class CheckAuthStatusEvent extends AuthEvent {
  const CheckAuthStatusEvent();
}

class LoginSubmittedEvent extends AuthEvent {
  final String correo;
  final String password;

  const LoginSubmittedEvent({required this.correo, required this.password});

  @override
  List<Object?> get props => [correo, password];
}

class LogoutRequestedEvent extends AuthEvent {
  const LogoutRequestedEvent();
}

/// Código TOTP (o de respaldo) para el desafío pendiente (US-AUT-05).
class SegundoFactorEnviadoEvent extends AuthEvent {
  final String codigo;

  const SegundoFactorEnviadoEvent(this.codigo);

  @override
  List<Object?> get props => [codigo];
}

/// Abandona el segundo factor y vuelve al formulario de contraseña.
class SegundoFactorCanceladoEvent extends AuthEvent {
  const SegundoFactorCanceladoEvent();
}
