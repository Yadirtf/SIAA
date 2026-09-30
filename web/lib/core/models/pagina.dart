import 'package:equatable/equatable.dart';

/// Página de un listado paginado del backend.
///
/// [total] proviene de la cabecera `X-Total-Count`; es null cuando el
/// navegador no la expone, y entonces se infiere si hay más páginas.
class Pagina<T> extends Equatable {
  final List<T> items;
  final int? total;
  final int pagina;
  final int limite;

  const Pagina({
    required this.items,
    required this.total,
    required this.pagina,
    required this.limite,
  });

  bool get hayMas =>
      total != null ? pagina * limite < total! : items.length >= limite;

  int? get totalPaginas =>
      total == null ? null : (total! / limite).ceil().clamp(1, 1 << 30);

  @override
  List<Object?> get props => [items, total, pagina, limite];
}
