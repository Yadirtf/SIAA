import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/widgets/selector_busqueda.dart';
import '../../data/buscador_usuarios.dart';
import '../../data/models/usuario_model.dart';

/// Selector de usuario por nombre, correo o documento (nunca por id).
/// Con [rol] limita la búsqueda (p. ej. `DOCENTE`). El [buscador] por
/// defecto es el registrado en el árbol de providers.
class SelectorUsuario extends StatelessWidget {
  final String etiqueta;
  final String? rol;
  final bool soloActivos;
  final String? idInicial;
  final ValueChanged<UsuarioModel?> onCambio;
  final bool requerido;
  final String? Function(UsuarioModel? valor)? validador;
  final IconData icono;
  final bool denso;
  final BuscadorUsuarios? buscador;

  const SelectorUsuario({
    super.key,
    required this.etiqueta,
    required this.onCambio,
    this.rol,
    this.soloActivos = true,
    this.idInicial,
    this.requerido = false,
    this.validador,
    this.icono = Icons.person_search_rounded,
    this.denso = false,
    this.buscador,
  });

  /// Texto secundario: correo y documento, si lo tiene.
  static String detalle(UsuarioModel u) => [
    u.correo,
    if (u.documento != null) 'Doc. ${u.documento}',
  ].where((t) => t.isNotEmpty).join(' · ');

  static String nombre(UsuarioModel u) =>
      u.nombreCompleto.isEmpty ? u.correo : u.nombreCompleto;

  @override
  Widget build(BuildContext context) {
    BuscadorUsuarios fuente() => buscador ?? context.read<BuscadorUsuarios>();
    return SelectorBusqueda<UsuarioModel>(
      etiqueta: etiqueta,
      ayuda: 'Nombre, correo o documento',
      icono: icono,
      denso: denso,
      requerido: requerido,
      validador: validador,
      idInicial: idInicial,
      onCambio: onCambio,
      buscar: (q) => fuente().buscar(q, rol: rol, soloActivos: soloActivos),
      resolver: (id) => fuente().porId(id),
      textoDe: nombre,
      detalleDe: detalle,
      idDe: (u) => u.id,
    );
  }
}
