// Repositorio de espacios y cartografía — data layer
// Permite listar aulas/espacios y enviar la geometría capturada al backend (US-GEO-01, US-GEO-02, US-GEO-03)
import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';

class EspacioModel {
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
  final bool tieneGeometria;
  final List<List<double>>? coordenadas;

  const EspacioModel({
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
    required this.tieneGeometria,
    this.coordenadas,
  });

  factory EspacioModel.fromJson(Map<String, dynamic> json) {
    List<List<double>>? coords;
    final geo = json['geometria'] as Map<String, dynamic>?;
    if (geo != null && geo['coordinates'] is List) {
      final rings = geo['coordinates'] as List<dynamic>;
      if (rings.isNotEmpty && rings.first is List) {
        final ring = rings.first as List<dynamic>;
        coords = ring.map<List<double>>((pt) {
          final p = pt as List<dynamic>;
          return [
            (p[0] as num).toDouble(),
            (p[1] as num).toDouble(),
          ];
        }).toList();
      }
    }

    return EspacioModel(
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
      tieneGeometria: coords != null && coords.isNotEmpty,
      coordenadas: coords,
    );
  }
}

class EspacioRepository {
  final Dio _client;

  EspacioRepository({Dio? client}) : _client = client ?? ApiClient.instance;

  /// Obtiene la lista de espacios/aulas desde el backend.
  Future<List<EspacioModel>> obtenerEspacios({
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

      final response = await _client.get('/espacios', queryParameters: queryParams);
      final list = response.data as List<dynamic>;
      return list
          .map((item) => EspacioModel.fromJson(item as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      final errorMsg = e.response?.data?['mensaje'] ?? e.message ?? 'Error al consultar espacios';
      throw Exception(errorMsg);
    }
  }

  /// Obtiene el detalle de un espacio por su identificador.
  Future<EspacioModel> obtenerEspacioPorId(String id) async {
    try {
      final response = await _client.get('/espacios/$id');
      return EspacioModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      final errorMsg = e.response?.data?['mensaje'] ?? e.message ?? 'Error al obtener espacio';
      throw Exception(errorMsg);
    }
  }

  /// Guarda o actualiza la geometría perimetral del espacio (PUT /api/v1/espacios/:id/geometria)
  /// AC-06, AC-07, ADR-04.
  Future<EspacioModel> guardarGeometria({
    required String espacioId,
    required List<List<double>> coordenadas,
    required String metodoCaptura,
    double? precisionPromedioMetros,
  }) async {
    try {
      final payload = <String, dynamic>{
        'coordenadas': coordenadas,
        'metodoCaptura': metodoCaptura,
      };
      if (precisionPromedioMetros != null) {
        payload['precisionPromedioMetros'] = precisionPromedioMetros;
      }

      final response = await _client.put(
        '/espacios/$espacioId/geometria',
        data: payload,
      );

      return EspacioModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      final errorMsg = e.response?.data?['mensaje'] ?? e.message ?? 'Error al guardar geometría en el servidor';
      throw Exception(errorMsg);
    }
  }
}
