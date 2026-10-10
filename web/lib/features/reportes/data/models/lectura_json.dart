/// Lectores tolerantes de JSON para los modelos de reportes operativos.
int jsonEntero(Object? v) => v is num ? v.toInt() : int.tryParse('$v') ?? 0;

double jsonDecimal(Object? v) =>
    v is num ? v.toDouble() : double.tryParse('$v') ?? 0;

String jsonTexto(Object? v) => v == null ? '' : v.toString();

DateTime? jsonFecha(Object? v) => v == null ? null : DateTime.tryParse('$v');

Map<String, dynamic> jsonMapa(Object? v) =>
    v is Map ? Map<String, dynamic>.from(v) : <String, dynamic>{};

List<Map<String, dynamic>> jsonLista(Object? v) => v is List
    ? v.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList()
    : const [];
