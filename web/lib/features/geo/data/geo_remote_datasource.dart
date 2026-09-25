import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import 'models/geo_models.dart';

class GeoRemoteDataSource {
  final ApiClient _client;

  GeoRemoteDataSource({ApiClient? client}) : _client = client ?? ApiClient();

  Future<List<SedeModel>> getSedes() async {
    final response = await _client.get(ApiConstants.sedes);
    if (response is List) {
      return response
          .map((item) => SedeModel.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  Future<SedeModel> createSede({
    required String codigo,
    required String nombre,
    String? direccion,
  }) async {
    final response = await _client.post(
      ApiConstants.sedes,
      body: {
        'codigo': codigo,
        'nombre': nombre,
        if (direccion != null && direccion.isNotEmpty) 'direccion': direccion,
      },
    );
    return SedeModel.fromJson(response as Map<String, dynamic>);
  }

  Future<List<BloqueModel>> getBloques({String? sedeId}) async {
    var url = ApiConstants.bloques;
    if (sedeId != null && sedeId.isNotEmpty) {
      url += '?sedeId=$sedeId';
    }
    final response = await _client.get(url);
    if (response is List) {
      return response
          .map((item) => BloqueModel.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  Future<BloqueModel> createBloque({
    required String sedeId,
    required String codigo,
    required String nombre,
    required List<int> pisos,
  }) async {
    final response = await _client.post(
      ApiConstants.bloques,
      body: {
        'sedeId': sedeId,
        'codigo': codigo,
        'nombre': nombre,
        'pisos': pisos,
      },
    );
    return BloqueModel.fromJson(response as Map<String, dynamic>);
  }

  Future<List<EspacioModel>> getEspacios({
    String? sedeId,
    String? bloqueId,
  }) async {
    var url = ApiConstants.espacios;
    final params = <String>[];
    if (sedeId != null && sedeId.isNotEmpty) params.add('sedeId=$sedeId');
    if (bloqueId != null && bloqueId.isNotEmpty)
      params.add('bloqueId=$bloqueId');
    if (params.isNotEmpty) {
      url += '?${params.join('&')}';
    }

    final response = await _client.get(url);
    if (response is List) {
      return response
          .map((item) => EspacioModel.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  Future<EspacioModel> createEspacio({
    required String sedeId,
    String? bloqueId,
    int? piso,
    required String codigo,
    required String nombre,
    required int capacidad,
    required String tipo,
    String? facultadResponsable,
  }) async {
    final response = await _client.post(
      ApiConstants.espacios,
      body: {
        'sedeId': sedeId,
        if (bloqueId != null) 'bloqueId': bloqueId,
        if (piso != null) 'piso': piso,
        'codigo': codigo,
        'nombre': nombre,
        'capacidad': capacidad,
        'tipo': tipo,
        if (facultadResponsable != null)
          'facultadResponsable': facultadResponsable,
      },
    );
    return EspacioModel.fromJson(response as Map<String, dynamic>);
  }

  Future<void> deleteEspacio(String id) async {
    await _client.delete('${ApiConstants.espacios}/$id');
  }

  Future<List<SolapamientoItemModel>> getSolapamientos({String? sedeId}) async {
    var url = ApiConstants.solapamientos;
    if (sedeId != null && sedeId.isNotEmpty) {
      url += '?sedeId=$sedeId';
    }
    final response = await _client.get(url);
    if (response is List) {
      return response
          .map(
            (item) =>
                SolapamientoItemModel.fromJson(item as Map<String, dynamic>),
          )
          .toList();
    }
    return [];
  }
}
