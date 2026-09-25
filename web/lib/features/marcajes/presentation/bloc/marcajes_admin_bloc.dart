// marcajes_admin_bloc.dart — BLoC para consola web administrativa de marcajes
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/models/marcaje_admin_model.dart';
import '../../domain/repositories/marcajes_admin_repository.dart';
import 'marcajes_admin_event.dart';
import 'marcajes_admin_state.dart';

class MarcajesAdminBloc extends Bloc<MarcajesAdminEvent, MarcajesAdminState> {
  final MarcajesAdminRepository _repository;
  FiltrosMarcajeAdmin _ultimosFiltros = const FiltrosMarcajeAdmin();
  int _ultimaPagina = 1;

  MarcajesAdminBloc({required MarcajesAdminRepository repository})
      : _repository = repository,
        super(MarcajesAdminInitial()) {
    on<CargarMarcajesAdminEvent>(_onCargarMarcajes);
    on<AjustarMarcajeEvent>(_onAjustarMarcaje);
    on<CrearMarcajeManualEvent>(_onCrearMarcajeManual);
  }

  Future<void> _onCargarMarcajes(
    CargarMarcajesAdminEvent event,
    Emitter<MarcajesAdminState> emit,
  ) async {
    emit(MarcajesAdminLoading());
    _ultimosFiltros = event.filtros;
    _ultimaPagina = event.pagina;

    try {
      final page = await _repository.listarMarcajes(
        filtros: event.filtros,
        pagina: event.pagina,
        limite: event.limite,
      );
      emit(MarcajesAdminLoaded(page: page, filtros: event.filtros));
    } catch (e) {
      emit(MarcajesAdminFailure('Error al cargar marcajes: ${e.toString()}'));
    }
  }

  Future<void> _onAjustarMarcaje(
    AjustarMarcajeEvent event,
    Emitter<MarcajesAdminState> emit,
  ) async {
    if (event.motivo.trim().length < 20) {
      emit(const MarcajesAdminFailure('El motivo de ajuste debe contener al menos 20 caracteres'));
      return;
    }

    emit(MarcajesAdminLoading());
    try {
      final marcaje = await _repository.ajustarMarcaje(
        marcajeId: event.marcajeId,
        accion: event.accion,
        nuevoResultado: event.nuevoResultado,
        anulado: event.anulado,
        motivo: event.motivo,
      );

      emit(MarcajesAdminActionSuccess(
        mensaje: 'Ajuste administrativo registrado con éxito en auditoría',
        marcaje: marcaje,
      ));

      // Recargar lista manteniendo filtros actuales
      add(CargarMarcajesAdminEvent(filtros: _ultimosFiltros, pagina: _ultimaPagina));
    } catch (e) {
      emit(MarcajesAdminFailure('Error al aplicar ajuste: ${e.toString()}'));
    }
  }

  Future<void> _onCrearMarcajeManual(
    CrearMarcajeManualEvent event,
    Emitter<MarcajesAdminState> emit,
  ) async {
    if (event.motivo.trim().length < 20) {
      emit(const MarcajesAdminFailure('El motivo debe contener al menos 20 caracteres para trazabilidad'));
      return;
    }

    emit(MarcajesAdminLoading());
    try {
      final marcaje = await _repository.crearMarcajeManual(
        sesionId: event.sesionId,
        usuarioId: event.usuarioId,
        tipo: event.tipo,
        resultado: event.resultado,
        motivo: event.motivo,
      );

      emit(MarcajesAdminActionSuccess(
        mensaje: 'Marcaje manual de respaldo creado y auditado exitosamente',
        marcaje: marcaje,
      ));

      add(CargarMarcajesAdminEvent(filtros: _ultimosFiltros, pagina: _ultimaPagina));
    } catch (e) {
      emit(MarcajesAdminFailure('Error al registrar marcaje manual: ${e.toString()}'));
    }
  }
}
