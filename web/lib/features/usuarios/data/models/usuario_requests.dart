import 'ambito_model.dart';

/// Cuerpo de POST /usuarios. Sin contraseña, el backend envía una invitación.
class CrearUsuarioRequest {
  final String correo;
  final String nombre;
  final String apellido;
  final String? documento;
  final String? password;
  final List<String> roles;
  final List<AmbitoModel> ambitos;

  const CrearUsuarioRequest({
    required this.correo,
    required this.nombre,
    required this.apellido,
    this.documento,
    this.password,
    this.roles = const [],
    this.ambitos = const [],
  });

  Map<String, dynamic> toJson() => {
    'correo': correo,
    'nombre': nombre,
    'apellido': apellido,
    if (documento != null && documento!.isNotEmpty) 'documento': documento,
    if (password != null && password!.isNotEmpty) 'password': password,
    'roles': roles.map((r) => {'nombre': r}).toList(),
    'ambitos': ambitos.map((a) => a.toJson()).toList(),
  };
}

/// Cuerpo de PUT /usuarios/:id (datos básicos).
class ActualizarUsuarioRequest {
  final String correo;
  final String nombre;
  final String apellido;
  final String documento;

  const ActualizarUsuarioRequest({
    required this.correo,
    required this.nombre,
    required this.apellido,
    required this.documento,
  });

  Map<String, dynamic> toJson() => {
    'correo': correo,
    'nombre': nombre,
    'apellido': apellido,
    'documento': documento,
  };
}

/// Resultado de POST /usuarios.
class UsuarioCreadoResult {
  final String usuarioId;
  final String correo;
  final bool invitacionEnviada;

  const UsuarioCreadoResult({
    required this.usuarioId,
    required this.correo,
    required this.invitacionEnviada,
  });
}
