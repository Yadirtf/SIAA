import 'package:equatable/equatable.dart';

import 'usuario_model.dart';

/// Página de resultados de GET /usuarios.
///
/// [total] proviene de la cabecera `X-Total-Count`; es null cuando el
/// navegador no la expone (CORS), y entonces se infiere si hay más páginas.
class UsuariosPaginaModel extends Equatable {
  final List<UsuarioModel> usuarios;
  final int? total;
  final int pagina;
  final int limite;

  const UsuariosPaginaModel({
    required this.usuarios,
    required this.total,
    required this.pagina,
    required this.limite,
  });

  bool get hayMas =>
      total != null ? pagina * limite < total! : usuarios.length >= limite;

  int? get totalPaginas =>
      total == null ? null : (total! / limite).ceil().clamp(1, 1 << 30);

  @override
  List<Object?> get props => [usuarios, total, pagina, limite];
}
