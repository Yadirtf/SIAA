// device_integrity_service.dart — Detección de integridad y metadatos de dispositivo (US-MAR-10)
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../../../../core/device/device_info_service.dart';
import '../../../../core/device/device_metadata.dart';
import '../../domain/models/marcaje_request_model.dart';

class DeviceIntegridadService {
  final DeviceInfoService _deviceInfoService;

  DeviceIntegridadService({DeviceInfoService? deviceInfoService})
      : _deviceInfoService = deviceInfoService ?? const DeviceInfoService();

  /// Obtiene los metadatos completos y genera las banderas de integridad
  Future<Map<String, dynamic>> obtenerMetadatosEIntegridad({
    bool mockLocation = false,
  }) async {
    final meta = await _deviceInfoService.getMetadata();

    bool esEmulador = false;
    bool esRooteado = false;

    if (!kIsWeb) {
      if (Platform.isAndroid) {
        final modeloLower = meta.modelo.toLowerCase();
        if (modeloLower.contains('sdk') ||
            modeloLower.contains('emulator') ||
            modeloLower.contains('google_sdk') ||
            modeloLower.contains('genymotion')) {
          esEmulador = true;
        }
        // Verificación básica de binarios su
        try {
          final res = await File('/system/app/Superuser.apk').exists();
          final suRes = await File('/system/bin/su').exists();
          esRooteado = res || suRes;
        } catch (_) {}
      } else if (Platform.isIOS) {
        final modeloLower = meta.modelo.toLowerCase();
        if (modeloLower.contains('simulator')) {
          esEmulador = true;
        }
      }
    }

    final integridad = IntegridadDeviceModel(
      mockLocation: mockLocation,
      rooteado: esRooteado,
      emulador: esEmulador,
      attestationOk: true,
    );

    return {
      'metadata': meta,
      'integridad': integridad,
    };
  }
}
