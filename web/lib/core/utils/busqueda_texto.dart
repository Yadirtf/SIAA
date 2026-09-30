/// Utilidades de búsqueda de texto para los selectores con filtro local.
library;

const _conTilde = 'áàäâãéèëêíìïîóòöôõúùüûñç';
const _sinTilde = 'aaaaaeeeeiiiiooooouuuunc';

/// Minúsculas y sin tildes, para comparar sin importar acentos ni mayúsculas.
String normalizarBusqueda(String texto) {
  final minus = texto.toLowerCase().trim();
  final buffer = StringBuffer();
  for (final rune in minus.runes) {
    final c = String.fromCharCode(rune);
    final i = _conTilde.indexOf(c);
    buffer.write(i >= 0 ? _sinTilde[i] : c);
  }
  return buffer.toString();
}

/// Filtra [items] cuyo texto (según [textoDe]) contiene todas las palabras
/// de [consulta]. Una consulta vacía devuelve los primeros [limite].
List<T> filtrarPorTexto<T>(
  Iterable<T> items,
  String Function(T) textoDe,
  String consulta, {
  int limite = 50,
}) {
  final palabras = normalizarBusqueda(consulta)
      .split(RegExp(r'\s+'))
      .where((p) => p.isNotEmpty)
      .toList();
  final resultado = <T>[];
  for (final item in items) {
    final texto = normalizarBusqueda(textoDe(item));
    if (palabras.every(texto.contains)) {
      resultado.add(item);
      if (resultado.length >= limite) break;
    }
  }
  return resultado;
}
