import 'package:siaa_web/features/geo/data/models/geo_models.dart';
import 'package:siaa_web/features/geo/domain/geo_repository.dart';

/// Repositorio de prueba: sólo implementa lo que usan los tests de geo.
class FakeGeoRepository implements GeoRepository {
  List<EspacioModel> espacios = [];
  Object? errorVerificacion;
  String? ultimoEspacioId;
  VerificacionEspacioModel? ultimaVerificacion;

  @override
  Future<EspacioModel> actualizarVerificacion(
    String espacioId,
    VerificacionEspacioModel verificacion,
  ) async {
    ultimoEspacioId = espacioId;
    ultimaVerificacion = verificacion;
    if (errorVerificacion != null) throw errorVerificacion!;
    final base = espacios.firstWhere((e) => e.id == espacioId);
    return EspacioModel(
      id: base.id,
      sedeId: base.sedeId,
      codigo: base.codigo,
      nombre: base.nombre,
      capacidad: base.capacidad,
      tipo: base.tipo,
      estado: base.estado,
      bufferMetros: base.bufferMetros,
      areaMetrosCuadrados: base.areaMetrosCuadrados,
      activo: base.activo,
      verificacionComplementaria: verificacion.configurada
          ? verificacion
          : null,
    );
  }

  @override
  Future<List<SedeModel>> getSedes() async => [
    const SedeModel(id: 's1', codigo: 'S1', nombre: 'Sede 1', activo: true),
  ];

  @override
  Future<List<BloqueModel>> getBloques({String? sedeId}) async => [];

  @override
  Future<List<EspacioModel>> getEspacios({
    String? sedeId,
    String? bloqueId,
  }) async => espacios;

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
}

EspacioModel espacioDePrueba({VerificacionEspacioModel? verificacion}) =>
    EspacioModel(
      id: 'e1',
      sedeId: 's1',
      codigo: 'AUL-101',
      nombre: 'Aula 101',
      capacidad: 30,
      tipo: 'AULA',
      estado: 'DISPONIBLE',
      bufferMetros: 0,
      areaMetrosCuadrados: 0,
      activo: true,
      verificacionComplementaria: verificacion,
    );
