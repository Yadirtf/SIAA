// auth_state.dart — Estados del BLoC de autenticación (US-AUT-01, US-AUT-03, US-AUT-04)
import 'package:equatable/equatable.dart';
import '../../data/segundo_factor.dart';

// ─── ESTADOS ──────────────────────────────────────────────────────────────────

abstract class AuthState extends Equatable {
  const AuthState();
  @override
  List<Object?> get props => [];
}

/// Estado inicial: verificando si hay sesion guardada.
class AuthInitial extends AuthState {}

/// Verificando sesion existente al arrancar la app.
class AuthCheckingSession extends AuthState {}

/// Usuario autenticado con sesion valida.
class AuthAuthenticated extends AuthState {
  final String usuarioId;
  final String nombre;
  final String correo;
  final List<String> roles;

  /// Permisos resueltos por el backend en formato recurso:accion.
  /// El cliente los consume para filtrar la navegacion; NO los recalcula.
  final List<String> permisos;

  /// Rol cuyos permisos lleva el token (vacío = primer rol de [roles]).
  final String rolActivo;

  /// Mensaje cuando falló el último cambio de contexto (la sesión sigue igual).
  final String? avisoContexto;

  const AuthAuthenticated({
    required this.usuarioId,
    required this.nombre,
    required this.roles,
    this.permisos = const [],
    this.correo = '',
    this.rolActivo = '',
    this.avisoContexto,
  });

  AuthAuthenticated conAviso(String? aviso) => AuthAuthenticated(
        usuarioId: usuarioId,
        nombre: nombre,
        correo: correo,
        roles: roles,
        permisos: permisos,
        rolActivo: rolActivo,
        avisoContexto: aviso,
      );

  @override
  List<Object?> get props =>
      [usuarioId, nombre, roles, permisos, rolActivo, avisoContexto];
}

/// Hay una sesión guardada, pero antes de restaurarla se exige verificación local
/// con biometría o el PIN del dispositivo (US-AUT-06).
class AuthDesbloqueoRequerido extends AuthState {}

/// No hay sesion activa: mostrar pantalla de login.
class AuthUnauthenticated extends AuthState {}

/// Cargando (login en proceso).
class AuthLoading extends AuthState {}

/// Error de autenticacion con mensaje para el usuario.
class AuthError extends AuthState {
  final String message;
  final String? code;
  const AuthError({required this.message, this.code});
  @override
  List<Object?> get props => [message, code];
}

/// Correo de recuperacion enviado correctamente.
class AuthRecuperarEnviado extends AuthState {}

/// Contrasena cambiada correctamente.
class AuthPasswordCambiado extends AuthState {}

/// Dispositivo móvil pendiente de aprobación por el administrador (US-AUT-03 AC-03).
class AuthDispositivoPendiente extends AuthState {
  final String mensaje;
  final String dispositivoId;
  const AuthDispositivoPendiente({
    required this.mensaje,
    required this.dispositivoId,
  });
  @override
  List<Object?> get props => [mensaje, dispositivoId];
}

/// Contraseña válida pero falta el segundo factor (US-AUT-05). Con [enrolamiento] el
/// usuario debe registrar la clave en su app autenticadora antes del primer código.
class AuthSegundoFactorRequerido extends AuthState {
  final DesafioTotp desafio;
  final TotpEnrolamiento? enrolamiento;
  final bool enviando;
  final String? error;

  const AuthSegundoFactorRequerido({
    required this.desafio,
    this.enrolamiento,
    this.enviando = false,
    this.error,
  });

  AuthSegundoFactorRequerido copyWith({bool? enviando, String? error}) =>
      AuthSegundoFactorRequerido(
        desafio: desafio,
        enrolamiento: enrolamiento,
        enviando: enviando ?? this.enviando,
        error: error,
      );

  @override
  List<Object?> get props => [desafio.token, enviando, error];
}
