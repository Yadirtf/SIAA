// fechas_es.dart — Formato de fechas en español sin depender de datos de localización
// (evita LocaleDataException cuando intl no tiene inicializado el locale).

const _mesesCortos = [
  'ene',
  'feb',
  'mar',
  'abr',
  'may',
  'jun',
  'jul',
  'ago',
  'sep',
  'oct',
  'nov',
  'dic'
];
const _mesesLargos = [
  'enero',
  'febrero',
  'marzo',
  'abril',
  'mayo',
  'junio',
  'julio',
  'agosto',
  'septiembre',
  'octubre',
  'noviembre',
  'diciembre',
];

String _dos(int n) => n.toString().padLeft(2, '0');

/// "5 sep".
String diaMesCorto(DateTime f) => '${f.day} ${_mesesCortos[f.month - 1]}';

/// "Septiembre 2026".
String mesAnio(DateTime f) {
  final mes = _mesesLargos[f.month - 1];
  return '${mes[0].toUpperCase()}${mes.substring(1)} ${f.year}';
}

/// "25/09/2026".
String fechaCorta(DateTime f) => '${_dos(f.day)}/${_dos(f.month)}/${f.year}';

/// "6:30 p. m." a partir de hora y minuto en 24 h.
String hora12hDe(int hora, int minuto) {
  final h = hora % 12 == 0 ? 12 : hora % 12;
  final sufijo = hora < 12 ? 'a. m.' : 'p. m.';
  return '$h:${_dos(minuto)} $sufijo';
}

/// "6:30 p. m." en la hora local del dispositivo.
String hora12h(DateTime f) {
  final l = f.toLocal();
  return hora12hDe(l.hour, l.minute);
}

/// Convierte "18:30" (24 h, como lo envía el backend) a "6:30 p. m.".
/// Si el texto no es una hora válida lo devuelve igual.
String hora12hDesdeTexto(String hhmm) {
  final partes = hhmm.trim().split(':');
  if (partes.length < 2) return hhmm;
  final h = int.tryParse(partes[0]);
  final m = int.tryParse(partes[1]);
  if (h == null || m == null || h < 0 || h > 23 || m < 0 || m > 59) {
    return hhmm;
  }
  return hora12hDe(h, m);
}

/// "25/09/2026 7:05 a. m." en hora local.
String fechaHora(DateTime f) {
  final l = f.toLocal();
  return '${fechaCorta(l)} ${hora12h(l)}';
}

/// "25/09 7:05 a. m." en hora local.
String diaMesHora(DateTime f) {
  final l = f.toLocal();
  return '${_dos(l.day)}/${_dos(l.month)} ${hora12h(l)}';
}

/// "2026-09-25".
String fechaIso(DateTime f) => '${f.year}-${_dos(f.month)}-${_dos(f.day)}';

final _hora24 = RegExp(r'\b([01]?\d|2[0-3]):([0-5]\d)\b(?!\s?[ap]\. ?m\.)(?!:\d)');

/// Reescribe en 12 h cada hora "HH:mm" dentro de un texto, p. ej. el nombre de
/// sesión "2026-10-01 18:30-19:30" que guardaban las justificaciones antiguas.
String horasEnTexto12h(String texto) => texto.replaceAllMapped(
      _hora24,
      (m) => hora12hDe(int.parse(m[1]!), int.parse(m[2]!)),
    );
