import 'api_exception.dart';

/// Extrae los errores por campo (`detalles: [{campo, error}]`) de una
/// respuesta 422 del backend, agrupados por nombre de campo.
Map<String, List<String>> erroresDeCampo(Object e) {
  if (e is! ApiException) return const {};
  final details = e.details;
  if (details is! Map || details['detalles'] is! List) return const {};
  final errores = <String, List<String>>{};
  for (final d in details['detalles'] as List) {
    if (d is! Map) continue;
    final campo = d['campo']?.toString() ?? '';
    final error = d['error']?.toString() ?? '';
    if (error.isEmpty) continue;
    errores.putIfAbsent(campo, () => []).add(error);
  }
  return errores;
}
