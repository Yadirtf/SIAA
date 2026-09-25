// Servicio de información del dispositivo — US-AUT-03
// Obtiene el identificador de instalación seguro y la información de la plataforma.
// RF-AUT-004, T-AUT-03.2.
import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../storage/secure_storage.dart';
import 'device_metadata.dart';

class DeviceInfoService {
  final DeviceInfoPlugin? _deviceInfo;

  const DeviceInfoService({DeviceInfoPlugin? deviceInfo})
      : _deviceInfo = deviceInfo;

  /// Obtiene los metadatos completos requeridos para POST /auth/devices
  Future<DeviceMetadata> getMetadata() async {
    final instalacionId = await SecureStorage.getOrCreateInstalacionId();
    String modelo = 'Dispositivo Móvil';
    String so = 'SO Móvil';
    String versionApp = '1.0.0';

    try {
      final pkg = await PackageInfo.fromPlatform();
      versionApp = '${pkg.version}+${pkg.buildNumber}';
    } catch (_) {}

    try {
      final info = _deviceInfo ?? DeviceInfoPlugin();
      if (!kIsWeb) {
        if (Platform.isAndroid) {
          final android = await info.androidInfo;
          modelo = '${android.manufacturer} ${android.model}';
          so =
              'Android ${android.version.release} (SDK ${android.version.sdkInt})';
        } else if (Platform.isIOS) {
          final ios = await info.iosInfo;
          modelo = ios.name.isNotEmpty ? ios.name : ios.model;
          so = 'iOS ${ios.systemVersion}';
        } else {
          modelo = Platform.operatingSystemVersion;
          so = Platform.operatingSystem;
        }
      } else {
        final web = await info.webBrowserInfo;
        modelo = web.browserName.name;
        so = web.platform ?? 'Web';
      }
    } catch (_) {
      modelo = 'Simulador';
      so = 'Flutter Test Env';
    }

    return DeviceMetadata(
      instalacionId: instalacionId,
      modelo: modelo,
      so: so,
      versionApp: versionApp,
    );
  }
}
