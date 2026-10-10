// cartografia_sync_service.dart — Envía al backend las capturas offline (US-GEO-10 AC-02..AC-04)
// Por cada captura pendiente:
//  1. GET /espacios/:id: si versionGeometria superó la versión con la que se capturó,
//     alguien modificó el espacio entretanto → conflicto; NO se sobrescribe (AC-04).
//  2. PUT /espacios/:id/geometria con las mismas validaciones que el guardado en línea.
//     Un rechazo del servidor deja la captura para corrección, sin perder vértices (AC-03).
// El backend aún no ofrece precondición de versión en el PUT (If-Match); la comprobación
// previa reduce, pero no elimina, la ventana de carrera entre el GET y el PUT.
import 'dart:async';

import '../../../core/geo/offline_cartografia_service.dart';
import 'espacio_repository.dart';

class CartografiaSyncService {
  final OfflineCartografiaService _cola;
  final EspacioRepository _repositorio;
  final _resultados = StreamController<ResultadoSincronizacion>.broadcast();

  CartografiaSyncService({
    OfflineCartografiaService? cola,
    EspacioRepository? repositorio,
  })  : _cola = cola ?? OfflineCartografiaService.instancia,
        _repositorio = repositorio ?? EspacioRepository();

  /// Resultado de cada sincronización que procesó al menos una captura.
  Stream<ResultadoSincronizacion> get resultados => _resultados.stream;

  Future<ResultadoSincronizacion> sincronizar() async {
    final r = await _cola.sincronizarPendientes(
      isOnline: true,
      syncHandler: enviar,
    );
    if (r.procesados > 0 && !_resultados.isClosed) _resultados.add(r);
    return r;
  }

  Future<EnvioCaptura> enviar(CapturaOfflineEspacio captura) async {
    try {
      final actual = await _repositorio.obtenerEspacioPorId(captura.espacioId);
      if (actual.versionGeometria > captura.versionEsperada) {
        return EnvioCaptura(ResultadoEnvioCaptura.conflicto,
            versionServidor: actual.versionGeometria);
      }
      await _repositorio.guardarGeometria(
        espacioId: captura.espacioId,
        coordenadas: captura.vertices,
        metodoCaptura: captura.metodoCaptura,
        precisionPromedioMetros: captura.precisionPromedioMetros,
        versionEsperada: actual.versionGeometria,
      );
      return const EnvioCaptura(ResultadoEnvioCaptura.aceptada);
    } on ConflictoVersionGeometriaException {
      // Otro cambio llegó entre la lectura y el guardado (US-GEO-10 AC-04).
      final vigente = await _repositorio.obtenerEspacioPorId(captura.espacioId);
      return EnvioCaptura(ResultadoEnvioCaptura.conflicto,
          versionServidor: vigente.versionGeometria);
    } on SinConexionGeometriaException {
      return const EnvioCaptura(ResultadoEnvioCaptura.sinConexion);
    } on SolapamientoAdvertenciaException catch (e) {
      return EnvioCaptura(ResultadoEnvioCaptura.rechazada,
          mensaje:
              '${e.mensaje} Ábrala en el editor para confirmar el solapamiento.');
    } catch (e) {
      final texto = e.toString();
      return EnvioCaptura(ResultadoEnvioCaptura.rechazada,
          mensaje:
              texto.startsWith('Exception: ') ? texto.substring(11) : texto);
    }
  }
}
