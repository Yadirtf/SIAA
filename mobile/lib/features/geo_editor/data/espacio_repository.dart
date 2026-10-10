// Repositorio de espacios y cartografía — data layer
// Permite listar aulas/espacios y enviar la geometría capturada al backend (US-GEO-01, US-GEO-02, US-GEO-03)
import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../domain/models/bloque_model.dart';
import '../domain/models/espacio_model.dart';
import '../domain/models/geometria_historial_item.dart';
import '../domain/models/sede_model.dart';
import '../domain/models/validacion_geometria_model.dart';
import 'geometria_exceptions.dart';

// Re-exportar modelos para mantener compatibilidad hacia atrás
export '../domain/models/bloque_model.dart';
export '../domain/models/espacio_model.dart';
export '../domain/models/sede_model.dart';
export '../domain/models/validacion_geometria_model.dart';
export 'geometria_exceptions.dart';

class EspacioRepository {
  final Dio _client;

  EspacioRepository({Dio? client}) : _client = client ?? ApiClient.instance;

  /// Obtiene la lista de sedes universitarias
  Future<List<SedeModel>> obtenerSedes() async {
    try {
      final response = await _client.get('/sedes');
      final list = response.data as List<dynamic>;
      return list
          .map((item) => SedeModel.fromJson(item as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      final errorMsg = e.response?.data?['mensaje'] ??
          e.message ??
          'Error al consultar sedes';
      throw Exception(errorMsg);
    }
  }

  /// Crea una nueva sede
  Future<SedeModel> crearSede({
    required String codigo,
    required String nombre,
    String? direccion,
  }) async {
    try {
      final response = await _client.post('/sedes', data: {
        'codigo': codigo,
        'nombre': nombre,
        'direccion': direccion ?? '',
      });
      return SedeModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      final errorMsg =
          e.response?.data?['mensaje'] ?? e.message ?? 'Error al crear sede';
      throw Exception(errorMsg);
    }
  }

  /// Obtiene los bloques de una sede
  Future<List<BloqueModel>> obtenerBloques({String? sedeId}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (sedeId != null && sedeId.isNotEmpty) queryParams['sedeId'] = sedeId;
      final response =
          await _client.get('/bloques', queryParameters: queryParams);
      final list = response.data as List<dynamic>;
      return list
          .map((item) => BloqueModel.fromJson(item as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      final errorMsg = e.response?.data?['mensaje'] ??
          e.message ??
          'Error al consultar bloques';
      throw Exception(errorMsg);
    }
  }

  /// Crea un nuevo bloque dentro de una sede
  Future<BloqueModel> crearBloque({
    required String sedeId,
    required String codigo,
    required String nombre,
    List<int>? pisos,
  }) async {
    try {
      final response = await _client.post('/bloques', data: {
        'sedeId': sedeId,
        'codigo': codigo,
        'nombre': nombre,
        'pisos': pisos ?? [1, 2, 3],
      });
      return BloqueModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      final errorMsg =
          e.response?.data?['mensaje'] ?? e.message ?? 'Error al crear bloque';
      throw Exception(errorMsg);
    }
  }

  /// Crea un nuevo espacio / aula en el backend
  Future<EspacioModel> crearEspacio({
    required String sedeId,
    String? bloqueId,
    int? piso,
    required String codigo,
    required String nombre,
    int capacidad = 30,
    String tipo = 'AULA',
    String? facultadResponsable,
    double bufferMetros = 10.0,
  }) async {
    try {
      final payload = <String, dynamic>{
        'sedeId': sedeId,
        'codigo': codigo,
        'nombre': nombre,
        'capacidad': capacidad,
        'tipo': tipo,
        'bufferMetros': bufferMetros,
      };
      if (bloqueId != null && bloqueId.isNotEmpty) {
        payload['bloqueId'] = bloqueId;
      }
      if (piso != null) payload['piso'] = piso;
      if (facultadResponsable != null && facultadResponsable.isNotEmpty) {
        payload['facultadResponsable'] = facultadResponsable;
      }

      final response = await _client.post('/espacios', data: payload);
      return EspacioModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      final errorMsg =
          e.response?.data?['mensaje'] ?? e.message ?? 'Error al crear espacio';
      throw Exception(errorMsg);
    }
  }

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
      if (bloqueId != null && bloqueId.isNotEmpty) {
        queryParams['bloqueId'] = bloqueId;
      }
      if (tipo != null && tipo.isNotEmpty) queryParams['tipo'] = tipo;
      if (estado != null && estado.isNotEmpty) queryParams['estado'] = estado;

      final response =
          await _client.get('/espacios', queryParameters: queryParams);
      final list = response.data as List<dynamic>;
      return list
          .map((item) => EspacioModel.fromJson(item as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      final errorMsg = e.response?.data?['mensaje'] ??
          e.message ??
          'Error al consultar espacios';
      throw Exception(errorMsg);
    }
  }

  /// Obtiene el detalle de un espacio por su identificador.
  Future<EspacioModel> obtenerEspacioPorId(String id) async {
    try {
      final response = await _client.get('/espacios/$id');
      return EspacioModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response == null && _esFalloDeRed(e)) {
        throw SinConexionGeometriaException();
      }
      final errorMsg = e.response?.data?['mensaje'] ??
          e.message ??
          'Error al obtener espacio';
      throw Exception(errorMsg);
    }
  }

  /// Guarda o actualiza la geometría perimetral del espacio (PUT /api/v1/espacios/:id/geometria)
  /// AC-06, AC-07, ADR-04, US-GEO-05 (AC-01..AC-03).
  Future<EspacioModel> guardarGeometria({
    required String espacioId,
    required List<List<double>> coordenadas,
    required String metodoCaptura,
    double? precisionPromedioMetros,
    bool confirmarSolapamiento = false,
    String? motivoSolapamiento,
    int? versionEsperada,
  }) async {
    try {
      final payload = <String, dynamic>{
        'coordenadas': coordenadas,
        'metodoCaptura': metodoCaptura,
        'confirmarSolapamiento': confirmarSolapamiento,
        if (precisionPromedioMetros != null)
          'precisionPromedioMetros': precisionPromedioMetros,
        if (motivoSolapamiento != null && motivoSolapamiento.isNotEmpty)
          'motivoSolapamiento': motivoSolapamiento,
        // Precondición optimista: 409 CONFLICTO_VERSION si otro la cambió.
        if (versionEsperada != null) 'versionEsperada': versionEsperada,
      };

      final response = await _client.put(
        '/espacios/$espacioId/geometria',
        data: payload,
      );

      return EspacioModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response == null && _esFalloDeRed(e)) {
        throw SinConexionGeometriaException();
      }
      throw excepcionGuardadoGeometria(e);
    }
  }

  /// Obtiene el historial de versiones archivadas de la geometría de un espacio (US-GEO-06 AC-04, T-GEO-06.3).
  Future<List<GeometriaHistorialItem>> obtenerVersionesGeometria(
      String espacioId) async {
    try {
      final response =
          await _client.get('/espacios/$espacioId/geometria/versiones');
      final list = response.data as List<dynamic>;
      return list
          .map((item) =>
              GeometriaHistorialItem.fromJson(item as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      final errorMsg = e.response?.data?['mensaje'] ??
          e.message ??
          'Error al obtener versiones de geometría';
      throw Exception(errorMsg);
    }
  }

  /// Valida en seco una geometría de polígono antes de persistirla (US-GEO-04, T-GEO-04.3).
  Future<ValidacionGeometriaModel> validarGeometria({
    required List<List<double>> coordenadas,
    double toleranciaMetros = 5.0,
    double longitudMinimaMetros = 1.0,
    double areaMinimaM2 = 4.0,
  }) async {
    try {
      final response = await _client.post(
        '/espacios/validar-geometria',
        data: {
          'coordenadas': coordenadas,
          'toleranciaMetros': toleranciaMetros,
          'longitudMinimaMetros': longitudMinimaMetros,
          'areaMinimaM2': areaMinimaM2,
        },
      );
      return ValidacionGeometriaModel.fromJson(
          response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      final data = e.response?.data;
      if (data is Map<String, dynamic>) {
        return ValidacionGeometriaModel.fromJson(data);
      }
      final errorMsg = e.response?.data?.toString() ??
          e.message ??
          'Error al validar geometría';
      throw Exception(errorMsg);
    }
  }

  static bool _esFalloDeRed(DioException e) =>
      e.type == DioExceptionType.connectionError ||
      e.type == DioExceptionType.connectionTimeout ||
      e.type == DioExceptionType.sendTimeout ||
      e.type == DioExceptionType.receiveTimeout;
}
