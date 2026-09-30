// formato_fechas.dart — Formato de fechas de justificaciones
import 'package:intl/intl.dart';

/// Convierte 'YYYY-MM-DD' a 'dd/MM/yyyy'; devuelve el texto original si no aplica.
String formatearFechaSesion(String fecha) {
  final f = DateTime.tryParse(fecha);
  return f == null ? fecha : DateFormat('dd/MM/yyyy').format(f);
}

/// Fecha y hora local legible (dd/MM/yyyy hh:mm a).
String formatearMomento(DateTime momento) =>
    DateFormat('dd/MM/yyyy hh:mm a').format(momento.toLocal());
