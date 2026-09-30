// marcajes_admin_event.dart — Eventos de administración de marcajes
import 'package:equatable/equatable.dart';
import '../../domain/models/marcaje_admin_model.dart';

abstract class MarcajesAdminEvent extends Equatable {
  const MarcajesAdminEvent();

  @override
  List<Object?> get props => [];
}

class CargarMarcajesAdminEvent extends MarcajesAdminEvent {
  final FiltrosMarcajeAdmin filtros;
  final int pagina;
  final int limite;

  const CargarMarcajesAdminEvent({
    this.filtros = const FiltrosMarcajeAdmin(),
    this.pagina = 1,
    this.limite = 20,
  });

  @override
  List<Object?> get props => [filtros, pagina, limite];
}

class AjustarMarcajeEvent extends MarcajesAdminEvent {
  final String marcajeId;
  final String accion; // ANULAR | AJUSTAR
  final String? nuevoResultado;
  final bool anulado;
  final String motivo; // Mínimo 20 caracteres

  const AjustarMarcajeEvent({
    required this.marcajeId,
    required this.accion,
    this.nuevoResultado,
    required this.anulado,
    required this.motivo,
  });

  @override
  List<Object?> get props => [marcajeId, accion, nuevoResultado, anulado, motivo];
}

class CrearMarcajeManualEvent extends MarcajesAdminEvent {
  final String sesionId;
  final String usuarioId;
  final String tipo;
  final String resultado;
  final String motivo;

  const CrearMarcajeManualEvent({
    required this.sesionId,
    required this.usuarioId,
    required this.tipo,
    required this.resultado,
    required this.motivo,
  });

  @override
  List<Object?> get props => [sesionId, usuarioId, tipo, resultado, motivo];
}
