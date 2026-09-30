import 'package:equatable/equatable.dart';

import '../../../../core/models/pagina.dart';
import '../../data/models/entrada_auditoria_model.dart';
import '../../data/models/filtro_auditoria_model.dart';

enum AuditoriaStatus { inicial, cargando, cargado, error }

class AuditoriaState extends Equatable {
  final AuditoriaStatus status;
  final FiltroAuditoriaModel filtro;
  final Pagina<EntradaAuditoriaModel>? pagina;
  final String? error;

  /// Formato en exportación (`xlsx`/`pdf`), o null.
  final String? exportando;
  final String? mensajeExito;
  final String? mensajeError;

  const AuditoriaState({
    this.status = AuditoriaStatus.inicial,
    this.filtro = const FiltroAuditoriaModel(),
    this.pagina,
    this.error,
    this.exportando,
    this.mensajeExito,
    this.mensajeError,
  });

  AuditoriaState copyWith({
    AuditoriaStatus? status,
    FiltroAuditoriaModel? filtro,
    Pagina<EntradaAuditoriaModel>? pagina,
    String? error,
    String? Function()? exportando,
    String? mensajeExito,
    String? mensajeError,
  }) {
    return AuditoriaState(
      status: status ?? this.status,
      filtro: filtro ?? this.filtro,
      pagina: pagina ?? this.pagina,
      error: error,
      exportando: exportando != null ? exportando() : this.exportando,
      mensajeExito: mensajeExito,
      mensajeError: mensajeError,
    );
  }

  @override
  List<Object?> get props => [
    status,
    filtro,
    pagina,
    error,
    exportando,
    mensajeExito,
    mensajeError,
  ];
}
