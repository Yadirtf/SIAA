// marcaje_grupal_state.dart — Estado del control de marcaje estudiantil del docente (US-MAR-13)
import 'package:equatable/equatable.dart';

import '../../domain/models/sesion_activa_model.dart';
import '../../domain/models/ventana_estudiantil_model.dart';

enum CargaGrupal { cargando, lista, sinSesion, error }

class MarcajeGrupalState extends Equatable {
  /// Duraciones que el docente puede elegir para la ventana (minutos).
  static const duraciones = [5, 10, 15];

  final CargaGrupal carga;
  final SesionActivaModel? sesion;
  final VentanaEstudiantil ventana;
  final int duracionMinutos;

  /// Hay una petición de abrir/cerrar en curso.
  final bool procesando;

  /// Error de carga de la sesión (pantalla completa).
  final String? error;

  /// Mensaje puntual para un SnackBar; [avisoId] cambia en cada aviso nuevo.
  final String? aviso;
  final bool avisoEsError;
  final int avisoId;

  const MarcajeGrupalState({
    this.carga = CargaGrupal.cargando,
    this.sesion,
    this.ventana = VentanaEstudiantil.cerrada,
    this.duracionMinutos = 5,
    this.procesando = false,
    this.error,
    this.aviso,
    this.avisoEsError = false,
    this.avisoId = 0,
  });

  /// Hora actual según el servidor (corrige un reloj del celular mal puesto).
  DateTime get ahora => sesion?.ahoraServidor() ?? DateTime.now();

  bool get ventanaAbierta => ventana.vigenteEn(ahora);

  MarcajeGrupalState copyWith({
    CargaGrupal? carga,
    SesionActivaModel? sesion,
    VentanaEstudiantil? ventana,
    int? duracionMinutos,
    bool? procesando,
    String? error,
  }) {
    return MarcajeGrupalState(
      carga: carga ?? this.carga,
      sesion: sesion ?? this.sesion,
      ventana: ventana ?? this.ventana,
      duracionMinutos: duracionMinutos ?? this.duracionMinutos,
      procesando: procesando ?? this.procesando,
      error: error,
      aviso: aviso,
      avisoEsError: avisoEsError,
      avisoId: avisoId,
    );
  }

  MarcajeGrupalState conAviso(String mensaje, {bool esError = false}) {
    return MarcajeGrupalState(
      carga: carga,
      sesion: sesion,
      ventana: ventana,
      duracionMinutos: duracionMinutos,
      procesando: procesando,
      error: error,
      aviso: mensaje,
      avisoEsError: esError,
      avisoId: avisoId + 1,
    );
  }

  @override
  List<Object?> get props => [
        carga,
        sesion,
        ventana,
        duracionMinutos,
        procesando,
        error,
        aviso,
        avisoEsError,
        avisoId,
      ];
}
