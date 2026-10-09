import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/network/mensaje_error.dart';
import '../../data/generacion_sesiones_remote_datasource.dart';
import '../../data/models/informe_generacion_model.dart';
import '../../data/models/trabajo_model.dart';

enum FaseGeneracion { inactiva, enCurso, completada, fallida }

class GeneracionSesionesState extends Equatable {
  final FaseGeneracion fase;
  final int progreso;
  final InformeGeneracionModel? informe;
  final String? error;

  const GeneracionSesionesState({
    this.fase = FaseGeneracion.inactiva,
    this.progreso = 0,
    this.informe,
    this.error,
  });

  bool get enCurso => fase == FaseGeneracion.enCurso;

  @override
  List<Object?> get props => [fase, progreso, informe, error];
}

/// Genera las sesiones de un periodo en segundo plano (US-ACA-05 AC-04): el
/// servidor responde 202 con un trabajo y aquí se consulta su estado cada
/// [intervalo] hasta que termina, sin bloquear la consola.
class GeneracionSesionesCubit extends Cubit<GeneracionSesionesState> {
  final GeneracionSesionesRemoteDataSource _ds;
  final Duration intervalo;

  /// Tiempo máximo de espera; el servidor corta la generación a los 10 min.
  final Duration limite;

  GeneracionSesionesCubit({
    required GeneracionSesionesRemoteDataSource dataSource,
    this.intervalo = const Duration(seconds: 2),
    this.limite = const Duration(minutes: 11),
  }) : _ds = dataSource,
       super(const GeneracionSesionesState());

  Future<void> generar(String periodoId, {bool incluirPasadas = false}) async {
    if (state.enCurso) return;
    emit(const GeneracionSesionesState(fase: FaseGeneracion.enCurso));
    try {
      var trabajo = await _ds.iniciarGeneracion(
        periodoId,
        incluirPasadas: incluirPasadas,
      );
      final inicio = DateTime.now();
      while (!trabajo.terminado) {
        if (DateTime.now().difference(inicio) > limite) {
          return _fallar(
            'La generación sigue en curso. Consulte las sesiones más tarde.',
          );
        }
        await Future<void>.delayed(intervalo);
        if (isClosed) return;
        trabajo = await _ds.consultarTrabajo(trabajo.id);
        if (isClosed) return;
        emit(
          GeneracionSesionesState(
            fase: FaseGeneracion.enCurso,
            progreso: trabajo.progreso,
          ),
        );
      }
      _terminar(trabajo);
    } catch (e) {
      if (!isClosed) _fallar(mensajeDeError(e));
    }
  }

  void _terminar(TrabajoModel trabajo) {
    if (trabajo.estado == TrabajoModel.fallido) {
      return _fallar(
        trabajo.error.isEmpty ? 'La generación falló.' : trabajo.error,
      );
    }
    emit(
      GeneracionSesionesState(
        fase: FaseGeneracion.completada,
        progreso: 100,
        informe: InformeGeneracionModel.fromJson(trabajo.resultado ?? {}),
      ),
    );
  }

  void _fallar(String mensaje) => emit(
    GeneracionSesionesState(fase: FaseGeneracion.fallida, error: mensaje),
  );
}
