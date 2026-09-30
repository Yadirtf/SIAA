// marcajes_admin_state.dart — Estados del BLoC administrativo de marcajes
import 'package:equatable/equatable.dart';
import '../../domain/models/marcaje_admin_model.dart';

abstract class MarcajesAdminState extends Equatable {
  const MarcajesAdminState();

  @override
  List<Object?> get props => [];
}

class MarcajesAdminInitial extends MarcajesAdminState {}

class MarcajesAdminLoading extends MarcajesAdminState {}

class MarcajesAdminLoaded extends MarcajesAdminState {
  final MarcajeAdminPageModel page;
  final FiltrosMarcajeAdmin filtros;

  const MarcajesAdminLoaded({
    required this.page,
    this.filtros = const FiltrosMarcajeAdmin(),
  });

  @override
  List<Object?> get props => [page, filtros];
}

class MarcajesAdminActionSuccess extends MarcajesAdminState {
  final String mensaje;
  final MarcajeAdminModel marcaje;

  const MarcajesAdminActionSuccess({
    required this.mensaje,
    required this.marcaje,
  });

  @override
  List<Object?> get props => [mensaje, marcaje];
}

class MarcajesAdminFailure extends MarcajesAdminState {
  final String error;

  const MarcajesAdminFailure(this.error);

  @override
  List<Object?> get props => [error];
}
