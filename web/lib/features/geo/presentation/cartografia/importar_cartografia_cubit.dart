import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/network/mensaje_error.dart';
import '../../data/cartografia_remote_datasource.dart';
import '../../data/models/preview_cartografia_model.dart';

enum PasoImportacionCartografia {
  inicial,
  analizando,
  previa,
  confirmando,
  completada,
}

class ImportarCartografiaState extends Equatable {
  final PasoImportacionCartografia paso;
  final String? archivo;
  final PreviewCartografiaModel? previa;
  final ResultadoImportacionCartografia? resultado;
  final String? error;

  const ImportarCartografiaState({
    this.paso = PasoImportacionCartografia.inicial,
    this.archivo,
    this.previa,
    this.resultado,
    this.error,
  });

  bool get puedeConfirmar =>
      paso == PasoImportacionCartografia.previa && (previa?.validos ?? 0) > 0;

  @override
  List<Object?> get props => [paso, archivo, previa, resultado, error];
}

/// Asistente de importación GeoJSON/KML (US-GEO-11): previsualiza con los
/// errores por elemento y luego confirma; el backend revalida todo.
class ImportarCartografiaCubit extends Cubit<ImportarCartografiaState> {
  final CartografiaRemoteDataSource _ds;

  ImportarCartografiaCubit({CartografiaRemoteDataSource? dataSource})
    : _ds = dataSource ?? CartografiaRemoteDataSource(),
      super(const ImportarCartografiaState());

  Future<void> previsualizar(List<int> bytes, String nombreArchivo) async {
    emit(
      ImportarCartografiaState(
        paso: PasoImportacionCartografia.analizando,
        archivo: nombreArchivo,
      ),
    );
    try {
      final previa = await _ds.previsualizar(
        bytes: bytes,
        nombreArchivo: nombreArchivo,
      );
      emit(
        ImportarCartografiaState(
          paso: PasoImportacionCartografia.previa,
          archivo: nombreArchivo,
          previa: previa,
        ),
      );
    } catch (e) {
      emit(
        ImportarCartografiaState(
          archivo: nombreArchivo,
          error: mensajeDeError(e),
        ),
      );
    }
  }

  Future<void> confirmar({
    required String sedeId,
    String? bloqueId,
    int? piso,
  }) async {
    final previa = state.previa;
    if (!state.puedeConfirmar || previa == null) return;
    emit(
      ImportarCartografiaState(
        paso: PasoImportacionCartografia.confirmando,
        archivo: state.archivo,
        previa: previa,
      ),
    );
    try {
      final r = await _ds.confirmar(
        sedeId: sedeId,
        bloqueId: bloqueId,
        piso: piso,
        elementos: previa.elementos
            .where((e) => e.valido)
            .map((e) => e.crudo)
            .toList(),
      );
      emit(
        ImportarCartografiaState(
          paso: PasoImportacionCartografia.completada,
          archivo: state.archivo,
          previa: previa,
          resultado: r,
        ),
      );
    } catch (e) {
      emit(
        ImportarCartografiaState(
          paso: PasoImportacionCartografia.previa,
          archivo: state.archivo,
          previa: previa,
          error: mensajeDeError(e),
        ),
      );
    }
  }
}
