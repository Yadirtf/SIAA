import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/network/api_exception.dart';
import '../../domain/auth_repository.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _authRepository;

  AuthBloc({required AuthRepository authRepository})
    : _authRepository = authRepository,
      super(const AuthInitial()) {
    on<CheckAuthStatusEvent>(_onCheckAuthStatus);
    on<LoginSubmittedEvent>(_onLoginSubmitted);
    on<LogoutRequestedEvent>(_onLogoutRequested);
    on<SegundoFactorEnviadoEvent>(_onSegundoFactorEnviado);
    on<SegundoFactorCanceladoEvent>((_, emit) => emit(const Unauthenticated()));
  }

  Future<void> _onCheckAuthStatus(
    CheckAuthStatusEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      final user = await _authRepository.checkAuthStatus();
      if (user != null) {
        emit(Authenticated(user));
      } else {
        emit(const Unauthenticated());
      }
    } catch (_) {
      emit(const Unauthenticated());
    }
  }

  Future<void> _onLoginSubmitted(
    LoginSubmittedEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      final resultado = await _authRepository.login(
        correo: event.correo,
        password: event.password,
      );
      final desafio = resultado.desafio;
      if (desafio == null) {
        emit(Authenticated(resultado.usuario!));
        return;
      }
      // US-AUT-05 AC-01: sin TOTP configurado, se enrola antes de entrar.
      final enrolamiento = desafio.configurar
          ? await _authRepository.enrolarTotp(desafio)
          : null;
      emit(
        SegundoFactorRequerido(
          correo: event.correo,
          desafio: desafio,
          enrolamiento: enrolamiento,
        ),
      );
    } catch (e) {
      emit(AuthFailure(_mensaje(e)));
    }
  }

  Future<void> _onSegundoFactorEnviado(
    SegundoFactorEnviadoEvent event,
    Emitter<AuthState> emit,
  ) async {
    final actual = state;
    if (actual is! SegundoFactorRequerido) return;
    emit(actual.copyWith(enviando: true));
    try {
      final user = await _authRepository.completarTotp(
        desafio: actual.desafio,
        codigo: event.codigo.trim(),
      );
      emit(Authenticated(user));
    } catch (e) {
      emit(actual.copyWith(enviando: false, error: _mensaje(e)));
    }
  }

  String _mensaje(Object e) => e is ApiException
      ? e.message
      : e.toString().replaceAll('Exception: ', '');

  Future<void> _onLogoutRequested(
    LogoutRequestedEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      await _authRepository.logout();
    } finally {
      emit(const Unauthenticated());
    }
  }
}
