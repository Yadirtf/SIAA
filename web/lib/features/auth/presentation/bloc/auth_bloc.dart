// BLoC de autenticación para la consola web SIAA — T-AUT-01.8
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/auth_repository.dart';

// ─── Eventos ───────────────────────────────────────────────────

abstract class WebAuthEvent extends Equatable {
  const WebAuthEvent();
  @override
  List<Object?> get props => [];
}

class WebAuthCheckSessionRequested extends WebAuthEvent {
  const WebAuthCheckSessionRequested();
}

class WebAuthLoginRequested extends WebAuthEvent {
  final String correo;
  final String password;

  const WebAuthLoginRequested({
    required this.correo,
    required this.password,
  });

  @override
  List<Object?> get props => [correo, password];
}

class WebAuthLogoutRequested extends WebAuthEvent {
  const WebAuthLogoutRequested();
}

// ─── Estados ───────────────────────────────────────────────────

abstract class WebAuthState extends Equatable {
  const WebAuthState();
  @override
  List<Object?> get props => [];
}

class WebAuthInitial extends WebAuthState {
  const WebAuthInitial();
}

class WebAuthLoading extends WebAuthState {
  const WebAuthLoading();
}

class WebAuthAuthenticated extends WebAuthState {
  final WebUserInfo usuario;

  const WebAuthAuthenticated(this.usuario);

  @override
  List<Object?> get props => [usuario.id, usuario.correo];
}

class WebAuthUnauthenticated extends WebAuthState {
  final String? mensajeError;

  const WebAuthUnauthenticated({this.mensajeError});

  @override
  List<Object?> get props => [mensajeError];
}

// ─── BLoC ──────────────────────────────────────────────────────

class WebAuthBloc extends Bloc<WebAuthEvent, WebAuthState> {
  final WebAuthRepository repository;

  WebAuthBloc({required this.repository}) : super(const WebAuthInitial()) {
    on<WebAuthCheckSessionRequested>(_onCheckSession);
    on<WebAuthLoginRequested>(_onLogin);
    on<WebAuthLogoutRequested>(_onLogout);
  }

  Future<void> _onCheckSession(
    WebAuthCheckSessionRequested event,
    Emitter<WebAuthState> emit,
  ) async {
    final user = await repository.checkSession();
    if (user != null) {
      emit(WebAuthAuthenticated(user));
    } else {
      emit(const WebAuthUnauthenticated());
    }
  }

  Future<void> _onLogin(
    WebAuthLoginRequested event,
    Emitter<WebAuthState> emit,
  ) async {
    emit(const WebAuthLoading());
    try {
      final user = await repository.login(
        correo: event.correo,
        password: event.password,
      );
      emit(WebAuthAuthenticated(user));
    } catch (e) {
      final msg = e.toString().replaceFirst('Exception: ', '');
      emit(WebAuthUnauthenticated(mensajeError: msg));
    }
  }

  Future<void> _onLogout(
    WebAuthLogoutRequested event,
    Emitter<WebAuthState> emit,
  ) async {
    emit(const WebAuthLoading());
    await repository.logout();
    emit(const WebAuthUnauthenticated());
  }
}
