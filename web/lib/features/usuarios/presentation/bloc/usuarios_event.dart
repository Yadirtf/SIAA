import 'package:equatable/equatable.dart';

import '../../data/models/ambito_model.dart';
import '../../data/models/rol_asignado_model.dart';
import '../../data/models/usuario_requests.dart';
import 'usuarios_filtro.dart';

abstract class UsuariosEvent extends Equatable {
  const UsuariosEvent();

  @override
  List<Object?> get props => [];
}

/// Consulta GET /usuarios con el filtro indicado.
class CargarUsuariosEvent extends UsuariosEvent {
  final UsuariosFiltro filtro;

  const CargarUsuariosEvent([this.filtro = const UsuariosFiltro()]);

  @override
  List<Object?> get props => [filtro];
}

/// Repite la consulta con el filtro vigente.
class RecargarUsuariosEvent extends UsuariosEvent {
  const RecargarUsuariosEvent();
}

class CrearUsuarioEvent extends UsuariosEvent {
  final CrearUsuarioRequest request;

  const CrearUsuarioEvent(this.request);

  @override
  List<Object?> get props => [request.correo];
}

class ActualizarUsuarioEvent extends UsuariosEvent {
  final String usuarioId;
  final ActualizarUsuarioRequest request;

  const ActualizarUsuarioEvent(this.usuarioId, this.request);

  @override
  List<Object?> get props => [usuarioId, request.correo];
}

class ActivarUsuarioEvent extends UsuariosEvent {
  final String usuarioId;

  const ActivarUsuarioEvent(this.usuarioId);

  @override
  List<Object?> get props => [usuarioId];
}

class DesactivarUsuarioEvent extends UsuariosEvent {
  final String usuarioId;
  final String motivo;

  const DesactivarUsuarioEvent(this.usuarioId, this.motivo);

  @override
  List<Object?> get props => [usuarioId, motivo];
}

class AsignarRolesUsuarioEvent extends UsuariosEvent {
  final String usuarioId;
  final List<RolAsignadoModel> roles;

  const AsignarRolesUsuarioEvent(this.usuarioId, this.roles);

  @override
  List<Object?> get props => [usuarioId, roles];
}

class AsignarAmbitosUsuarioEvent extends UsuariosEvent {
  final String usuarioId;
  final List<AmbitoModel> ambitos;

  const AsignarAmbitosUsuarioEvent(this.usuarioId, this.ambitos);

  @override
  List<Object?> get props => [usuarioId, ambitos];
}

class DesbloquearUsuarioEvent extends UsuariosEvent {
  final String usuarioId;

  const DesbloquearUsuarioEvent(this.usuarioId);

  @override
  List<Object?> get props => [usuarioId];
}

class RevocarSesionesUsuarioEvent extends UsuariosEvent {
  final String usuarioId;
  final String motivo;

  const RevocarSesionesUsuarioEvent(this.usuarioId, this.motivo);

  @override
  List<Object?> get props => [usuarioId, motivo];
}

class LimpiarMensajesUsuariosEvent extends UsuariosEvent {
  const LimpiarMensajesUsuariosEvent();
}
