// catalogo_justificacion.dart — Tipos y estados de justificación (EP-07, RF-JUS-001)

/// Tipos de justificación aceptados por el backend.
enum TipoJustificacion {
  incapacidad('INCAPACIDAD', 'Incapacidad médica'),
  comision('COMISION', 'Comisión institucional'),
  permiso('PERMISO', 'Permiso autorizado'),
  fallaTecnica('FALLA_TECNICA', 'Falla técnica'),
  calamidad('CALAMIDAD', 'Calamidad doméstica');

  final String codigo;
  final String etiqueta;

  const TipoJustificacion(this.codigo, this.etiqueta);

  /// Etiqueta legible para un código del backend (o el código si es desconocido).
  static String etiquetaDe(String codigo) {
    for (final t in values) {
      if (t.codigo == codigo) return t.etiqueta;
    }
    return codigo;
  }
}

/// Estados del flujo de revisión de una justificación.
enum EstadoJustificacion {
  radicada('RADICADA', 'Radicada'),
  enRevision('EN_REVISION', 'En revisión'),
  aprobada('APROBADA', 'Aprobada'),
  rechazada('RECHAZADA', 'Rechazada');

  final String codigo;
  final String etiqueta;

  const EstadoJustificacion(this.codigo, this.etiqueta);

  /// Estado para un código del backend; `null` si no se reconoce.
  static EstadoJustificacion? desdeCodigo(String codigo) {
    for (final e in values) {
      if (e.codigo == codigo) return e;
    }
    return null;
  }

  static String etiquetaDe(String codigo) =>
      desdeCodigo(codigo)?.etiqueta ?? codigo;
}
