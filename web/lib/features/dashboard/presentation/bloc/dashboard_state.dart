import 'package:equatable/equatable.dart';
import '../../data/admin_geo_repository.dart';

enum DashboardStatus { initial, loading, success, failure }

class DashboardState extends Equatable {
  final DashboardStatus status;
  final List<AdminSede> sedes;
  final List<AdminBloque> bloques;
  final List<AdminEspacio> espacios;
  final int selectedNavIndex;
  final String? errorMessage;
  final String? successMessage;

  const DashboardState({
    this.status = DashboardStatus.initial,
    this.sedes = const [],
    this.bloques = const [],
    this.espacios = const [],
    this.selectedNavIndex = 0,
    this.errorMessage,
    this.successMessage,
  });

  int get delimitadosCount => espacios.where((e) => e.tieneGeometria).length;
  int get pendientesCount => espacios.length - delimitadosCount;

  DashboardState copyWith({
    DashboardStatus? status,
    List<AdminSede>? sedes,
    List<AdminBloque>? bloques,
    List<AdminEspacio>? espacios,
    int? selectedNavIndex,
    String? errorMessage,
    String? successMessage,
    bool clearErrors = false,
  }) {
    return DashboardState(
      status: status ?? this.status,
      sedes: sedes ?? this.sedes,
      bloques: bloques ?? this.bloques,
      espacios: espacios ?? this.espacios,
      selectedNavIndex: selectedNavIndex ?? this.selectedNavIndex,
      errorMessage: clearErrors ? null : (errorMessage ?? this.errorMessage),
      successMessage: clearErrors ? null : (successMessage ?? this.successMessage),
    );
  }

  @override
  List<Object?> get props => [
        status,
        sedes,
        bloques,
        espacios,
        selectedNavIndex,
        errorMessage,
        successMessage,
      ];
}
