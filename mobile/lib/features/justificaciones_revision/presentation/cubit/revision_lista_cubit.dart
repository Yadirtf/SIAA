// revision_lista_cubit.dart — Bandeja de justificaciones por estado con nombres de docentes
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/network/api_error.dart';
import '../../../justificaciones/domain/models/catalogo_justificacion.dart';
import '../../../justificaciones/domain/models/justificacion_model.dart';
import '../../data/resolutor_nombres.dart';
import '../../data/revision_remote_datasource.dart';

enum EstadoRevisionLista { cargando, listo, error }

class RevisionListaState extends Equatable {
  final EstadoRevisionLista estado;

  /// Por defecto las pendientes de decisión (radicadas).
  final EstadoJustificacion? filtro;
  final List<Justificacion> items;
  final int total;
  final Map<String, String> nombres;
  final String? error;

  const RevisionListaState({
    this.estado = EstadoRevisionLista.cargando,
    this.filtro = EstadoJustificacion.radicada,
    this.items = const [],
    this.total = 0,
    this.nombres = const {},
    this.error,
  });

  String nombreDocente(String id) => nombres[id] ?? 'Docente';

  RevisionListaState copyWith({
    EstadoRevisionLista? estado,
    EstadoJustificacion? filtro,
    bool todas = false,
    List<Justificacion>? items,
    int? total,
    Map<String, String>? nombres,
    String? error,
  }) {
    return RevisionListaState(
      estado: estado ?? this.estado,
      filtro: todas ? null : (filtro ?? this.filtro),
      items: items ?? this.items,
      total: total ?? this.total,
      nombres: nombres ?? this.nombres,
      error: error,
    );
  }

  @override
  List<Object?> get props => [estado, filtro, items, total, nombres, error];
}

class RevisionListaCubit extends Cubit<RevisionListaState> {
  final RevisionRemoteDataSource _remote;
  final ResolutorNombres nombres;

  RevisionListaCubit({RevisionRemoteDataSource? remote})
      : this._(remote ?? RevisionRemoteDataSource());

  RevisionListaCubit._(this._remote)
      : nombres = ResolutorNombres(_remote),
        super(const RevisionListaState());

  Future<void> cambiarFiltro(EstadoJustificacion? filtro) async {
    emit(state.copyWith(filtro: filtro, todas: filtro == null));
    await cargar();
  }

  Future<void> cargar() async {
    emit(state.copyWith(estado: EstadoRevisionLista.cargando));
    try {
      final pagina = await _remote.listar(estado: state.filtro?.codigo);
      final conocidos =
          await nombres.resolver(pagina.items.map((j) => j.docenteId));
      emit(state.copyWith(
        estado: EstadoRevisionLista.listo,
        items: pagina.items,
        total: pagina.total,
        nombres: conocidos,
      ));
    } catch (e) {
      emit(state.copyWith(
        estado: EstadoRevisionLista.error,
        error: mensajeDeError(e,
            porDefecto: 'No se pudieron cargar las justificaciones.'),
      ));
    }
  }
}
