// espacios_jerarquia_cubit.dart — Carga perezosa de la jerarquía física por sede (US-GEO-01)
// GET /sedes, y por sede GET /bloques?sedeId= y GET /espacios?sedeId= (aula:leer).
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/network/api_error.dart';
import '../../../geo_editor/data/espacio_repository.dart';
import '../../domain/jerarquia_sede.dart';

enum EstadoCarga { cargando, listo, error }

class DetalleSede extends Equatable {
  final EstadoCarga estado;
  final JerarquiaSede? jerarquia;
  final String? error;

  const DetalleSede(
      {this.estado = EstadoCarga.cargando, this.jerarquia, this.error});

  @override
  List<Object?> get props => [estado, jerarquia, error];
}

class EspaciosJerarquiaState extends Equatable {
  final EstadoCarga estado;
  final List<SedeModel> sedes;
  final Map<String, DetalleSede> detalles;
  final String? error;

  const EspaciosJerarquiaState({
    this.estado = EstadoCarga.cargando,
    this.sedes = const [],
    this.detalles = const {},
    this.error,
  });

  EspaciosJerarquiaState conDetalle(String sedeId, DetalleSede d) =>
      EspaciosJerarquiaState(
          estado: estado,
          sedes: sedes,
          detalles: {...detalles, sedeId: d},
          error: error);

  @override
  List<Object?> get props => [estado, sedes, detalles, error];
}

class EspaciosJerarquiaCubit extends Cubit<EspaciosJerarquiaState> {
  final EspacioRepository _repo;

  EspaciosJerarquiaCubit({EspacioRepository? repository})
      : _repo = repository ?? EspacioRepository(),
        super(const EspaciosJerarquiaState());

  Future<void> cargarSedes() async {
    emit(const EspaciosJerarquiaState());
    try {
      final sedes = [...await _repo.obtenerSedes()]
        ..sort((a, b) => a.nombre.compareTo(b.nombre));
      emit(EspaciosJerarquiaState(estado: EstadoCarga.listo, sedes: sedes));
    } catch (e) {
      emit(EspaciosJerarquiaState(
        estado: EstadoCarga.error,
        error:
            mensajeDeError(e, porDefecto: 'No se pudieron cargar las sedes.'),
      ));
    }
  }

  /// Carga bloques y aulas de la sede (se llama al expandirla y tras editar un polígono).
  Future<void> cargarSede(String sedeId, {bool forzar = false}) async {
    final actual = state.detalles[sedeId];
    if (!forzar && actual != null && actual.estado != EstadoCarga.error) return;
    emit(state.conDetalle(sedeId, const DetalleSede()));
    try {
      final datos = await Future.wait([
        _repo.obtenerBloques(sedeId: sedeId),
        _repo.obtenerEspacios(sedeId: sedeId),
      ]);
      emit(state.conDetalle(
        sedeId,
        DetalleSede(
          estado: EstadoCarga.listo,
          jerarquia: JerarquiaSede(
            bloques: datos[0] as List<BloqueModel>,
            espacios: datos[1] as List<EspacioModel>,
          ),
        ),
      ));
    } catch (e) {
      emit(state.conDetalle(
        sedeId,
        DetalleSede(
          estado: EstadoCarga.error,
          error:
              mensajeDeError(e, porDefecto: 'No se pudieron cargar las aulas.'),
        ),
      ));
    }
  }
}
