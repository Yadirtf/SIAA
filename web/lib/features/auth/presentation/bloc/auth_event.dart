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

  const LoginSubmittedEvent({
    required this.correo,
    required this.password,
  });

  @override
  List<Object?> get props => [correo, password];
}

class LogoutRequestedEvent extends AuthEvent {
  const LogoutRequestedEvent();
}
