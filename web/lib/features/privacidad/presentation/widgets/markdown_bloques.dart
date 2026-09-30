/// Parser mínimo de Markdown (sin paquetes externos) para el aviso de
/// privacidad: encabezados, párrafos y listas con viñetas o numeradas.
enum TipoBloqueMd { encabezado, parrafo, vineta, numerada }

class BloqueMd {
  final TipoBloqueMd tipo;
  final String texto;

  /// Nivel del encabezado (1..6) o número del ítem de lista numerada.
  final int nivel;

  const BloqueMd(this.tipo, this.texto, {this.nivel = 0});

  @override
  bool operator ==(Object other) =>
      other is BloqueMd &&
      other.tipo == tipo &&
      other.texto == texto &&
      other.nivel == nivel;

  @override
  int get hashCode => Object.hash(tipo, texto, nivel);

  @override
  String toString() => 'BloqueMd($tipo, $nivel, "$texto")';
}

final _reEncabezado = RegExp(r'^(#{1,6})\s+(.*)$');
final _reVineta = RegExp(r'^[-*+]\s+(.*)$');
final _reNumerada = RegExp(r'^(\d+)[.)]\s+(.*)$');

/// Divide [markdown] en bloques. Las líneas consecutivas de texto se unen en
/// un mismo párrafo; una línea en blanco lo cierra.
List<BloqueMd> parsearMarkdown(String markdown) {
  final bloques = <BloqueMd>[];
  final parrafo = <String>[];

  void cerrarParrafo() {
    if (parrafo.isEmpty) return;
    bloques.add(BloqueMd(TipoBloqueMd.parrafo, parrafo.join(' ')));
    parrafo.clear();
  }

  for (final cruda in markdown.replaceAll('\r\n', '\n').split('\n')) {
    final linea = cruda.trim();
    if (linea.isEmpty) {
      cerrarParrafo();
      continue;
    }
    final h = _reEncabezado.firstMatch(linea);
    final v = _reVineta.firstMatch(linea);
    final n = _reNumerada.firstMatch(linea);
    if (h != null) {
      cerrarParrafo();
      bloques.add(
        BloqueMd(
          TipoBloqueMd.encabezado,
          h.group(2)!.replaceAll(RegExp(r'\s#+$'), '').trim(),
          nivel: h.group(1)!.length,
        ),
      );
    } else if (v != null) {
      cerrarParrafo();
      bloques.add(BloqueMd(TipoBloqueMd.vineta, v.group(1)!));
    } else if (n != null) {
      cerrarParrafo();
      bloques.add(
        BloqueMd(
          TipoBloqueMd.numerada,
          n.group(2)!,
          nivel: int.parse(n.group(1)!),
        ),
      );
    } else if (parrafo.isEmpty && _esContinuacionDeLista(bloques, cruda)) {
      // Línea sangrada que continúa el ítem de lista anterior.
      final ultimo = bloques.removeLast();
      bloques.add(
        BloqueMd(ultimo.tipo, '${ultimo.texto} $linea', nivel: ultimo.nivel),
      );
    } else {
      parrafo.add(linea);
    }
  }
  cerrarParrafo();
  return bloques;
}

bool _esContinuacionDeLista(List<BloqueMd> bloques, String cruda) =>
    bloques.isNotEmpty &&
    (bloques.last.tipo == TipoBloqueMd.vineta ||
        bloques.last.tipo == TipoBloqueMd.numerada) &&
    cruda.startsWith(RegExp(r'\s{2,}'));

/// Tramo de texto en línea: `**negrita**` o `*cursiva*` / `_cursiva_`.
class TramoMd {
  final String texto;
  final bool negrita;
  final bool cursiva;

  const TramoMd(this.texto, {this.negrita = false, this.cursiva = false});
}

// Los guiones bajos sólo marcan énfasis fuera de palabras (no en snake_case).
final _reEnLinea = RegExp(
  r'\*\*(.+?)\*\*|(?<!\w)__(.+?)__(?!\w)|\*(.+?)\*|(?<!\w)_(.+?)_(?!\w)',
);

/// Separa el texto en tramos con énfasis; quita las comillas invertidas.
List<TramoMd> parsearEnLinea(String texto) {
  final limpio = texto.replaceAll('`', '');
  final tramos = <TramoMd>[];
  var desde = 0;
  for (final m in _reEnLinea.allMatches(limpio)) {
    if (m.start > desde) tramos.add(TramoMd(limpio.substring(desde, m.start)));
    final negrita = m.group(1) ?? m.group(2);
    if (negrita != null) {
      tramos.add(TramoMd(negrita, negrita: true));
    } else {
      tramos.add(TramoMd(m.group(3) ?? m.group(4)!, cursiva: true));
    }
    desde = m.end;
  }
  if (desde < limpio.length) tramos.add(TramoMd(limpio.substring(desde)));
  return tramos;
}
