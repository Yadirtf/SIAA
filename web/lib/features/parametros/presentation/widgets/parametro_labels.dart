/// Etiquetas y ayudas legibles para las claves del catálogo de parámetros.
/// Las claves y valores vienen del backend; esto sólo las presenta.
const _etiquetas = {
  'holgura_entrada_antes_min': 'Holgura entrada (antes)',
  'holgura_entrada_despues_min': 'Holgura entrada (después)',
  'umbral_tardanza_min': 'Umbral de tardanza',
  'holgura_salida_antes_min': 'Holgura salida (antes)',
  'holgura_salida_despues_min': 'Holgura salida (después)',
  'precision_gps_max_metros': 'Precisión GPS máxima (m)',
  'buffer_perimetral_metros': 'Buffer perimetral (m)',
  'promedio_lecturas_vertice': 'Lecturas por vértice',
  'salida_obligatoria': 'Marcaje de salida',
  'offline_permitido': 'Marcaje offline',
  'bloqueo_mock_location': 'Bloquear ubicación simulada',
  'bloqueo_dispositivo_rooteado': 'Bloquear dispositivo rooteado',
  'verificacion_complementaria': 'Verificación complementaria',
  'exigir_attestation': 'Exigir attestation de Play Integrity',
  'porcentaje_minimo_asistencia': 'Porcentaje mínimo de asistencia',
  'inasistencias_consecutivas_alerta': 'Inasistencias consecutivas para alerta',
  'retencion_coordenadas_dias': 'Retención de coordenadas (días)',
};

const _ayudas = {
  'verificacion_complementaria':
      'Exigir verificación complementaria (WiFi/BLE/QR) en aulas que la '
      'tengan configurada',
  'exigir_attestation':
      'Exigir attestation de Play Integrity: requiere configurar '
      'PLAY_INTEGRITY_PACKAGE y PLAY_INTEGRITY_CREDENTIALS en el servidor; '
      'sin eso todos los marcajes se rechazan',
  'retencion_coordenadas_dias':
      'Solo aplica en ámbito GLOBAL. Pasado este plazo, las coordenadas de '
      'los marcajes se anonimizan (se conservan resultado y distancia).',
};

/// Nombre legible del parámetro; la clave técnica si no hay etiqueta.
String etiquetaParametro(String clave) => _etiquetas[clave] ?? clave;

/// Texto de ayuda del parámetro, o null si no tiene.
String? ayudaParametro(String clave) => _ayudas[clave];
