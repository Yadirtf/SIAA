// etiqueta_registro.dart — Texto amable para el resultado y origen de un registro existente
// en el pase de lista manual (US-MAR-14).

/// "Presente", "Tardanza", "Ausente", "Rechazado"... a partir del código del servidor.
String etiquetaResultado(String? resultado) {
  final r = (resultado ?? '').toUpperCase();
  if (r.isEmpty) return 'Sin registro';
  if (r.startsWith('RECHAZADO')) return 'Rechazado';
  switch (r) {
    case 'PRESENTE':
    case 'ACEPTADO':
    case 'VALIDO':
      return 'Presente';
    case 'TARDANZA':
      return 'Tardanza';
    case 'AUSENTE':
    case 'AUSENCIA':
      return 'Ausente';
    case 'PENDIENTE_SINCRONIZACION':
      return 'Pendiente';
  }
  final texto = r.replaceAll('_', ' ').toLowerCase();
  return '${texto[0].toUpperCase()}${texto.substring(1)}';
}

/// "con la app", "en lista manual"... o null si el origen no se conoce.
String? etiquetaOrigen(String? origen) {
  switch ((origen ?? '').toUpperCase()) {
    case 'APP_MOVIL':
      return 'con la app';
    case 'OFFLINE':
      return 'con la app (sin conexión)';
    case 'MANUAL':
    case 'MANUAL_DOCENTE':
      return 'en lista manual';
    case 'AJUSTE':
      return 'por ajuste administrativo';
  }
  return null;
}
