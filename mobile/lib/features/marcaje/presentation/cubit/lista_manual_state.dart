// lista_manual_state.dart — Estado del pase de lista manual del docente (US-MAR-14)
import 'package:equatable/equatable.dart';

import '../../domain/models/lista_manual_model.dart';

enum CargaListaManual { cargando, lista, error }

class ListaManualState extends Equatable {
  final CargaListaManual carga;
  final List<EstudianteListaManual> estudiantes;

  /// Asistencia marcada por el docente para las filas no bloqueadas.
  final Map<String, bool> presentes;
  final String motivo;
  final bool enviando;
  final ResultadoListaManual? resultado;

  /// Error de carga (pantalla completa) o de envío (mensaje bajo el formulario).
  final String? error;

  /// El usuario intentó enviar sin motivo.
  final bool motivoFaltante;

  const ListaManualState({
    this.carga = CargaListaManual.cargando,
    this.estudiantes = const [],
    this.presentes = const {},
    this.motivo = '',
    this.enviando = false,
    this.resultado,
    this.error,
    this.motivoFaltante = false,
  });

  bool presente(String estudianteId) => presentes[estudianteId] ?? false;

  int get editables => estudiantes.where((e) => !e.bloqueado).length;

  int get marcadosPresentes =>
      estudiantes.where((e) => !e.bloqueado && presente(e.id)).length;

  bool get puedeEnviar =>
      carga == CargaListaManual.lista && !enviando && estudiantes.isNotEmpty;

  ListaManualState copyWith({
    CargaListaManual? carga,
    List<EstudianteListaManual>? estudiantes,
    Map<String, bool>? presentes,
    String? motivo,
    bool? enviando,
    ResultadoListaManual? resultado,
    String? error,
    bool? motivoFaltante,
  }) {
    return ListaManualState(
      carga: carga ?? this.carga,
      estudiantes: estudiantes ?? this.estudiantes,
      presentes: presentes ?? this.presentes,
      motivo: motivo ?? this.motivo,
      enviando: enviando ?? this.enviando,
      resultado: resultado ?? this.resultado,
      error: error,
      motivoFaltante: motivoFaltante ?? this.motivoFaltante,
    );
  }

  @override
  List<Object?> get props => [
        carga,
        estudiantes,
        presentes,
        motivo,
        enviando,
        resultado,
        error,
        motivoFaltante,
      ];
}
