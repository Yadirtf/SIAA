// justificacion_form_cubit.dart — Radicación de justificaciones con soportes (US-JUS-01)
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/repositories/justificacion_repository.dart';
import '../../data/services/soporte_picker_service.dart';
import '../../domain/models/catalogo_justificacion.dart';
import '../../domain/models/justificacion_exception.dart';
import '../../domain/models/soporte_adjunto.dart';
import 'justificacion_form_state.dart';

class JustificacionFormCubit extends Cubit<JustificacionFormState> {
  final JustificacionRepository _repository;
  final SoportePickerService _picker;

  JustificacionFormCubit(
    this._repository, {
    required String sesionId,
    SoportePickerService? picker,
  })  : _picker = picker ?? SoportePickerService(),
        super(JustificacionFormState(sesionId: sesionId));

  void seleccionarTipo(TipoJustificacion tipo) =>
      emit(state.copyWith(tipo: tipo));

  /// Abre el selector del origen elegido y agrega el archivo si es válido.
  Future<void> adjuntar(OrigenSoporte origen) async {
    if (!state.puedeAdjuntar) return;
    emit(state.copyWith(envio: EnvioJustificacion.adjuntando));
    try {
      final soporte = await _picker.seleccionar(origen);
      emit(state.copyWith(envio: EnvioJustificacion.editando));
      if (soporte != null) agregarSoporte(soporte);
    } on JustificacionException catch (e) {
      emit(
          state.copyWith(envio: EnvioJustificacion.editando, error: e.mensaje));
    } catch (_) {
      emit(state.copyWith(
        envio: EnvioJustificacion.editando,
        error: 'No se pudo obtener el archivo. Inténtalo de nuevo.',
      ));
    }
  }

  /// Agrega un soporte ya leído validando formato, tamaño y cantidad.
  void agregarSoporte(SoporteAdjunto soporte) {
    if (state.soportes.length >= ReglasSoporte.maxArchivos) {
      emit(state.copyWith(error: 'Puedes adjuntar máximo 3 soportes'));
      return;
    }
    final invalido = soporte.validar();
    if (invalido != null) {
      emit(state.copyWith(error: invalido));
      return;
    }
    emit(state.copyWith(soportes: [...state.soportes, soporte]));
  }

  void quitarSoporte(int indice) {
    if (indice < 0 || indice >= state.soportes.length) return;
    final soportes = [...state.soportes]..removeAt(indice);
    emit(state.copyWith(soportes: soportes));
  }

  /// Valida en cliente y radica en el backend; muestra su "mensaje" si falla.
  Future<void> enviar(String descripcion) async {
    if (state.ocupado || state.envio == EnvioJustificacion.exito) return;
    final texto = descripcion.trim();
    final invalido = validarFormulario(state, texto);
    if (invalido != null) {
      emit(state.copyWith(error: invalido));
      return;
    }
    emit(state.copyWith(envio: EnvioJustificacion.enviando));
    try {
      final radicada = await _repository.radicar(
        sesionId: state.sesionId,
        tipo: state.tipo!.codigo,
        descripcion: texto,
        soportes: state.soportes,
      );
      emit(state.copyWith(envio: EnvioJustificacion.exito, radicada: radicada));
    } on JustificacionException catch (e) {
      emit(
          state.copyWith(envio: EnvioJustificacion.editando, error: e.mensaje));
    }
  }
}

/// Reglas previas al envío; el backend sigue siendo la autoridad.
String? validarFormulario(JustificacionFormState state, String descripcion) {
  if (state.sesionId.isEmpty) return 'No se identificó la sesión a justificar';
  if (state.tipo == null) return 'Selecciona el tipo de justificación';
  if (descripcion.length < ReglasSoporte.minDescripcion) {
    return 'La descripción debe tener al menos 10 caracteres';
  }
  if (state.soportes.isEmpty) return 'Adjunta al menos un soporte';
  return null;
}
