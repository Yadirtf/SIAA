import 'package:equatable/equatable.dart';

import '../../data/models/segundo_factor_model.dart';
import '../../data/models/user_model.dart';

abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {
  const AuthInitial();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

class Authenticated extends AuthState {
  final UserModel user;

  const Authenticated(this.user);

  @override
  List<Object?> get props => [user];
}

class Unauthenticated extends AuthState {
  final String? message;

  const Unauthenticated({this.message});

  @override
  List<Object?> get props => [message];
}

class AuthFailure extends AuthState {
  final String errorMessage;

  const AuthFailure(this.errorMessage);

  @override
  List<Object?> get props => [errorMessage];
}

/// La contraseña fue válida pero falta el segundo factor (US-AUT-05). Si [enrolamiento]
/// no es nulo, el usuario debe registrar la clave en su app autenticadora primero.
class SegundoFactorRequerido extends AuthState {
  final String correo;
  final DesafioTotp desafio;
  final TotpEnrolamiento? enrolamiento;
  final bool enviando;
  final String? error;

  const SegundoFactorRequerido({
    required this.correo,
    required this.desafio,
    this.enrolamiento,
    this.enviando = false,
    this.error,
  });

  SegundoFactorRequerido copyWith({bool? enviando, String? error}) =>
      SegundoFactorRequerido(
        correo: correo,
        desafio: desafio,
        enrolamiento: enrolamiento,
        enviando: enviando ?? this.enviando,
        error: error,
      );

  @override
  List<Object?> get props => [correo, desafio, enrolamiento, enviando, error];
}
