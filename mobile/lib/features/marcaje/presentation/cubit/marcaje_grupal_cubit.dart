// marcaje_grupal_cubit.dart — Abre y cierra la ventana de marcaje de estudiantes (US-MAR-13).
// El estado de la ventana viene del servidor (ventanaEstudiantil) para sobrevivir recargas.
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/network/api_error.dart';
import '../../../../core/utils/fechas_es.dart';
import '../../data/datasources/marcaje_grupal_remote_datasource.dart';
import '../../data/datasources/marcaje_remote_datasource.dart';
import '../../domain/models/sesion_activa_model.dart';
import '../../domain/models/ventana_estudiantil_model.dart';
import 'marcaje_grupal_state.dart';

typedef CargadorSesionActiva = Future<SesionActivaModel?> Function();

class MarcajeGrupalCubit extends Cubit<MarcajeGrupalState> {
  final MarcajeGrupalRemoteDataSource _grupal;
  final CargadorSesionActiva _cargarSesion;

  MarcajeGrupalCubit({
    MarcajeGrupalRemoteDataSource? grupal,
    CargadorSesionActiva? cargarSesion,
  })  : _grupal = grupal ?? MarcajeGrupalRemoteDataSource(),
        _cargarSesion =
            cargarSesion ?? MarcajeRemoteDataSource().obtenerSesionActiva,
        super(const MarcajeGrupalState());

  Future<void> cargar() async {
    if (state.sesion == null) {
      emit(state.copyWith(carga: CargaGrupal.cargando));
    }
    try {
      final sesion = await _cargarSesion();
      if (isClosed) return;
      if (sesion == null) {
        emit(MarcajeGrupalState(
          carga: CargaGrupal.sinSesion,
          duracionMinutos: state.duracionMinutos,
        ));
        return;
      }
      emit(MarcajeGrupalState(
        carga: CargaGrupal.lista,
        sesion: sesion,
        ventana: sesion.ventanaEstudiantil ?? VentanaEstudiantil.cerrada,
        duracionMinutos: state.duracionMinutos,
      ));
    } catch (e) {
      if (isClosed) return;
      if (state.sesion != null) {
        emit(state.conAviso(mensajeDeError(e), esError: true));
      } else {
        emit(
            state.copyWith(carga: CargaGrupal.error, error: mensajeDeError(e)));
      }
    }
  }

  void seleccionarDuracion(int minutos) {
    if (state.procesando || state.ventanaAbierta) return;
    emit(state.copyWith(duracionMinutos: minutos));
  }

  Future<void> abrirVentana() async {
    final sesion = state.sesion;
    if (sesion == null || state.procesando) return;
    emit(state.copyWith(procesando: true));
    try {
      final ventana = await _grupal.abrirVentana(sesion.id,
          duracionMinutos: state.duracionMinutos);
      if (isClosed) return;
      final cierre = ventana.cierraEn;
      emit(state.copyWith(ventana: ventana, procesando: false).conAviso(
            cierre == null
                ? '¡Listo! Tus estudiantes ya pueden marcar asistencia.'
                : '¡Listo! Tus estudiantes pueden marcar hasta las ${hora12h(cierre)}.',
          ));
    } catch (e) {
      if (isClosed) return;
      emit(state
          .copyWith(procesando: false)
          .conAviso(mensajeDeError(e), esError: true));
    }
  }

  Future<void> cerrarVentana() async {
    final sesion = state.sesion;
    if (sesion == null || state.procesando) return;
    emit(state.copyWith(procesando: true));
    try {
      final ventana = await _grupal.cerrarVentana(sesion.id);
      if (isClosed) return;
      emit(state
          .copyWith(ventana: ventana, procesando: false)
          .conAviso('Cerraste el marcaje para estudiantes.'));
    } catch (e) {
      if (isClosed) return;
      emit(state
          .copyWith(procesando: false)
          .conAviso(mensajeDeError(e), esError: true));
    }
  }

  /// La cuenta regresiva llegó a cero: la ventana ya no admite marcajes.
  void ventanaVencida() {
    if (!state.ventana.abierta) return;
    emit(state.copyWith(
      ventana: VentanaEstudiantil(
        abierta: false,
        abiertaEn: state.ventana.abiertaEn,
        cierraEn: state.ventana.cierraEn,
      ),
    ));
  }
}
