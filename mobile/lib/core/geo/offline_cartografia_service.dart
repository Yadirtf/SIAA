// Servicio de almacenamiento y sincronización offline de cartografía.
// Satisface US-GEO-10 (AC-01..AC-04) y RF-GEO-013.

enum EstadoSincronizacion {
  pendienteSincronizacion,
  sincronizado,
  errorValidacion,
  conflicto,
}

class CapturaOfflineEspacio {
  final String id;
  final String espacioId;
  final List<List<double>> vertices; // Coordenadas [longitud, latitud]
  final String metodoCaptura;
  final double? precisionPromedioMetros;
  final DateTime capturadoEn;
  final int versionEsperada;
  EstadoSincronizacion estado;
  String? mensajeError;

  CapturaOfflineEspacio({
    required this.id,
    required this.espacioId,
    required this.vertices,
    required this.metodoCaptura,
    this.precisionPromedioMetros,
    required this.capturadoEn,
    this.versionEsperada = 1,
    this.estado = EstadoSincronizacion.pendienteSincronizacion,
    this.mensajeError,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'espacioId': espacioId,
      'vertices': vertices,
      'metodoCaptura': metodoCaptura,
      'precisionPromedioMetros': precisionPromedioMetros,
      'capturadoEn': capturadoEn.toIso8601String(),
      'versionEsperada': versionEsperada,
      'estado': estado.name,
      'mensajeError': mensajeError,
    };
  }

  factory CapturaOfflineEspacio.fromJson(Map<String, dynamic> json) {
    return CapturaOfflineEspacio(
      id: json['id'] as String,
      espacioId: json['espacioId'] as String,
      vertices: (json['vertices'] as List<dynamic>)
          .map((v) => (v as List<dynamic>).map((c) => (c as num).toDouble()).toList())
          .toList(),
      metodoCaptura: json['metodoCaptura'] as String,
      precisionPromedioMetros: (json['precisionPromedioMetros'] as num?)?.toDouble(),
      capturadoEn: DateTime.parse(json['capturadoEn'] as String),
      versionEsperada: (json['versionEsperada'] as num?)?.toInt() ?? 1,
      estado: EstadoSincronizacion.values.firstWhere(
        (e) => e.name == json['estado'],
        orElse: () => EstadoSincronizacion.pendienteSincronizacion,
      ),
      mensajeError: json['mensajeError'] as String?,
    );
  }
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
}

class OfflineCartografiaService {
  final Map<String, CapturaOfflineEspacio> _storage = {};

  // AC-01: Guarda la geometría localmente con estado PENDIENTE_SINCRONIZACION
  Future<void> guardarCapturaOffline(CapturaOfflineEspacio captura) async {
    captura.estado = EstadoSincronizacion.pendienteSincronizacion;
    _storage[captura.id] = captura;
  }

  Future<List<CapturaOfflineEspacio>> obtenerTodas() async {
    return _storage.values.toList();
  }

  Future<List<CapturaOfflineEspacio>> obtenerPendientes() async {
    return _storage.values
        .where((c) => c.estado == EstadoSincronizacion.pendienteSincronizacion)
        .toList();
  }

  Future<CapturaOfflineEspacio?> obtenerPorId(String id) async {
    return _storage[id];
  }

  // AC-02, AC-03, AC-04: Sincroniza automáticamente las geometrías pendientes cuando hay conexión
  Future<ResultadoSincronizacion> sincronizarPendientes({
    required bool isOnline,
    required Future<int> Function(CapturaOfflineEspacio captura) syncHandler,
  }) async {
    if (!isOnline) {
      final pendientes = await obtenerPendientes();
      return ResultadoSincronizacion(
        sincronizados: 0,
        erroresValidacion: 0,
        conflictos: 0,
        pendientesRestantes: pendientes,
      );
    }

    int sincOk = 0;
    int errVal = 0;
    int conf = 0;

    final lista = await obtenerPendientes();
    for (final captura in lista) {
      try {
        final serverVersion = await syncHandler(captura);
        if (serverVersion > captura.versionEsperada) {
          // AC-04: Conflicto detectado (espacio fue modificado en el servidor)
          captura.estado = EstadoSincronizacion.conflicto;
          captura.mensajeError = 'Conflicto: el espacio ya tiene una versión superior ($serverVersion) en el servidor';
          conf++;
        } else {
          // Sincronización exitosa
          captura.estado = EstadoSincronizacion.sincronizado;
          captura.mensajeError = null;
          sincOk++;
        }
      } catch (e) {
        // AC-03: Error de validación del servidor: se conserva localmente sin pérdida de vértices
        captura.estado = EstadoSincronizacion.errorValidacion;
        captura.mensajeError = e.toString();
        errVal++;
      }
    }

    final restantes = _storage.values
        .where((c) => c.estado != EstadoSincronizacion.sincronizado)
        .toList();

    return ResultadoSincronizacion(
      sincronizados: sincOk,
      erroresValidacion: errVal,
      conflictos: conf,
      pendientesRestantes: restantes,
    );
  }
}
