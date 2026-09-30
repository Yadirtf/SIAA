// marcaje_repository.dart — Implementación del repositorio de marcaje
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:uuid/uuid.dart';
import '../../domain/models/marcaje_historial_model.dart';
import '../../domain/models/marcaje_request_model.dart';
import '../../domain/models/marcaje_result_model.dart';
import '../../domain/models/offline_marcaje_item.dart';
import '../../domain/models/resumen_sincronizacion.dart';
import '../../domain/models/sesion_activa_model.dart';
import '../../domain/models/verificacion_complementaria_model.dart';
import '../datasources/marcaje_local_datasource.dart';
import '../datasources/marcaje_remote_datasource.dart';
import '../services/attestation_service.dart';
import '../services/device_integrity_service.dart';
import '../services/location_service.dart';
import '../services/marcaje_sync_service.dart';
import '../services/politica_reintentos.dart';

class MarcajeRepository {
  final MarcajeRemoteDataSource _remoteDataSource;
  final MarcajeLocalDataSource _localDataSource;
  final LocationService _locationService;
  final DeviceIntegridadService _integrityService;
  final AttestationService _attestation;
  final MarcajeSyncService? _syncServiceInyectado;
  late final MarcajeSyncService _syncService = _syncServiceInyectado ??
      MarcajeSyncService(
        remote: _remoteDataSource,
        local: _localDataSource,
        attestation: _attestation,
      );
  final Connectivity _connectivity;
  final Uuid _uuid;

  MarcajeRepository({
    MarcajeRemoteDataSource? remoteDataSource,
    MarcajeLocalDataSource? localDataSource,
    LocationService? locationService,
    DeviceIntegridadService? integrityService,
    AttestationService? attestationService,
    MarcajeSyncService? syncService,
    Connectivity? connectivity,
    Uuid? uuid,
  })  : _remoteDataSource = remoteDataSource ?? MarcajeRemoteDataSource(),
        _localDataSource = localDataSource ?? MarcajeLocalDataSource(),
        _locationService = locationService ?? LocationService(),
        _integrityService = integrityService ?? DeviceIntegridadService(),
        _attestation = attestationService ?? AttestationService(),
        _connectivity = connectivity ?? Connectivity(),
        _uuid = uuid ?? const Uuid(),
        _syncServiceInyectado = syncService;

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
    VerificacionComplementariaModel? verificacion,
    bool exigirAttestation = false,
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
      verificacionComplementaria: verificacion,
      idempotencyKey: _uuid.v4(),
    );

    final online = await hayConexion();
    if (!online) {
      // Guardar en cola offline (US-MAR-11); el token de attestation se pide al sincronizar.
      await _encolar(request, exigirAttestation);
      return const MarcajeResultModel(
        resultado: 'PENDIENTE_SINCRONIZACION',
        mensaje:
            'Sin conexión a internet. El marcaje ha sido cifrado y guardado en cola local; se sincronizará automáticamente al restablecerse la red.',
        permiteReintento: false,
        puedeJustificar: false,
      );
    }

    try {
      final conToken = exigirAttestation
          ? request.conIntegridad(request.integridad.conToken(
              await _attestation.obtenerToken(
                sesionId: sesionId,
                tipo: tipo,
                idempotencyKey: request.idempotencyKey,
              ),
            ))
          : request;
      return await _remoteDataSource.enviarMarcaje(conToken);
    } catch (e) {
      // Si falló por red durante la petición, encolar offline
      await _encolar(request, exigirAttestation);
      return const MarcajeResultModel(
        resultado: 'PENDIENTE_SINCRONIZACION',
        mensaje:
            'Fallo temporal de conexión. Su marcaje fue almacenado localmente y será enviado tan pronto haya red disponible.',
        permiteReintento: false,
        puedeJustificar: false,
      );
    }
  }

  Future<void> _encolar(
      MarcajeRequestModel request, bool exigirAttestation) async {
    await _localDataSource.encolarMarcaje(
      request,
      exigirAttestation: exigirAttestation,
    );
    MarcajeSyncService.notificarCambio();
  }

  /// Todos los items de la cola local (pendientes, rechazados, fallidos y aceptados recientes).
  Future<List<OfflineMarcajeItem>> obtenerColaOffline() {
    return _localDataSource.obtenerTodos();
  }

  /// Sincroniza la cola por lotes vía POST /marcajes/sync (nunca dos veces en paralelo).
  Future<ResumenSincronizacion> sincronizarMarcajesOffline() async {
    final online = await hayConexion();
    if (!online) return ResumenSincronizacion.vacio;
    return _syncService.sincronizar();
  }

  /// Reintento manual de un item fallido: vuelve a la cola con el contador reiniciado.
  Future<void> reintentarMarcajeOffline(String localId) async {
    final todos = await _localDataSource.obtenerTodos();
    final idx = todos.indexWhere((it) => it.localId == localId);
    if (idx == -1) return;
    await _localDataSource
        .actualizarItem(const PoliticaReintentos().reiniciar(todos[idx]));
  }

  Future<HistorialPaginadoModel> consultarHistorial(
      {String? mes, int pagina = 1}) {
    return _remoteDataSource.consultarHistorial(mes: mes, pagina: pagina);
  }

  Future<DateTime> abrirVentanaEstudiantil(String sesionId,
      {int duracionMinutos = 5}) {
    return _remoteDataSource.abrirVentanaEstudiantil(sesionId,
        duracionMinutos: duracionMinutos);
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
