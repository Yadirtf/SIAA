import '../data/geo_remote_datasource.dart';
import '../data/models/geo_models.dart';

abstract class GeoRepository {
  Future<List<SedeModel>> getSedes();
  Future<SedeModel> createSede({required String codigo, required String nombre, String? direccion});
  Future<List<BloqueModel>> getBloques({String? sedeId});
  Future<BloqueModel> createBloque({
    required String sedeId,
    required String codigo,
    required String nombre,
    required List<int> pisos,
  });
  Future<List<EspacioModel>> getEspacios({String? sedeId, String? bloqueId});
  Future<EspacioModel> createEspacio({
    required String sedeId,
    String? bloqueId,
    int? piso,
    required String codigo,
    required String nombre,
    required int capacidad,
    required String tipo,
    String? facultadResponsable,
  });
  Future<void> deleteEspacio(String id);
  Future<List<SolapamientoItemModel>> getSolapamientos({String? sedeId});
}

class GeoRepositoryImpl implements GeoRepository {
  final GeoRemoteDataSource _remoteDataSource;

  GeoRepositoryImpl({GeoRemoteDataSource? remoteDataSource})
      : _remoteDataSource = remoteDataSource ?? GeoRemoteDataSource();

  @override
  Future<List<SedeModel>> getSedes() => _remoteDataSource.getSedes();

  @override
  Future<SedeModel> createSede({required String codigo, required String nombre, String? direccion}) =>
      _remoteDataSource.createSede(codigo: codigo, nombre: nombre, direccion: direccion);

  @override
  Future<List<BloqueModel>> getBloques({String? sedeId}) =>
      _remoteDataSource.getBloques(sedeId: sedeId);

  @override
  Future<BloqueModel> createBloque({
    required String sedeId,
    required String codigo,
    required String nombre,
    required List<int> pisos,
  }) =>
      _remoteDataSource.createBloque(sedeId: sedeId, codigo: codigo, nombre: nombre, pisos: pisos);

  @override
  Future<List<EspacioModel>> getEspacios({String? sedeId, String? bloqueId}) =>
      _remoteDataSource.getEspacios(sedeId: sedeId, bloqueId: bloqueId);

  @override
  Future<EspacioModel> createEspacio({
    required String sedeId,
    String? bloqueId,
    int? piso,
    required String codigo,
    required String nombre,
    required int capacidad,
    required String tipo,
    String? facultadResponsable,
  }) =>
      _remoteDataSource.createEspacio(
        sedeId: sedeId,
        bloqueId: bloqueId,
        piso: piso,
        codigo: codigo,
        nombre: nombre,
        capacidad: capacidad,
        tipo: tipo,
        facultadResponsable: facultadResponsable,
      );

  @override
  Future<void> deleteEspacio(String id) => _remoteDataSource.deleteEspacio(id);

  @override
  Future<List<SolapamientoItemModel>> getSolapamientos({String? sedeId}) =>
      _remoteDataSource.getSolapamientos(sedeId: sedeId);
}
