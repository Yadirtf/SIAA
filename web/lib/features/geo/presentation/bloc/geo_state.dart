import 'package:equatable/equatable.dart';
import '../../data/models/geo_models.dart';

abstract class GeoState extends Equatable {
  const GeoState();

  @override
  List<Object?> get props => [];
}

class GeoInitial extends GeoState {
  const GeoInitial();
}

class GeoLoading extends GeoState {
  const GeoLoading();
}

class GeoLoaded extends GeoState {
  final List<SedeModel> sedes;
  final List<BloqueModel> bloques;
  final List<EspacioModel> espacios;
  final List<SolapamientoItemModel> solapamientos;
  final String? selectedSedeId;
  final String? selectedBloqueId;
  final String? actionSuccessMessage;

  const GeoLoaded({
    required this.sedes,
    required this.bloques,
    required this.espacios,
    this.solapamientos = const [],
    this.selectedSedeId,
    this.selectedBloqueId,
    this.actionSuccessMessage,
  });

  GeoLoaded copyWith({
    List<SedeModel>? sedes,
    List<BloqueModel>? bloques,
    List<EspacioModel>? espacios,
    List<SolapamientoItemModel>? solapamientos,
    String? selectedSedeId,
    String? selectedBloqueId,
    String? actionSuccessMessage,
  }) {
    return GeoLoaded(
      sedes: sedes ?? this.sedes,
      bloques: bloques ?? this.bloques,
      espacios: espacios ?? this.espacios,
      solapamientos: solapamientos ?? this.solapamientos,
      selectedSedeId: selectedSedeId ?? this.selectedSedeId,
      selectedBloqueId: selectedBloqueId ?? this.selectedBloqueId,
      actionSuccessMessage: actionSuccessMessage,
    );
  }

  @override
  List<Object?> get props => [
        sedes,
        bloques,
        espacios,
        solapamientos,
        selectedSedeId,
        selectedBloqueId,
        actionSuccessMessage,
      ];
}

class GeoError extends GeoState {
  final String message;

  const GeoError(this.message);

  @override
  List<Object?> get props => [message];
}
