import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/download/guardar_archivo.dart';
import '../../../../core/network/api_exception.dart';
import '../../data/models/importacion_model.dart';
import '../../domain/importacion_repository.dart';

// ─── Events ───
abstract class ImportacionEvent extends Equatable {
  const ImportacionEvent();
  @override
  List<Object?> get props => [];
}

/// Archivo CSV o XLSX elegido: se valida en el servidor sin persistir.
class PreviewImportarCsvEvent extends ImportacionEvent {
  final List<int> bytes;
  final String filename;

  const PreviewImportarCsvEvent({required this.bytes, required this.filename});

  @override
  List<Object?> get props => [filename, bytes.length];
}

/// Aplica el archivo validado (el servidor lo revalida completo).
class ConfirmarImportarCsvEvent extends ImportacionEvent {
  const ConfirmarImportarCsvEvent();
}

/// Descarga el archivo con la columna de diagnóstico por fila.
class DescargarDiagnosticoEvent extends ImportacionEvent {
  const DescargarDiagnosticoEvent();
}

/// Descarga la plantilla publicada (`csv` o `xlsx`).
class DescargarPlantillaEvent extends ImportacionEvent {
  final String formato;
  const DescargarPlantillaEvent(this.formato);
  @override
  List<Object?> get props => [formato];
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
  const ImportacionLoading({this.message = 'Procesando archivo...'});

  @override
  List<Object?> get props => [message];
}

class ImportacionPreviewLoaded extends ImportacionState {
  final PreviewImportacionModel preview;
  final String nombreArchivo;

  /// Mensaje del último intento de aplicar que no se aplicó (sobre el umbral).
  final String? aviso;

  const ImportacionPreviewLoaded(
    this.preview, {
    this.nombreArchivo = '',
    this.aviso,
  });

  @override
  List<Object?> get props => [preview, nombreArchivo, aviso];
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
  final ImportacionRepository _repository;
  final GuardarArchivo _guardar;
  List<int>? _bytes;
  String _nombre = '';

  ImportacionBloc({
    required ImportacionRepository repository,
    GuardarArchivo guardar = guardarEnNavegador,
  }) : _repository = repository,
       _guardar = guardar,
       super(const ImportacionInitial()) {
    on<PreviewImportarCsvEvent>(_onPreview);
    on<ConfirmarImportarCsvEvent>(_onConfirmar);
    on<DescargarDiagnosticoEvent>(_onDiagnostico);
    on<DescargarPlantillaEvent>(_onPlantilla);
    on<ClearImportacionEvent>((_, emit) {
      _bytes = null;
      emit(const ImportacionInitial());
    });
  }

  Future<void> _onPreview(
    PreviewImportarCsvEvent event,
    Emitter<ImportacionState> emit,
  ) async {
    _bytes = event.bytes;
    _nombre = event.filename;
    emit(
      const ImportacionLoading(message: 'Validando archivo en el servidor...'),
    );
    try {
      final preview = await _repository.preview(event.bytes, event.filename);
      emit(ImportacionPreviewLoaded(preview, nombreArchivo: _nombre));
    } catch (e) {
      emit(ImportacionError(_mensaje(e)));
    }
  }

  Future<void> _onConfirmar(
    ConfirmarImportarCsvEvent event,
    Emitter<ImportacionState> emit,
  ) async {
    final bytes = _bytes;
    if (bytes == null) return;
    emit(const ImportacionLoading(message: 'Aplicando la carga...'));
    try {
      final r = await _repository.confirmar(bytes, _nombre);
      if (r.aplicada) {
        emit(ImportacionSuccess(r.mensaje));
      } else if (r.informe != null) {
        emit(
          ImportacionPreviewLoaded(
            r.informe!,
            nombreArchivo: _nombre,
            aviso: r.mensaje,
          ),
        );
      } else {
        emit(ImportacionError(r.mensaje));
      }
    } catch (e) {
      emit(ImportacionError(_mensaje(e)));
    }
  }

  Future<void> _onDiagnostico(
    DescargarDiagnosticoEvent event,
    Emitter<ImportacionState> emit,
  ) async {
    final bytes = _bytes;
    if (bytes == null) return;
    try {
      final archivo = await _repository.diagnostico(bytes, _nombre);
      _guardar(archivo, 'diagnostico-$_nombre');
    } catch (e) {
      emit(ImportacionError(_mensaje(e)));
    }
  }

  Future<void> _onPlantilla(
    DescargarPlantillaEvent event,
    Emitter<ImportacionState> emit,
  ) async {
    try {
      final archivo = await _repository.plantilla(event.formato);
      _guardar(archivo, 'plantilla-carga-academica.${event.formato}');
    } catch (e) {
      emit(ImportacionError(_mensaje(e)));
    }
  }

  String _mensaje(Object e) => e is ApiException
      ? e.message
      : e.toString().replaceAll('Exception: ', '');
}
