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

/// "25/09/2026 07:05" en hora local.
String fechaHora(DateTime f) {
  final l = f.toLocal();
  return '${fechaCorta(l)} ${_dos(l.hour)}:${_dos(l.minute)}';
}

/// "2026-09-25".
String fechaIso(DateTime f) => '${f.year}-${_dos(f.month)}-${_dos(f.day)}';
