import 'package:equatable/equatable.dart';

import '../../data/models/usuario_model.dart';
import '../../data/models/usuarios_pagina_model.dart';
import 'usuarios_filtro.dart';

enum UsuariosStatus { inicial, cargando, cargado, error }

class UsuariosState extends Equatable {
  final UsuariosStatus status;
  final UsuariosFiltro filtro;
  final UsuariosPaginaModel? pagina;
  final String? errorCarga;
  final bool procesando;
  final String? mensajeExito;
  final String? mensajeError;

  const UsuariosState({
    this.status = UsuariosStatus.inicial,
    this.filtro = const UsuariosFiltro(),
    this.pagina,
    this.errorCarga,
    this.procesando = false,
    this.mensajeExito,
    this.mensajeError,
  });

  List<UsuarioModel> get usuarios => pagina?.usuarios ?? const [];

  UsuariosState copyWith({
    UsuariosStatus? status,
    UsuariosFiltro? filtro,
    UsuariosPaginaModel? pagina,
    String? errorCarga,
    bool? procesando,
    String? mensajeExito,
    String? mensajeError,
    bool limpiarMensajes = false,
  }) {
    return UsuariosState(
      status: status ?? this.status,
      filtro: filtro ?? this.filtro,
      pagina: pagina ?? this.pagina,
      errorCarga: errorCarga,
      procesando: procesando ?? this.procesando,
      mensajeExito: limpiarMensajes
          ? null
          : (mensajeExito ?? this.mensajeExito),
      mensajeError: limpiarMensajes
          ? null
          : (mensajeError ?? this.mensajeError),
    );
  }

  @override
  List<Object?> get props => [
    status,
    filtro,
    pagina,
    errorCarga,
    procesando,
    mensajeExito,
    mensajeError,
  ];
}
