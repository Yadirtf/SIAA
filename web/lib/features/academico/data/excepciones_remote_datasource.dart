import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import 'models/academico_models.dart';

/// Resultado de crear una excepción: sesiones ya generadas que canceló (US-ACA-04 AC-03).
class ExcepcionCreada {
  final ExcepcionModel excepcion;
  final int sesionesCanceladas;

  const ExcepcionCreada(this.excepcion, this.sesionesCanceladas);
}

/// Fechas que quedan libres al eliminar una excepción (AC-04): se ofrece
/// regenerar las sesiones de [periodoIds], sin hacerlo automáticamente.
class FechasLiberadas {
  final int sesionesReactivables;
  final List<String> periodoIds;
  final String mensaje;

  const FechasLiberadas({
    required this.sesionesReactivables,
    required this.periodoIds,
    required this.mensaje,
  });

  factory FechasLiberadas.fromJson(Map<String, dynamic> json) =>
      FechasLiberadas(
        sesionesReactivables:
            (json['sesionesReactivables'] as num?)?.toInt() ?? 0,
        periodoIds: (json['periodoIds'] as List? ?? const [])
            .map((e) => e.toString())
            .toList(),
        mensaje: json['mensaje']?.toString() ?? '',
      );
}

/// Calendario de excepciones (US-ACA-04): crear con ámbito y eliminar.
class ExcepcionesRemoteDataSource {
  final ApiClient _client;

  ExcepcionesRemoteDataSource({ApiClient? client})
    : _client = client ?? ApiClient();

  Future<ExcepcionCreada> crear({
    required String nombre,
    required String tipo,
    required String ambito,
    String? ambitoId,
    required String fechaInicio,
    required String fechaFin,
  }) async {
    final r = await _client.post(
      ApiConstants.excepciones,
      body: {
        'nombre': nombre,
        'tipo': tipo,
        'ambito': ambito,
        if (ambitoId != null && ambitoId.isNotEmpty) 'ambitoId': ambitoId,
        'fechaInicio': fechaInicio,
        'fechaFin': fechaFin,
      },
    ) as Map<String, dynamic>;
    return ExcepcionCreada(
      ExcepcionModel.fromJson(r),
      (r['sesionesCanceladas'] as num?)?.toInt() ?? 0,
    );
  }

  Future<FechasLiberadas> eliminar(String id) async {
    final r = await _client.delete('${ApiConstants.excepciones}/$id');
    return r is Map<String, dynamic>
        ? FechasLiberadas.fromJson(r)
        : const FechasLiberadas(
            sesionesReactivables: 0,
            periodoIds: [],
            mensaje: 'Excepción eliminada.',
          );
  }
}
