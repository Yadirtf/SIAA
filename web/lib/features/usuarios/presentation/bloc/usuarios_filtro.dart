import 'package:equatable/equatable.dart';

/// Criterios de búsqueda y paginación del listado de usuarios.
class UsuariosFiltro extends Equatable {
  static const int limitePorDefecto = 50;

  final String texto;
  final String? rol;
  final bool? activo;
  final int pagina;
  final int limite;

  const UsuariosFiltro({
    this.texto = '',
    this.rol,
    this.activo,
    this.pagina = 1,
    this.limite = limitePorDefecto,
  });

  /// Copia el filtro; los campos anulables se reemplazan con funciones para
  /// poder limpiarlos explícitamente (p. ej. `rol: () => null`).
  UsuariosFiltro copyWith({
    String? texto,
    String? Function()? rol,
    bool? Function()? activo,
    int? pagina,
    int? limite,
  }) {
    return UsuariosFiltro(
      texto: texto ?? this.texto,
      rol: rol != null ? rol() : this.rol,
      activo: activo != null ? activo() : this.activo,
      pagina: pagina ?? this.pagina,
      limite: limite ?? this.limite,
    );
  }

  @override
  List<Object?> get props => [texto, rol, activo, pagina, limite];
}
