/// Separa un texto pegado (una línea por persona, o separado por comas o
/// punto y coma) en identificadores limpios y sin repetir.
List<String> separarIdentificadores(String texto) {
  final vistos = <String>{};
  final salida = <String>[];
  for (final parte in texto.split(RegExp(r'[\n\r,;\t]+'))) {
    final v = parte.trim();
    if (v.isEmpty) continue;
    if (vistos.add(v.toLowerCase())) salida.add(v);
  }
  return salida;
}
