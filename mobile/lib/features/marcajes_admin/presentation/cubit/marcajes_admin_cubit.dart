// marcajes_admin_cubit.dart — Consulta paginada, filtros y ajustes de marcajes (US-MAR-09)
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/network/api_error.dart';
import '../../data/marcajes_admin_remote_datasource.dart';
import '../../domain/filtro_marcajes.dart';
import 'marcajes_admin_state.dart';

class MarcajesAdminCubit extends Cubit<MarcajesAdminState> {
  final MarcajesAdminRemoteDataSource _remote;

  MarcajesAdminCubit({MarcajesAdminRemoteDataSource? remote})
      : _remote = remote ?? MarcajesAdminRemoteDataSource(),
        super(const MarcajesAdminState());

  Future<void> cargar([FiltroMarcajes? filtro]) async {
    final f = (filtro ?? state.filtro).copyWith(pagina: 1);
    emit(state.copyWith(estado: EstadoMarcajesAdmin.cargando, filtro: f));
    try {
      final pagina = await _remote.listar(f);
      emit(state.copyWith(
        estado: EstadoMarcajesAdmin.listo,
        items: pagina.items,
        total: pagina.total,
        hayMas: pagina.hayMas,
      ));
    } catch (e) {
      emit(state.copyWith(
        estado: EstadoMarcajesAdmin.error,
        error: mensajeDeError(e,
            porDefecto: 'No se pudieron cargar los marcajes.'),
      ));
    }
  }

  Future<void> cargarMas() async {
    if (!state.hayMas || state.cargandoMas) return;
    final f = state.filtro.copyWith(pagina: state.filtro.pagina + 1);
    emit(state.copyWith(cargandoMas: true));
    try {
      final pagina = await _remote.listar(f);
      emit(state.copyWith(
        filtro: f,
        items: [...state.items, ...pagina.items],
        hayMas: pagina.hayMas,
        cargandoMas: false,
      ));
    } catch (e) {
      emit(state.copyWith(cargandoMas: false, error: mensajeDeError(e)));
    }
  }

  void filtrarResultado(String? resultado) => cargar(resultado == null
      ? state.filtro.copyWith(limpiarResultado: true)
      : state.filtro.copyWith(resultado: resultado));

  void filtrarFechas(DateTime? desde, DateTime? hasta) => cargar(desde == null
      ? state.filtro.copyWith(limpiarFechas: true)
      : state.filtro.copyWith(desde: desde, hasta: hasta));

  /// Aplica el ajuste y recarga. Devuelve null si tuvo éxito o el mensaje de error.
  Future<String?> ajustar(String marcajeId, AjusteMarcaje ajuste) async {
    if (ajuste.motivo.trim().length < AjusteMarcaje.minMotivo) {
      return 'El motivo debe tener al menos ${AjusteMarcaje.minMotivo} caracteres.';
    }
    try {
      await _remote.ajustar(marcajeId, ajuste);
      await cargar();
      return null;
    } catch (e) {
      return mensajeDeError(e, porDefecto: 'No se pudo aplicar el ajuste.');
    }
  }
}
