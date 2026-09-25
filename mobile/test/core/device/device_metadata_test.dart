import 'package:flutter_test/flutter_test.dart';
import 'package:siaa_mobile/core/device/device_metadata.dart';

void main() {
  group('DeviceMetadata (US-AUT-03)', () {
    test('crea instancia y serializa a Map para POST /auth/devices', () {
      const meta = DeviceMetadata(
        instalacionId: 'uuid-1234-5678',
        modelo: 'Pixel 7',
        so: 'Android 14',
        versionApp: '1.2.0+15',
      );

      expect(meta.instalacionId, 'uuid-1234-5678');
      expect(meta.modelo, 'Pixel 7');
      expect(meta.so, 'Android 14');
      expect(meta.versionApp, '1.2.0+15');

      final json = meta.toJson();
      expect(json['instalacionId'], 'uuid-1234-5678');
      expect(json['modelo'], 'Pixel 7');
      expect(json['so'], 'Android 14');
      expect(json['versionApp'], '1.2.0+15');
    });

    test('soporta comparación por igualdad mediante Equatable', () {
      const meta1 = DeviceMetadata(
        instalacionId: 'id-1',
        modelo: 'iPhone 15',
        so: 'iOS 17.4',
        versionApp: '1.0.0',
      );
      const meta2 = DeviceMetadata(
        instalacionId: 'id-1',
        modelo: 'iPhone 15',
        so: 'iOS 17.4',
        versionApp: '1.0.0',
      );

      expect(meta1, equals(meta2));
    });
  });
}
