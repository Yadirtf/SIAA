// captura_offline_espacio.dart — Geometría capturada sin conexión (US-GEO-10, RF-GEO-013)

enum EstadoSincronizacion {
  pendienteSincronizacion,
  sincronizado,
  errorValidacion,
  conflicto,
}

class CapturaOfflineEspacio {
  final String id;
  final String espacioId;
  final String espacioCodigo;
  final String espacioNombre;
  final List<List<double>> vertices; // Coordenadas [longitud, latitud]
  final String metodoCaptura;
  final double? precisionPromedioMetros;
  final DateTime capturadoEn;

  /// versionGeometria del espacio cuando se abrió el editor; si el servidor tiene
  /// una mayor al sincronizar, alguien lo modificó entretanto (AC-04).
  int versionEsperada;
  EstadoSincronizacion estado;
  String? mensajeError;

  /// Versión encontrada en el servidor al detectar el conflicto.
  int? versionServidor;

  CapturaOfflineEspacio({
    required this.id,
    required this.espacioId,
    this.espacioCodigo = '',
    this.espacioNombre = '',
    required this.vertices,
    required this.metodoCaptura,
    this.precisionPromedioMetros,
    required this.capturadoEn,
    this.versionEsperada = 1,
    this.estado = EstadoSincronizacion.pendienteSincronizacion,
    this.mensajeError,
    this.versionServidor,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'espacioId': espacioId,
      'espacioCodigo': espacioCodigo,
      'espacioNombre': espacioNombre,
      'vertices': vertices,
      'metodoCaptura': metodoCaptura,
      'precisionPromedioMetros': precisionPromedioMetros,
      'capturadoEn': capturadoEn.toIso8601String(),
      'versionEsperada': versionEsperada,
      'estado': estado.name,
      'mensajeError': mensajeError,
      'versionServidor': versionServidor,
    };
  }

  factory CapturaOfflineEspacio.fromJson(Map<String, dynamic> json) {
    return CapturaOfflineEspacio(
      id: json['id'] as String,
      espacioId: json['espacioId'] as String,
      espacioCodigo: json['espacioCodigo'] as String? ?? '',
      espacioNombre: json['espacioNombre'] as String? ?? '',
      vertices: (json['vertices'] as List<dynamic>)
          .map((v) =>
              (v as List<dynamic>).map((c) => (c as num).toDouble()).toList())
          .toList(),
      metodoCaptura: json['metodoCaptura'] as String,
      precisionPromedioMetros:
          (json['precisionPromedioMetros'] as num?)?.toDouble(),
      capturadoEn: DateTime.parse(json['capturadoEn'] as String),
      versionEsperada: (json['versionEsperada'] as num?)?.toInt() ?? 1,
      estado: EstadoSincronizacion.values.firstWhere(
        (e) => e.name == json['estado'],
        orElse: () => EstadoSincronizacion.pendienteSincronizacion,
      ),
      mensajeError: json['mensajeError'] as String?,
      versionServidor: (json['versionServidor'] as num?)?.toInt(),
    );
  }
}

/// Resultado del envío de una captura al servidor.
enum ResultadoEnvioCaptura { aceptada, conflicto, rechazada, sinConexion }

/// Lo que devuelve el manejador de envío para cada captura.
class EnvioCaptura {
  final ResultadoEnvioCaptura resultado;
  final String? mensaje;
  final int? versionServidor;

  const EnvioCaptura(this.resultado, {this.mensaje, this.versionServidor});
}

class ResultadoSincronizacion {
  final int sincronizados;
  final int erroresValidacion;
  final int conflictos;
  final List<CapturaOfflineEspacio> pendientesRestantes;

  ResultadoSincronizacion({
    required this.sincronizados,
    required this.erroresValidacion,
    required this.conflictos,
    required this.pendientesRestantes,
  });

  int get procesados => sincronizados + erroresValidacion + conflictos;

  /// Texto para el usuario con el resultado de la sincronización (AC-02).
  String get resumen {
    final partes = [
      if (sincronizados > 0) '$sincronizados sincronizada(s)',
      if (erroresValidacion > 0)
        '$erroresValidacion rechazada(s) por validación',
      if (conflictos > 0) '$conflictos en conflicto',
    ];
    return 'Cartografía sin conexión: ${partes.join(', ')}.';
  }
}
