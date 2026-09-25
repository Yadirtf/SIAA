// marcaje_repository.dart — Implementación del repositorio de marcaje
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:uuid/uuid.dart';
import '../../domain/models/marcaje_historial_model.dart';
import '../../domain/models/marcaje_request_model.dart';
import '../../domain/models/marcaje_result_model.dart';
import '../../domain/models/offline_marcaje_item.dart';
import '../../domain/models/sesion_activa_model.dart';
import '../datasources/marcaje_local_datasource.dart';
import '../datasources/marcaje_remote_datasource.dart';
import '../services/device_integrity_service.dart';
import '../services/location_service.dart';

class MarcajeRepository {
  final MarcajeRemoteDataSource _remoteDataSource;
  final MarcajeLocalDataSource _localDataSource;
  final LocationService _locationService;
  final DeviceIntegridadService _integrityService;
  final Connectivity _connectivity;
  final Uuid _uuid;

  MarcajeRepository({
    MarcajeRemoteDataSource? remoteDataSource,
    MarcajeLocalDataSource? localDataSource,
    LocationService? locationService,
    DeviceIntegridadService? integrityService,
    Connectivity? connectivity,
    Uuid? uuid,
  })  : _remoteDataSource = remoteDataSource ?? MarcajeRemoteDataSource(),
        _localDataSource = localDataSource ?? MarcajeLocalDataSource(),
        _locationService = locationService ?? LocationService(),
        _integrityService = integrityService ?? DeviceIntegridadService(),
        _connectivity = connectivity ?? Connectivity(),
        _uuid = uuid ?? const Uuid();

  Future<SesionActivaModel?> obtenerSesionActiva() {
    return _remoteDataSource.obtenerSesionActiva();
  }

  Future<LocationResult> capturarUbicacion() {
    return _locationService.capturarUbicacionPuntual();
  }

  Future<bool> hayConexion() async {
    final status = await _connectivity.checkConnectivity();
    return !status.contains(ConnectivityResult.none);
  }

  Future<MarcajeResultModel> realizarMarcaje({
    required String sesionId,
    required String tipo,
    required LocationResult location,
  }) async {
    final metaEIntegridad = await _integrityService.obtenerMetadatosEIntegridad(
      mockLocation: location.isMocked,
    );

    final meta = metaEIntegridad['metadata'];
    final integridad = metaEIntegridad['integridad'] as IntegridadDeviceModel;

    final request = MarcajeRequestModel(
      sesionId: sesionId,
      tipo: tipo,
      latitud: location.latitud,
      longitud: location.longitud,
      precisionMetros: location.precisionMetros,
      timestampDispositivo: location.timestamp,
      dispositivoId: meta.instalacionId,
      modeloDispositivo: meta.modelo,
      soDispositivo: meta.so,
      versionApp: meta.versionApp,
      integridad: integridad,
      idempotencyKey: _uuid.v4(),
    );

    final online = await hayConexion();
    if (!online) {
      // Guardar en cola offline (US-MAR-11)
      await _localDataSource.encolarMarcaje(request);
      return const MarcajeResultModel(
        resultado: 'PENDIENTE_SINCRONIZACION',
        mensaje: 'Sin conexión a internet. El marcaje ha sido cifrado y guardado en cola local; se sincronizará automáticamente al restablecerse la red.',
        permiteReintento: false,
        puedeJustificar: false,
      );
    }

    try {
      return await _remoteDataSource.enviarMarcaje(request);
    } catch (e) {
      // Si falló por red durante la petición, encolar offline
      await _localDataSource.encolarMarcaje(request);
      return const MarcajeResultModel(
        resultado: 'PENDIENTE_SINCRONIZACION',
        mensaje: 'Fallo temporal de conexión. Su marcaje fue almacenado localmente y será enviado tan pronto haya red disponible.',
        permiteReintento: false,
        puedeJustificar: false,
      );
    }
  }

  Future<List<OfflineMarcajeItem>> obtenerColaOffline() {
    return _localDataSource.obtenerPendientes();
  }

  Future<int> sincronizarMarcajesOffline() async {
    final online = await hayConexion();
    if (!online) return 0;

    final pendientes = await _localDataSource.obtenerPendientes();
    if (pendientes.isEmpty) return 0;

    int sincronizados = 0;
    // Enviar individualmente o en lote para tolerancia a fallos aislados (US-MAR-11 AC-03)
    for (final item in pendientes) {
      try {
        final res = await _remoteDataSource.enviarMarcaje(item.request);
        await _localDataSource.actualizarItem(
          item.copyWith(
            estado: EstadoSincronizacion.sincronizado,
            resultadoServidor: res,
          ),
        );
        sincronizados++;
      } catch (e) {
        await _localDataSource.actualizarItem(
          item.copyWith(
            estado: EstadoSincronizacion.fallido,
            errorMensaje: e.toString(),
          ),
        );
      }
    }
    return sincronizados;
  }

  Future<HistorialPaginadoModel> consultarHistorial({String? mes, int pagina = 1}) {
    return _remoteDataSource.consultarHistorial(mes: mes, pagina: pagina);
  }

  Future<DateTime> abrirVentanaEstudiantil(String sesionId, {int duracionMinutos = 5}) {
    return _remoteDataSource.abrirVentanaEstudiantil(sesionId, duracionMinutos: duracionMinutos);
  }

  Future<void> registrarListaManual({
    required String sesionId,
    required String motivo,
    required List<Map<String, dynamic>> estudiantes,
  }) {
    return _remoteDataSource.registrarListaManual(
      sesionId: sesionId,
      motivo: motivo,
      estudiantes: estudiantes,
    );
  }
}
