// formato_fechas.dart — Formato de fechas de justificaciones
import 'package:intl/intl.dart';

import '../../../../core/utils/fechas_es.dart';

/// Convierte 'YYYY-MM-DD' a 'dd/MM/yyyy'; devuelve el texto original si no aplica.
String formatearFechaSesion(String fecha) {
  final f = DateTime.tryParse(fecha);
  return f == null ? fecha : DateFormat('dd/MM/yyyy').format(f);
}

/// Fecha y hora local legible ("25/09/2026 6:30 p. m.").
String formatearMomento(DateTime momento) => fechaHora(momento);
