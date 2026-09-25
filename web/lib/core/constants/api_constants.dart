class ApiConstants {
  ApiConstants._();

  static const String baseUrl = 'http://localhost:8080/api/v1';

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
}
