import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/models/importacion_model.dart';
import '../../domain/academico_repository.dart';

// ─── Events ───
abstract class ImportacionEvent extends Equatable {
  const ImportacionEvent();
  @override
  List<Object?> get props => [];
}

class PreviewImportarCsvEvent extends ImportacionEvent {
  final List<int> bytes;
  final String filename;

  const PreviewImportarCsvEvent({required this.bytes, required this.filename});

  @override
  List<Object?> get props => [bytes, filename];
}

class ConfirmarImportarCsvEvent extends ImportacionEvent {
  final List<Map<String, dynamic>> filas;
  const ConfirmarImportarCsvEvent(this.filas);

  @override
  List<Object?> get props => [filas];
}

class ClearImportacionEvent extends ImportacionEvent {
  const ClearImportacionEvent();
}

// ─── States ───
abstract class ImportacionState extends Equatable {
  const ImportacionState();
  @override
  List<Object?> get props => [];
}

class ImportacionInitial extends ImportacionState {
  const ImportacionInitial();
}

class ImportacionLoading extends ImportacionState {
  final String message;
  const ImportacionLoading({this.message = 'Procesando archivo CSV...'});

  @override
  List<Object?> get props => [message];
}

class ImportacionPreviewLoaded extends ImportacionState {
  final PreviewImportacionModel preview;
  const ImportacionPreviewLoaded(this.preview);

  @override
  List<Object?> get props => [preview];
}

class ImportacionSuccess extends ImportacionState {
  final String message;
  const ImportacionSuccess(this.message);

  @override
  List<Object?> get props => [message];
}

class ImportacionError extends ImportacionState {
  final String message;
  const ImportacionError(this.message);

  @override
  List<Object?> get props => [message];
}

// ─── BLoC ───
class ImportacionBloc extends Bloc<ImportacionEvent, ImportacionState> {
  final AcademicoRepository _repository;

  ImportacionBloc({required AcademicoRepository repository})
      : _repository = repository,
        super(const ImportacionInitial()) {
    on<PreviewImportarCsvEvent>(_onPreviewCsv);
    on<ConfirmarImportarCsvEvent>(_onConfirmarCsv);
    on<ClearImportacionEvent>((_, emit) => emit(const ImportacionInitial()));
  }

  Future<void> _onPreviewCsv(
    PreviewImportarCsvEvent event,
    Emitter<ImportacionState> emit,
  ) async {
    emit(const ImportacionLoading(message: 'Validando archivo CSV en el servidor...'));
    try {
      final preview = await _repository.previewImportarCsv(
        bytes: event.bytes,
        filename: event.filename,
      );
      emit(ImportacionPreviewLoaded(preview));
    } catch (e) {
      emit(ImportacionError(_cleanError(e)));
    }
  }

  Future<void> _onConfirmarCsv(
    ConfirmarImportarCsvEvent event,
    Emitter<ImportacionState> emit,
  ) async {
    emit(const ImportacionLoading(message: 'Guardando asignaciones en base de datos...'));
    try {
      await _repository.confirmarImportarCsv(filas: event.filas);
      emit(const ImportacionSuccess('¡Importación masiva completada exitosamente!'));
    } catch (e) {
      emit(ImportacionError(_cleanError(e)));
    }
  }

  String _cleanError(dynamic e) {
    return e
        .toString()
        .replaceAll('ApiException: ', '')
        .replaceAll('Exception: ', '');
  }
}
