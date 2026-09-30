/// Estados y tipos de novedad del flujo de justificaciones (RF-JUS-003).
class JustificacionCatalogos {
  JustificacionCatalogos._();

  static const String radicada = 'RADICADA';
  static const String enRevision = 'EN_REVISION';
  static const String aprobada = 'APROBADA';
  static const String rechazada = 'RECHAZADA';

  /// Longitud mínima de las observaciones al rechazar (validada en backend).
  static const int minObservaciones = 10;

  static const Map<String, String> estados = {
    radicada: 'Radicada',
    enRevision: 'En revisión',
    aprobada: 'Aprobada',
    rechazada: 'Rechazada',
  };

  static const Map<String, String> tipos = {
    'INCAPACIDAD': 'Incapacidad',
    'COMISION': 'Comisión',
    'PERMISO': 'Permiso',
    'FALLA_TECNICA': 'Falla técnica',
    'CALAMIDAD': 'Calamidad',
  };

  static String etiquetaEstado(String estado) => estados[estado] ?? estado;

  static String etiquetaTipo(String tipo) => tipos[tipo] ?? tipo;

  /// Solo las justificaciones radicadas o en revisión admiten decisión.
  static bool esPendiente(String estado) =>
      estado == radicada || estado == enRevision;
}
