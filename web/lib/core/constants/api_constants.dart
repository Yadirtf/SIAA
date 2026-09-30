class ApiConstants {
  ApiConstants._();

  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8080/api/v1',
  );

  // Auth
  static const String login = '$baseUrl/auth/login';
  static const String refresh = '$baseUrl/auth/refresh';
  static const String logout = '$baseUrl/auth/logout';
  static const String recuperar = '$baseUrl/auth/recuperar';
  static const String confirmarRecuperar = '$baseUrl/auth/recuperar/confirmar';

  // Geo
  static const String sedes = '$baseUrl/sedes';
  static const String bloques = '$baseUrl/bloques';
  static const String espacios = '$baseUrl/espacios';
  static const String solapamientos = '$baseUrl/espacios/solapamientos';

  // Academico
  static const String periodos = '$baseUrl/periodos';
  static const String facultades = '$baseUrl/facultades';
  static const String programas = '$baseUrl/programas';
  static const String asignaturas = '$baseUrl/asignaturas';
  static const String grupos = '$baseUrl/grupos';
  static const String asignaciones = '$baseUrl/asignaciones';
  static const String excepciones = '$baseUrl/calendario-excepciones';

  // Dispositivos (US-AUT-03)
  static String dispositivosUsuario(String usuarioId) =>
      '$baseUrl/usuarios/$usuarioId/dispositivos';
  static String aprobarDispositivo(String dispositivoId) =>
      '$baseUrl/dispositivos/$dispositivoId/aprobar';
  static String revocarDispositivo(String dispositivoId) =>
      '$baseUrl/dispositivos/$dispositivoId/revocar';

  // Parámetros jerárquicos (EP-05, US-PAR-01/02/03)
  static const String parametros = '$baseUrl/parametros';
  static const String parametrosEfectivos = '$baseUrl/parametros/efectivos';

  // Marcajes (EP-06, US-MAR-09)
  static const String marcajes = '$baseUrl/marcajes';
  static String ajustarMarcaje(String marcajeId) =>
      '$baseUrl/marcajes/$marcajeId';
  static const String marcajeManual = '$baseUrl/marcajes/manual';
  static const String sesiones = '$baseUrl/sesiones';
  static const String academicoImportarPreview =
      '$baseUrl/academico/importar/preview';
  static const String academicoImportar = '$baseUrl/academico/importar';

  // Usuarios (US-ROL-01..05, US-AUT-02/07)
  static const String usuarios = '$baseUrl/usuarios';
  static const String usuariosImportar = '$baseUrl/usuarios/importar';
  static const String roles = '$baseUrl/roles';
  static String usuario(String id) => '$baseUrl/usuarios/$id';
  static String activarUsuario(String id) => '$baseUrl/usuarios/$id/activar';
  static String desactivarUsuario(String id) =>
      '$baseUrl/usuarios/$id/desactivar';
  static String rolesUsuario(String id) => '$baseUrl/usuarios/$id/roles';
  static String ambitosUsuario(String id) => '$baseUrl/usuarios/$id/ambitos';
  static String desbloquearUsuario(String id) =>
      '$baseUrl/usuarios/$id/desbloquear';
  static String revocarSesionesUsuario(String id) =>
      '$baseUrl/usuarios/$id/revocar-sesiones';

  // Justificaciones (EP-07, US-JUS-02/03)
  static const String justificaciones = '$baseUrl/justificaciones';
  static String justificacion(String id) => '$baseUrl/justificaciones/$id';
  static String soporteJustificacion(String id, String soporteId) =>
      '$baseUrl/justificaciones/$id/soportes/$soporteId';

  // Reportes (EP-08)
  static const String reporteCumplimiento = '$baseUrl/reportes/cumplimiento';
  static const String exportarCumplimiento =
      '$baseUrl/reportes/cumplimiento/exportar';

  // Auditoría (RF-AUD-003)
  static const String auditoria = '$baseUrl/auditoria';
  static const String exportarAuditoria = '$baseUrl/auditoria/exportar';

  // Privacidad (RNF-LEG-003, US-LEG-01): endpoint público, sin token.
  static const String politicaPrivacidad = '$baseUrl/privacidad/politica';
}
