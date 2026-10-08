// BLoC de autenticacion - US-AUT-01, US-AUT-04, RF-ROL-004
// Gestiona el estado de login, recuperacion de contrasena, sesion y contexto de rol.
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/auth/jwt_claims.dart';
import '../../../../core/device/device_info_service.dart';
import '../../../../core/storage/secure_storage.dart';
import '../../data/auth_repository.dart';
import '../../data/sesion_restaurador.dart';
import 'auth_event.dart';
import 'auth_state.dart';

export 'auth_event.dart';
export 'auth_state.dart';

// ─── BLOC ─────────────────────────────────────────────────────────────────────

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _repository;
  final DeviceInfoService _deviceInfoService;

  /// Limpieza que requiere la sesión aún vigente (p. ej. DELETE del token push,
  /// US-NOT-01); se ejecuta antes de borrar los tokens.
  final Future<void> Function()? _antesDeCerrarSesion;
  final SesionRestaurador _restaurador;

  AuthBloc({
    required AuthRepository repository,
    DeviceInfoService? deviceInfoService,
    Future<void> Function()? antesDeCerrarSesion,
    SesionRestaurador? restaurador,
  })  : _repository = repository,
        _deviceInfoService = deviceInfoService ?? const DeviceInfoService(),
        _antesDeCerrarSesion = antesDeCerrarSesion,
        _restaurador = restaurador ?? SesionRestaurador(),
        super(AuthInitial()) {
    on<AuthSessionChecked>(_onSessionChecked);
    on<AuthLoginRequested>(_onLoginRequested);
    on<AuthRecuperarSolicitado>(_onRecuperarSolicitado);
    on<AuthNuevoPasswordConfirmado>(_onNuevoPasswordConfirmado);
    on<AuthLogoutRequested>(_onLogoutRequested);
    on<AuthContextoSolicitado>(_onContextoSolicitado);
    on<AuthSegundoFactorEnviado>(_onSegundoFactorEnviado);
    on<AuthSegundoFactorCancelado>((_, emit) => emit(AuthUnauthenticated()));
  }

  /// Restaura la sesión guardada al abrir la app con nombre, roles y permisos reales.
  Future<void> _onSessionChecked(
    AuthSessionChecked event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthCheckingSession());
    final sesion = await _restaurador.restaurar();
    if (sesion == null) {
      emit(AuthUnauthenticated());
      return;
    }
    emit(AuthAuthenticated(
      usuarioId: sesion.usuarioId,
      nombre: sesion.nombre,
      correo: sesion.correo,
      roles: sesion.roles,
      permisos: sesion.permisos,
      rolActivo: sesion.rolActivo,
    ));
  }

  /// Cambia el rol activo en el backend y adopta los permisos del nuevo token.
  Future<void> _onContextoSolicitado(
    AuthContextoSolicitado event,
    Emitter<AuthState> emit,
  ) async {
    final actual = state;
    if (actual is! AuthAuthenticated) return;
    try {
      final par = await _repository.cambiarContexto(rol: event.rol);
      await SecureStorage.saveSession(
        accessToken: par.accessToken,
        refreshToken: par.refreshToken,
      );
      emit(AuthAuthenticated(
        usuarioId:
            par.usuario.id.isNotEmpty ? par.usuario.id : actual.usuarioId,
        nombre: actual.nombre,
        correo: actual.correo,
        roles: actual.roles,
        permisos: par.usuario.permisos,
        rolActivo: event.rol,
      ));
    } on AuthException catch (e) {
      emit(actual.conAviso(e.message));
    } catch (_) {
      emit(actual.conAviso('No se pudo cambiar de rol. Verifica tu conexión.'));
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
      final desafio = result.desafio;
      if (desafio != null) {
        // US-AUT-05 AC-01: sin TOTP configurado se enrola antes de entrar.
        final enrol =
            desafio.configurar ? await _repository.enrolarTotp(desafio) : null;
        emit(AuthSegundoFactorRequerido(desafio: desafio, enrolamiento: enrol));
        return;
      }
      await _finalizarLogin(result, emit);
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

  /// Presenta el código del desafío y, si es válido, completa el login.
  Future<void> _onSegundoFactorEnviado(
    AuthSegundoFactorEnviado event,
    Emitter<AuthState> emit,
  ) async {
    final actual = state;
    if (actual is! AuthSegundoFactorRequerido) return;
    emit(actual.copyWith(enviando: true));
    try {
      final par = await _repository.completarTotp(
        desafio: actual.desafio,
        codigo: event.codigo.trim(),
      );
      await _finalizarLogin(par, emit);
    } on AuthException catch (e) {
      emit(actual.copyWith(enviando: false, error: e.message));
    } catch (_) {
      emit(actual.copyWith(
          enviando: false, error: 'Error de conexion. Intentalo de nuevo.'));
    }
  }

  /// Guarda la sesión, registra el dispositivo (US-AUT-03) y emite el estado final.
  Future<void> _finalizarLogin(
      TokenPair result, Emitter<AuthState> emit) async {
    await SecureStorage.saveSession(
      accessToken: result.accessToken,
      refreshToken: result.refreshToken,
    );

    // US-AUT-03: Registrar y verificar dispositivo móvil confiable
    try {
      final meta = await _deviceInfoService.getMetadata();
      final disp = await _repository.registrarDispositivo(
        instalacionId: meta.instalacionId,
        modelo: meta.modelo,
        so: meta.so,
        versionApp: meta.versionApp,
      );
      if (disp.requiereAprobacion || disp.estado == 'pendiente') {
        await SecureStorage.clearSession();
        emit(AuthDispositivoPendiente(
          mensaje: disp.mensaje.isNotEmpty
              ? disp.mensaje
              : 'Dispositivo no reconocido. Se ha enviado una solicitud de aprobación al administrador.',
          dispositivoId: disp.id,
        ));
        return;
      }
    } catch (_) {
      // En caso de fallo de red en registro de dispositivo, se continúa
      // con la sesión autenticada.
    }

    emit(AuthAuthenticated(
      usuarioId: result.usuario.id,
      nombre: '${result.usuario.nombre} ${result.usuario.apellido}'.trim(),
      correo: result.usuario.correo,
      roles: result.usuario.roles,
      permisos: result.usuario.permisos,
      rolActivo: JwtClaims.decodificar(result.accessToken)?.rolActivo ?? '',
    ));
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
    try {
      await _antesDeCerrarSesion?.call();
    } catch (_) {
      // Best-effort: el cierre de sesión local nunca se bloquea.
    }
    final refreshToken = await SecureStorage.getRefreshToken();
    await SecureStorage.clearSession();
    if (refreshToken != null) {
      await _repository.logout(refreshToken: refreshToken);
    }
    emit(AuthUnauthenticated());
  }
}
