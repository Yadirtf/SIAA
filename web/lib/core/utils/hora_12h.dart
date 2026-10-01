/// Hora en formato de 12 horas como se lee en Colombia: `6:30 p. m.`.
/// El backend siempre guarda y recibe `HH:mm` de 24 horas en hora de Bogotá;
/// esto es solo para mostrarla sin ambigüedad.
String hora12h(int hora, int minuto) {
  final h = hora % 12 == 0 ? 12 : hora % 12;
  final sufijo = hora < 12 ? 'a. m.' : 'p. m.';
  return '$h:${minuto.toString().padLeft(2, '0')} $sufijo';
}

/// Convierte `HH:mm` (24 h) a 12 h. Si el texto no es una hora, lo devuelve igual.
String hora12hDesdeTexto(String hhmm) {
  final partes = hhmm.split(':');
  if (partes.length != 2) return hhmm;
  final hora = int.tryParse(partes[0]);
  final minuto = int.tryParse(partes[1]);
  if (hora == null || minuto == null || hora > 23 || minuto > 59) return hhmm;
  return hora12h(hora, minuto);
}
