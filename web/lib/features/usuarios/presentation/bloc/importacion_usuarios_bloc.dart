import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/models/importacion_usuarios_model.dart';
import '../../domain/usuarios_repository.dart';
import 'usuarios_bloc.dart';

// ─── Events ───
abstract class ImportacionUsuariosEvent extends Equatable {
  const ImportacionUsuariosEvent();
  @override
  List<Object?> get props => [];
}

/// Valida el CSV sin crear usuarios (confirmar=false).
class PrevisualizarImportacionUsuariosEvent extends ImportacionUsuariosEvent {
  final String csv;
  const PrevisualizarImportacionUsuariosEvent(this.csv);
  @override
  List<Object?> get props => [csv];
}

/// Crea los usuarios válidos del CSV previamente validado (confirmar=true).
class ConfirmarImportacionUsuariosEvent extends ImportacionUsuariosEvent {
  const ConfirmarImportacionUsuariosEvent();
}

class ReiniciarImportacionUsuariosEvent extends ImportacionUsuariosEvent {
  const ReiniciarImportacionUsuariosEvent();
}

// ─── State ───
enum ImportacionUsuariosPaso { inicial, validando, previa, creando, completada }

class ImportacionUsuariosState extends Equatable {
  final ImportacionUsuariosPaso paso;
  final String csv;
  final ImportacionUsuariosModel? resultado;
  final String? error;

  const ImportacionUsuariosState({
    this.paso = ImportacionUsuariosPaso.inicial,
    this.csv = '',
    this.resultado,
    this.error,
  });

  bool get ocupado =>
      paso == ImportacionUsuariosPaso.validando ||
      paso == ImportacionUsuariosPaso.creando;

  @override
  List<Object?> get props => [paso, csv, resultado, error];
}

// ─── BLoC ───
class ImportacionUsuariosBloc
    extends Bloc<ImportacionUsuariosEvent, ImportacionUsuariosState> {
  final UsuariosRepository _repository;

  ImportacionUsuariosBloc({required UsuariosRepository repository})
    : _repository = repository,
      super(const ImportacionUsuariosState()) {
    on<PrevisualizarImportacionUsuariosEvent>(_onPrevisualizar);
    on<ConfirmarImportacionUsuariosEvent>(_onConfirmar);
    on<ReiniciarImportacionUsuariosEvent>(
      (e, emit) => emit(const ImportacionUsuariosState()),
    );
  }

  Future<void> _onPrevisualizar(
    PrevisualizarImportacionUsuariosEvent e,
    Emitter<ImportacionUsuariosState> emit,
  ) async {
    emit(
      ImportacionUsuariosState(
        paso: ImportacionUsuariosPaso.validando,
        csv: e.csv,
      ),
    );
    try {
      final r = await _repository.importarCsv(e.csv, confirmar: false);
      emit(
        ImportacionUsuariosState(
          paso: ImportacionUsuariosPaso.previa,
          csv: e.csv,
          resultado: r,
        ),
      );
    } catch (err) {
      emit(
        ImportacionUsuariosState(
          csv: e.csv,
          error: UsuariosBloc.mensajeDe(err),
        ),
      );
    }
  }

  Future<void> _onConfirmar(
    ConfirmarImportacionUsuariosEvent e,
    Emitter<ImportacionUsuariosState> emit,
  ) async {
    final previa = state;
    if (previa.paso != ImportacionUsuariosPaso.previa) return;
    emit(
      ImportacionUsuariosState(
        paso: ImportacionUsuariosPaso.creando,
        csv: previa.csv,
        resultado: previa.resultado,
      ),
    );
    try {
      final r = await _repository.importarCsv(previa.csv, confirmar: true);
      emit(
        ImportacionUsuariosState(
          paso: ImportacionUsuariosPaso.completada,
          csv: previa.csv,
          resultado: r,
        ),
      );
    } catch (err) {
      emit(
        ImportacionUsuariosState(
          paso: ImportacionUsuariosPaso.previa,
          csv: previa.csv,
          resultado: previa.resultado,
          error: UsuariosBloc.mensajeDe(err),
        ),
      );
    }
  }
}
