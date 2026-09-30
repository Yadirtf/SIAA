import 'package:intl/intl.dart';

/// Formatos de presentación compartidos por las pantallas de consulta.
class Formatos {
  Formatos._();

  static final DateFormat _fechaHora = DateFormat('yyyy-MM-dd HH:mm');
  static final DateFormat _fechaHoraSeg = DateFormat('yyyy-MM-dd HH:mm:ss');

  /// `AAAA-MM-DD HH:mm` en hora local, o '—' si no hay fecha.
  static String fechaHora(DateTime? d) =>
      d == null ? '—' : _fechaHora.format(d.toLocal());

  /// `AAAA-MM-DD HH:mm:ss` en hora local, o '—' si no hay fecha.
  static String fechaHoraSegundos(DateTime? d) =>
      d == null ? '—' : _fechaHoraSeg.format(d.toLocal());

  /// Número con hasta un decimal (horas).
  static String decimal(num v) =>
      v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(1);

  /// Porcentaje con un decimal.
  static String porcentaje(num v) => '${v.toStringAsFixed(1)} %';
}
