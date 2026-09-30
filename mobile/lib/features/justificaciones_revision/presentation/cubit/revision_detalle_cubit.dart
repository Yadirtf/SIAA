// revision_detalle_cubit.dart — Detalle y decisión de una justificación (RF-JUS-002)
// Transiciones: RADICADA → EN_REVISION; RADICADA|EN_REVISION → APROBADA|RECHAZADA.
import 'dart:typed_data';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/network/api_error.dart';
import '../../../justificaciones/domain/models/catalogo_justificacion.dart';
import '../../../justificaciones/domain/models/justificacion_model.dart';
import '../../data/resolutor_nombres.dart';
import '../../data/revision_remote_datasource.dart';

class RevisionDetalleState extends Equatable {
  final Justificacion justificacion;
  final Map<String, String> nombres;
  final bool procesando;
  final String? error;

  const RevisionDetalleState({
    required this.justificacion,
    this.nombres = const {},
    this.procesando = false,
    this.error,
  });

  String nombreDe(String id, {String porDefecto = 'Usuario'}) =>
      nombres[id] ?? porDefecto;

  bool get puedeTomar =>
      justificacion.estado == EstadoJustificacion.radicada.codigo;
  bool get puedeDecidir => !justificacion.estaCerrada;

  RevisionDetalleState copyWith({
    Justificacion? justificacion,
    Map<String, String>? nombres,
    bool? procesando,
    String? error,
  }) {
    return RevisionDetalleState(
      justificacion: justificacion ?? this.justificacion,
      nombres: nombres ?? this.nombres,
      procesando: procesando ?? this.procesando,
      error: error,
    );
  }

  @override
  List<Object?> get props => [justificacion, nombres, procesando, error];
}

class RevisionDetalleCubit extends Cubit<RevisionDetalleState> {
  /// Mínimo de caracteres de observaciones para rechazar (MinObservaciones del backend).
  static const minObservacionesRechazo = 10;

  final RevisionRemoteDataSource _remote;
  final ResolutorNombres _nombres;

  RevisionDetalleCubit(this._remote, this._nombres, Justificacion inicial)
      : super(RevisionDetalleState(
            justificacion: inicial, nombres: _nombres.conocidos));

  Future<void> cargar() async {
    try {
      final j = await _remote.obtener(state.justificacion.id);
      final ids = {
        j.docenteId,
        j.revisorId ?? '',
        ...j.historial.map((e) => e.actorId)
      };
      emit(state.copyWith(
          justificacion: j, nombres: await _nombres.resolver(ids)));
    } catch (e) {
      emit(state.copyWith(error: mensajeDeError(e)));
    }
  }

  Future<String?> tomarEnRevision() =>
      _revisar(EstadoJustificacion.enRevision.codigo, null);

  Future<String?> aprobar(String? observaciones) =>
      _revisar(EstadoJustificacion.aprobada.codigo, observaciones);

  Future<String?> rechazar(String observaciones) {
    if (observaciones.trim().length < minObservacionesRechazo) {
      return Future.value(
          'Para rechazar escribe al menos $minObservacionesRechazo caracteres de observaciones.');
    }
    return _revisar(EstadoJustificacion.rechazada.codigo, observaciones);
  }

  Future<Uint8List> descargarSoporte(String soporteId) =>
      _remote.descargarSoporte(state.justificacion.id, soporteId);

  /// null si se aplicó la decisión; mensaje de error en otro caso.
  Future<String?> _revisar(String estado, String? observaciones) async {
    emit(state.copyWith(procesando: true));
    try {
      final j = await _remote.revisar(state.justificacion.id,
          estado: estado, observaciones: observaciones);
      emit(state.copyWith(justificacion: j, procesando: false));
      await cargar();
      return null;
    } catch (e) {
      final msg =
          mensajeDeError(e, porDefecto: 'No se pudo registrar la decisión.');
      emit(state.copyWith(procesando: false, error: msg));
      return msg;
    }
  }
}
