import 'package:equatable/equatable.dart';
import '../../../geo_editor/data/espacio_repository.dart';

class HomeState extends Equatable {
  final List<SedeModel> sedes;
  final SedeModel? sedeSeleccionada;
  final bool cargandoSedes;

  final List<BloqueModel> bloques;
  final BloqueModel? bloqueSeleccionado;
  final bool cargandoBloques;

  final List<EspacioModel> espacios;
  final bool cargandoEspacios;

  final String? errorMessage;
  final String? successMessage;
  final EspacioModel? ultimoEspacioCreado;

  const HomeState({
    this.sedes = const [],
    this.sedeSeleccionada,
    this.cargandoSedes = false,
    this.bloques = const [],
    this.bloqueSeleccionado,
    this.cargandoBloques = false,
    this.espacios = const [],
    this.cargandoEspacios = false,
    this.errorMessage,
    this.successMessage,
    this.ultimoEspacioCreado,
  });

  HomeState copyWith({
    List<SedeModel>? sedes,
    SedeModel? sedeSeleccionada,
    bool clearSedeSeleccionada = false,
    bool? cargandoSedes,
    List<BloqueModel>? bloques,
    BloqueModel? bloqueSeleccionado,
    bool clearBloqueSeleccionado = false,
    bool? cargandoBloques,
    List<EspacioModel>? espacios,
    bool? cargandoEspacios,
    String? errorMessage,
    String? successMessage,
    EspacioModel? ultimoEspacioCreado,
    bool clearError = false,
    bool clearSuccess = false,
    bool clearUltimoEspacio = false,
  }) {
    return HomeState(
      sedes: sedes ?? this.sedes,
      sedeSeleccionada: clearSedeSeleccionada
          ? null
          : (sedeSeleccionada ?? this.sedeSeleccionada),
      cargandoSedes: cargandoSedes ?? this.cargandoSedes,
      bloques: bloques ?? this.bloques,
      bloqueSeleccionado: clearBloqueSeleccionado
          ? null
          : (bloqueSeleccionado ?? this.bloqueSeleccionado),
      cargandoBloques: cargandoBloques ?? this.cargandoBloques,
      espacios: espacios ?? this.espacios,
      cargandoEspacios: cargandoEspacios ?? this.cargandoEspacios,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      successMessage: clearSuccess ? null : (successMessage ?? this.successMessage),
      ultimoEspacioCreado: clearUltimoEspacio
          ? null
          : (ultimoEspacioCreado ?? this.ultimoEspacioCreado),
    );
  }

  @override
  List<Object?> get props => [
        sedes,
        sedeSeleccionada,
        cargandoSedes,
        bloques,
        bloqueSeleccionado,
        cargandoBloques,
        espacios,
        cargandoEspacios,
        errorMessage,
        successMessage,
        ultimoEspacioCreado,
      ];
}
