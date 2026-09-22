// Repositorio administrativo para Sedes, Bloques y Espacios (US-GEO-01)
import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';

class AdminSede {
  final String id;
  final String codigo;
  final String nombre;
  final String? direccion;
  final bool activo;

  const AdminSede({
    required this.id,
    required this.codigo,
    required this.nombre,
    this.direccion,
    required this.activo,
  });

  factory AdminSede.fromJson(Map<String, dynamic> json) => AdminSede(
    id: json['id'] as String? ?? '',
    codigo: json['codigo'] as String? ?? '',
    nombre: json['nombre'] as String? ?? '',
    direccion: json['direccion'] as String?,
    activo: json['activo'] as bool? ?? true,
  );
}

class AdminBloque {
  final String id;
  final String sedeId;
  final String codigo;
  final String nombre;
  final List<int> pisos;
  final bool activo;

  const AdminBloque({
    required this.id,
    required this.sedeId,
    required this.codigo,
    required this.nombre,
    required this.pisos,
    required this.activo,
  });

  factory AdminBloque.fromJson(Map<String, dynamic> json) => AdminBloque(
    id: json['id'] as String? ?? '',
    sedeId: json['sedeId'] as String? ?? '',
    codigo: json['codigo'] as String? ?? '',
    nombre: json['nombre'] as String? ?? '',
    pisos: (json['pisos'] as List<dynamic>? ?? []).cast<int>(),
    activo: json['activo'] as bool? ?? true,
  );
}

class AdminEspacio {
  final String id;
  final String sedeId;
  final String? bloqueId;
  final int? piso;
  final String codigo;
  final String nombre;
  final int capacidad;
  final String tipo;
  final String estado;
  final String nivelValidacion;
  final double bufferMetros;
  final double areaMetrosCuadrados;
  final double? precisionPromedioMetros;
  final String? metodoCaptura;
  final bool tieneGeometria;
  final int versionGeometria;
  final bool activo;

  const AdminEspacio({
    required this.id,
    required this.sedeId,
    this.bloqueId,
    this.piso,
    required this.codigo,
    required this.nombre,
    required this.capacidad,
    required this.tipo,
    required this.estado,
    required this.nivelValidacion,
    required this.bufferMetros,
    required this.areaMetrosCuadrados,
    this.precisionPromedioMetros,
    this.metodoCaptura,
    required this.tieneGeometria,
    required this.versionGeometria,
    required this.activo,
  });

  factory AdminEspacio.fromJson(Map<String, dynamic> json) {
    final geo = json['geometria'] as Map<String, dynamic>?;
    final tieneGeo = geo != null && geo['coordinates'] != null;

    return AdminEspacio(
      id: json['id'] as String? ?? '',
      sedeId: json['sedeId'] as String? ?? '',
      bloqueId: json['bloqueId'] as String?,
      piso: json['piso'] as int?,
      codigo: json['codigo'] as String? ?? '',
      nombre: json['nombre'] as String? ?? '',
      capacidad: json['capacidad'] as int? ?? 0,
      tipo: json['tipo'] as String? ?? 'AULA',
      estado: json['estado'] as String? ?? 'ACTIVO',
      nivelValidacion: json['nivelValidacion'] as String? ?? 'AULA',
      bufferMetros: (json['bufferMetros'] as num?)?.toDouble() ?? 10.0,
      areaMetrosCuadrados: (json['areaMetrosCuadrados'] as num?)?.toDouble() ?? 0.0,
      precisionPromedioMetros: (json['precisionPromedioMetros'] as num?)?.toDouble(),
      metodoCaptura: json['metodoCaptura'] as String?,
      tieneGeometria: tieneGeo,
      versionGeometria: json['versionGeometria'] as int? ?? 1,
      activo: json['activo'] as bool? ?? true,
    );
  }
}

class AdminGeoRepository {
  final Dio _client;

  AdminGeoRepository({Dio? client}) : _client = client ?? WebApiClient.instance;

  // ─── SEDES ─────────────────────────────────────────────────────────────

  Future<List<AdminSede>> listarSedes() async {
    try {
      final res = await _client.get('/sedes');
      final list = res.data as List<dynamic>;
      return list.map((e) => AdminSede.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw Exception(e.response?.data?['mensaje'] ?? 'Error al listar sedes');
    }
  }

  Future<AdminSede> crearSede({
    required String codigo,
    required String nombre,
    String? direccion,
  }) async {
    try {
      final res = await _client.post('/sedes', data: {
        'codigo': codigo,
        'nombre': nombre,
        if (direccion != null) 'direccion': direccion,
      });
      return AdminSede.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw Exception(e.response?.data?['mensaje'] ?? 'Error al crear sede');
    }
  }

  // ─── BLOQUES ───────────────────────────────────────────────────────────

  Future<List<AdminBloque>> listarBloques({String? sedeId}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (sedeId != null && sedeId.isNotEmpty) queryParams['sedeId'] = sedeId;

      final res = await _client.get('/bloques', queryParameters: queryParams);
      final list = res.data as List<dynamic>;
      return list.map((e) => AdminBloque.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw Exception(e.response?.data?['mensaje'] ?? 'Error al listar bloques');
    }
  }

  Future<AdminBloque> crearBloque({
    required String sedeId,
    required String codigo,
    required String nombre,
    List<int> pisos = const [1],
  }) async {
    try {
      final res = await _client.post('/bloques', data: {
        'sedeId': sedeId,
        'codigo': codigo,
        'nombre': nombre,
        'pisos': pisos,
      });
      return AdminBloque.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw Exception(e.response?.data?['mensaje'] ?? 'Error al crear bloque');
    }
  }

  // ─── ESPACIOS ──────────────────────────────────────────────────────────

  Future<List<AdminEspacio>> listarEspacios({
    String? sedeId,
    String? bloqueId,
    String? tipo,
    String? estado,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (sedeId != null && sedeId.isNotEmpty) queryParams['sedeId'] = sedeId;
      if (bloqueId != null && bloqueId.isNotEmpty) queryParams['bloqueId'] = bloqueId;
      if (tipo != null && tipo.isNotEmpty) queryParams['tipo'] = tipo;
      if (estado != null && estado.isNotEmpty) queryParams['estado'] = estado;

      final res = await _client.get('/espacios', queryParameters: queryParams);
      final list = res.data as List<dynamic>;
      return list.map((e) => AdminEspacio.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw Exception(e.response?.data?['mensaje'] ?? 'Error al listar espacios');
    }
  }

  Future<AdminEspacio> crearEspacio({
    required String sedeId,
    String? bloqueId,
    int? piso,
    required String codigo,
    required String nombre,
    required int capacidad,
    required String tipo,
    String nivelValidacion = 'AULA',
    double bufferMetros = 10.0,
  }) async {
    try {
      final res = await _client.post('/espacios', data: {
        'sedeId': sedeId,
        if (bloqueId != null) 'bloqueId': bloqueId,
        if (piso != null) 'piso': piso,
        'codigo': codigo,
        'nombre': nombre,
        'capacidad': capacidad,
        'tipo': tipo,
        'nivelValidacion': nivelValidacion,
        'bufferMetros': bufferMetros,
      });
      return AdminEspacio.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw Exception(e.response?.data?['mensaje'] ?? 'Error al crear espacio');
    }
  }

  Future<void> eliminarEspacio(String id) async {
    try {
      await _client.delete('/espacios/$id');
    } on DioException catch (e) {
      throw Exception(e.response?.data?['mensaje'] ?? 'Error al eliminar espacio');
    }
  }
}
