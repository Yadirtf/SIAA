import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/network/api_exception.dart';
import '../../data/models/usuarios_pagina_model.dart';
import '../../domain/usuarios_repository.dart';
import 'usuarios_event.dart';
import 'usuarios_filtro.dart';
import 'usuarios_state.dart';

/// Estado del listado de usuarios y de las acciones administrativas.
class UsuariosBloc extends Bloc<UsuariosEvent, UsuariosState> {
  final UsuariosRepository _repository;

  UsuariosBloc({required UsuariosRepository repository})
    : _repository = repository,
      super(const UsuariosState()) {
    on<CargarUsuariosEvent>((e, emit) => _cargar(e.filtro, emit));
    on<RecargarUsuariosEvent>((e, emit) => _cargar(state.filtro, emit));
    on<CrearUsuarioEvent>(_onCrear);
    on<ActualizarUsuarioEvent>(
      (e, emit) => _accion(emit, () async {
        await _repository.actualizar(e.usuarioId, e.request);
        return 'Datos del usuario actualizados.';
      }),
    );
    on<ActivarUsuarioEvent>(
      (e, emit) => _accion(emit, () async {
        await _repository.activar(e.usuarioId);
        return 'Usuario activado.';
      }),
    );
    on<DesactivarUsuarioEvent>(
      (e, emit) => _accion(emit, () async {
        await _repository.desactivar(e.usuarioId, e.motivo);
        return 'Usuario desactivado.';
      }),
    );
    on<AsignarRolesUsuarioEvent>(
      (e, emit) => _accion(emit, () async {
        await _repository.asignarRoles(e.usuarioId, e.roles);
        return 'Roles actualizados.';
      }),
    );
    on<AsignarAmbitosUsuarioEvent>(
      (e, emit) => _accion(emit, () async {
        await _repository.asignarAmbitos(e.usuarioId, e.ambitos);
        return 'Ámbitos actualizados.';
      }),
    );
    on<DesbloquearUsuarioEvent>(
      (e, emit) => _accion(emit, () async {
        await _repository.desbloquear(e.usuarioId);
        return 'Usuario desbloqueado.';
      }),
    );
    on<RevocarSesionesUsuarioEvent>(
      (e, emit) => _accion(emit, () async {
        await _repository.revocarSesiones(e.usuarioId, e.motivo);
        return 'Sesiones del usuario cerradas.';
      }),
    );
    on<LimpiarMensajesUsuariosEvent>(
      (e, emit) => emit(state.copyWith(limpiarMensajes: true)),
    );
  }

  static String mensajeDe(Object e) {
    if (e is ApiException) return e.message;
    return e.toString().replaceAll('Exception: ', '');
  }

  Future<void> _cargar(
    UsuariosFiltro filtro,
    Emitter<UsuariosState> emit,
  ) async {
    emit(
      state.copyWith(
        status: UsuariosStatus.cargando,
        filtro: filtro,
        limpiarMensajes: true,
      ),
    );
    try {
      final pagina = await _consultar(filtro);
      emit(state.copyWith(status: UsuariosStatus.cargado, pagina: pagina));
    } catch (e) {
      emit(
        state.copyWith(status: UsuariosStatus.error, errorCarga: mensajeDe(e)),
      );
    }
  }

  Future<void> _onCrear(CrearUsuarioEvent e, Emitter<UsuariosState> emit) {
    return _accion(emit, () async {
      final r = await _repository.crear(e.request);
      return r.invitacionEnviada
          ? 'Usuario creado. Se envió un correo de invitación a ${r.correo} '
                'para que defina su contraseña.'
          : 'Usuario ${r.correo} creado.';
    });
  }

  /// Ejecuta una acción, recarga la página actual y publica el resultado.
  Future<void> _accion(
    Emitter<UsuariosState> emit,
    Future<String> Function() accion,
  ) async {
    emit(state.copyWith(procesando: true, limpiarMensajes: true));
    final String mensaje;
    try {
      mensaje = await accion();
    } catch (e) {
      emit(state.copyWith(procesando: false, mensajeError: mensajeDe(e)));
      return;
    }
    try {
      final pagina = await _consultar(state.filtro);
      emit(
        state.copyWith(
          status: UsuariosStatus.cargado,
          pagina: pagina,
          procesando: false,
          mensajeExito: mensaje,
        ),
      );
    } catch (e) {
      emit(state.copyWith(procesando: false, mensajeExito: mensaje));
    }
  }

  Future<UsuariosPaginaModel> _consultar(UsuariosFiltro f) =>
      _repository.listar(
        texto: f.texto,
        rol: f.rol,
        activo: f.activo,
        pagina: f.pagina,
        limite: f.limite,
      );
}
