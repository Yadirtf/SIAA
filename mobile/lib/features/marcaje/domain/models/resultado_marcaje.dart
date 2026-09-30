// resultado_marcaje.dart — Clasificación y etiqueta de los resultados de marcaje (US-MAR-08)
// Valores del backend: PRESENTE, TARDANZA, AUSENTE, PRECISION_INSUFICIENTE, RECHAZADO_* y
// los alias VALIDO, RETARDO, FUERA_DE_AREA, FUERA_DE_TIEMPO.

enum CategoriaResultado { aceptado, tardanza, ausencia, rechazado, desconocido }

CategoriaResultado categoriaDeResultado(String resultado) {
  switch (resultado.toUpperCase()) {
    case 'PRESENTE':
    case 'VALIDO':
    case 'ACEPTADO':
      return CategoriaResultado.aceptado;
    case 'TARDANZA':
    case 'RETARDO':
      return CategoriaResultado.tardanza;
    case 'AUSENTE':
    case 'AUSENCIA_AUTOMATICA':
      return CategoriaResultado.ausencia;
    case '':
      return CategoriaResultado.desconocido;
    default:
      return CategoriaResultado.rechazado;
  }
}

/// Etiquetas legibles de los resultados (también usadas en los filtros).
const etiquetasResultado = {
  'PRESENTE': 'Presente',
  'TARDANZA': 'Tardanza',
  'AUSENTE': 'Ausente',
  'PRECISION_INSUFICIENTE': 'Precisión GPS insuficiente',
  'RECHAZADO_FUERA_DE_AREA': 'Fuera del aula',
  'RECHAZADO_FUERA_DE_HORARIO': 'Fuera de horario',
  'RECHAZADO_INTEGRIDAD': 'Dispositivo no confiable',
  'RECHAZADO_SIN_ASIGNACION': 'Sin asignación',
  'RECHAZADO_VERIFICACION': 'Verificación fallida',
};

String etiquetaResultado(String resultado) =>
    etiquetasResultado[resultado.toUpperCase()] ??
    (resultado.isEmpty ? 'Sin resultado' : resultado.replaceAll('_', ' '));

/// Etiquetas legibles del origen del marcaje.
String etiquetaOrigen(String origen) {
  switch (origen.toUpperCase()) {
    case 'APP_MOVIL':
    case 'MOVIL_ONLINE':
      return 'App móvil';
    case 'MOVIL_OFFLINE':
    case 'OFFLINE':
      return 'App móvil (sin conexión)';
    case 'MANUAL':
    case 'MANUAL_DOCENTE':
      return 'Registro manual';
    case 'AJUSTE':
      return 'Ajuste administrativo';
    case 'SISTEMA_AUSENCIA':
    case 'SISTEMA_AUTOMATICO':
      return 'Automático del sistema';
    default:
      return origen.isEmpty ? '—' : origen;
  }
}
