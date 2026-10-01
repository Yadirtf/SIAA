import 'package:intl/intl.dart';

import 'hora_12h.dart';

/// Formatos de presentación compartidos por las pantallas de consulta.
class Formatos {
  Formatos._();

  static final DateFormat _fecha = DateFormat('yyyy-MM-dd');

  /// `AAAA-MM-DD 6:30 p. m.` en hora local, o '—' si no hay fecha.
  static String fechaHora(DateTime? d) {
    if (d == null) return '—';
    final l = d.toLocal();
    return '${_fecha.format(l)} ${hora12h(l.hour, l.minute)}';
  }

  /// `AAAA-MM-DD 6:30:05 p. m.` en hora local, o '—' si no hay fecha.
  static String fechaHoraSegundos(DateTime? d) {
    if (d == null) return '—';
    final l = d.toLocal();
    final h = l.hour % 12 == 0 ? 12 : l.hour % 12;
    final sufijo = l.hour < 12 ? 'a. m.' : 'p. m.';
    String dos(int n) => n.toString().padLeft(2, '0');
    return '${_fecha.format(l)} $h:${dos(l.minute)}:${dos(l.second)} $sufijo';
  }

  /// Número con hasta un decimal (horas).
  static String decimal(num v) =>
      v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(1);

  /// Porcentaje con un decimal.
  static String porcentaje(num v) => '${v.toStringAsFixed(1)} %';
}
