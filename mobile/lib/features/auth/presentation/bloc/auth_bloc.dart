// BLoC de autenticacion - US-AUT-01, US-AUT-04
// Gestiona el estado de login, recuperacion de contrasena y sesion.
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../data/auth_repository.dart';
import '../../../../core/storage/secure_storage.dart';

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
  final List<String> roles;

  /// Permisos resueltos por el backend en formato recurso:accion.
  /// El cliente los consume para filtrar la navegacion; NO los recalcula.
  final List<String> permisos;
  const AuthAuthenticated({
    required this.usuarioId,
    required this.nombre,
    required this.roles,
    this.permisos = const [],
  });
  @override
  List<Object?> get props => [usuarioId, roles, permisos];
}

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

// ─── BLOC ─────────────────────────────────────────────────────────────────────

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _repository;

  AuthBloc({required AuthRepository repository})
      : _repository = repository,
        super(AuthInitial()) {
    on<AuthSessionChecked>(_onSessionChecked);
    on<AuthLoginRequested>(_onLoginRequested);
    on<AuthRecuperarSolicitado>(_onRecuperarSolicitado);
    on<AuthNuevoPasswordConfirmado>(_onNuevoPasswordConfirmado);
    on<AuthLogoutRequested>(_onLogoutRequested);
  }

  /// Verifica si existe una sesion guardada al abrir la app.
  Future<void> _onSessionChecked(
    AuthSessionChecked event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthCheckingSession());
    final token = await SecureStorage.getAccessToken();
    if (token != null) {
      // TODO: Decodificar el JWT y verificar expiracion.
      // Si esta expirado, intentar renovar con el refresh token.
      emit(const AuthAuthenticated(
        usuarioId: '',
        nombre: '',
        roles: [],
        permisos: [],
      ));
    } else {
      emit(AuthUnauthenticated());
    }
  }

  /// Maneja el intento de login.
  Future<void> _onLoginRequested(
    AuthLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final result = await _repository.login(
        correo: event.correo,
        password: event.password,
      );

      await SecureStorage.saveSession(
        accessToken: result.accessToken,
        refreshToken: result.refreshToken,
      );

      emit(AuthAuthenticated(
        usuarioId: result.usuario.id,
        nombre: '${result.usuario.nombre} ${result.usuario.apellido}',
        roles: result.usuario.roles,
        permisos: result.usuario.permisos,
      ));
    } on AuthException catch (e) {
      emit(AuthError(message: e.message, code: e.code));
    } catch (e) {
      emit(const AuthError(
        message:
            'Error de conexion. Verifica tu internet e intentalo de nuevo.',
        code: 'CONEXION',
      ));
    }
  }

  /// Solicita el envio del enlace de recuperacion.
  Future<void> _onRecuperarSolicitado(
    AuthRecuperarSolicitado event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      await _repository.solicitarRecuperacion(correo: event.correo);
      emit(AuthRecuperarEnviado());
    } catch (_) {
      // Siempre mostrar el mismo mensaje (AC-02 US-AUT-04)
      emit(AuthRecuperarEnviado());
    }
  }

  /// Confirma el cambio de contrasena con el token de recuperacion.
  Future<void> _onNuevoPasswordConfirmado(
    AuthNuevoPasswordConfirmado event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      await _repository.confirmarRecuperacion(
        token: event.token,
        password: event.password,
      );
      emit(AuthPasswordCambiado());
    } on AuthException catch (e) {
      emit(AuthError(message: e.message, code: e.code));
    }
  }

  /// Cierra la sesion del usuario.
  Future<void> _onLogoutRequested(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    final refreshToken = await SecureStorage.getRefreshToken();
    await SecureStorage.clearSession();
    if (refreshToken != null) {
      await _repository.logout(refreshToken: refreshToken);
    }
    emit(AuthUnauthenticated());
  }
}
