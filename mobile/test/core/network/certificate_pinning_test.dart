// Pruebas unitarias de Certificate Pinning.
// Satisface US-PLT-03, AC-06 y RNF-SEG-001.
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:siaa_mobile/core/network/certificate_pinning.dart';

class _FakeX509Certificate implements X509Certificate {
  @override
  final Uint8List der;

  _FakeX509Certificate(this.der);

  @override
  DateTime get end => DateTime.now().add(const Duration(days: 365));

  @override
  DateTime get endValidity => end;

  @override
  DateTime get start => DateTime.now().subtract(const Duration(days: 1));

  @override
  DateTime get startValidity => start;

  @override
  String get pem => '-----BEGIN CERTIFICATE-----\nMIID...\n-----END CERTIFICATE-----';

  @override
  String get issuer => 'CN=SIAA Root CA';

  @override
  Uint8List get sha1 => Uint8List(20);

  @override
  String get subject => 'CN=api.siaa.edu.co';
}

void main() {
  group('CertificatePinningValidator (US-PLT-03 AC-06)', () {
    late Uint8List certBytesPrimary;
    late String primaryFingerprint;
    late Uint8List certBytesBackup;
    late String backupFingerprint;
    late Uint8List certBytesUntrusted;

    setUp(() {
      certBytesPrimary = Uint8List.fromList(utf8.encode('CERTIFICADO_PRIMARIO_PRODUCCION_SIAA'));
      primaryFingerprint = sha256.convert(certBytesPrimary).toString().toUpperCase();

      certBytesBackup = Uint8List.fromList(utf8.encode('CERTIFICADO_RESPALDO_ROTACION_SIAA'));
      backupFingerprint = sha256.convert(certBytesBackup).toString().toUpperCase();

      certBytesUntrusted = Uint8List.fromList(utf8.encode('CERTIFICADO_FALSO_MAN_IN_THE_MIDDLE'));
    });

    test('acepta certificado cuando su fingerprint coincide con el pin primario', () {
      final config = CertificatePinningConfig(
        pinnedFingerprints: [primaryFingerprint, backupFingerprint],
        allowedHosts: ['api.siaa.edu.co'],
      );
      final validator = CertificatePinningValidator(config: config);

      final cert = _FakeX509Certificate(certBytesPrimary);
      final isValid = validator.validate(cert, 'api.siaa.edu.co', 443);

      expect(isValid, isTrue);
    });

    test('acepta certificado cuando coincide con el pin de respaldo (rotación sin downtime)', () {
      final config = CertificatePinningConfig(
        pinnedFingerprints: [primaryFingerprint, backupFingerprint],
        allowedHosts: ['api.siaa.edu.co'],
      );
      final validator = CertificatePinningValidator(config: config);

      final cert = _FakeX509Certificate(certBytesBackup);
      final isValid = validator.validate(cert, 'api.siaa.edu.co', 443);

      expect(isValid, isTrue);
    });

    test('rechaza certificado cuando el fingerprint no coincide con ningún pin (mitigación MITM)', () {
      final config = CertificatePinningConfig(
        pinnedFingerprints: [primaryFingerprint, backupFingerprint],
        allowedHosts: ['api.siaa.edu.co'],
      );
      final validator = CertificatePinningValidator(config: config);

      final cert = _FakeX509Certificate(certBytesUntrusted);
      final isValid = validator.validate(cert, 'api.siaa.edu.co', 443);

      expect(isValid, isFalse);
    });

    test('rechaza inmediatamente si el certificado es nulo', () {
      final validator = CertificatePinningValidator();
      final isValid = validator.validate(null, 'api.siaa.edu.co', 443);

      expect(isValid, isFalse);
    });

    test('rechaza si el host no está en la lista de hosts permitidos', () {
      final config = CertificatePinningConfig(
        pinnedFingerprints: [primaryFingerprint],
        allowedHosts: ['api.siaa.edu.co'],
      );
      final validator = CertificatePinningValidator(config: config);

      final cert = _FakeX509Certificate(certBytesPrimary);
      final isValid = validator.validate(cert, 'sitio-malicioso.com', 443);

      expect(isValid, isFalse);
    });
  });
}
