// Pruebas de fijación de certificado con certificados reales (US-SEG-01 AC-02, RNF-SEG-001).
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:siaa_mobile/core/network/api_error.dart';
import 'package:siaa_mobile/core/network/certificate_pinning.dart';
import 'package:siaa_mobile/core/network/politica_pinning.dart';
import 'package:siaa_mobile/core/network/spki_extractor.dart';

import 'certificados_prueba.dart';

/// Solo expone el DER, que es lo único que usa el validador.
class _CertificadoFalso implements X509Certificate {
  @override
  final Uint8List der;

  _CertificadoFalso(this.der);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

const _api = 'https://api.siaa.test/api/v1';

void main() {
  group('SpkiExtractor', () {
    test('calcula el mismo pin que openssl para EC y RSA', () {
      expect(
          CertificatePinningValidator.pinDe(certificadoEc), pinCertificadoEc);
      expect(
          CertificatePinningValidator.pinDe(certificadoRsa), pinCertificadoRsa);
    });

    test('devuelve null ante DER truncado o basura', () {
      expect(SpkiExtractor.extraer(certificadoEc.sublist(0, 40)), isNull);
      expect(SpkiExtractor.extraer([0x02, 0x01, 0x00]), isNull);
      expect(SpkiExtractor.extraer(const []), isNull);
    });
  });

  group('CertificatePinningConfig.desdeEntorno', () {
    test('lee pines separados por coma, admite prefijo sha256/ y toma el host',
        () {
      final config = CertificatePinningConfig.desdeEntorno(
        baseUrl: _api,
        pines: ' sha256/$pinCertificadoEc , $pinCertificadoRsa ,',
      );
      expect(config.pinesSpki, [pinCertificadoEc, pinCertificadoRsa]);
      expect(config.pinesInvalidos, isEmpty);
      expect(config.hosts, ['api.siaa.test']);
    });

    test('separa los pines mal formados (no son SHA-256 en Base64)', () {
      final config = CertificatePinningConfig.desdeEntorno(
        baseUrl: _api,
        pines: 'A1B2C3D4E5F6,$pinCertificadoEc',
      );
      expect(config.pinesSpki, [pinCertificadoEc]);
      expect(config.pinesInvalidos, ['A1B2C3D4E5F6']);
    });

    test('sin dart-define no hay pines (no existen valores de relleno)', () {
      final config = CertificatePinningConfig.desdeEntorno(baseUrl: _api);
      expect(config.tienePines, isFalse);
    });
  });

  group('CertificatePinningValidator', () {
    final validador = CertificatePinningValidator(
      CertificatePinningConfig.desdeEntorno(
          baseUrl: _api, pines: pinCertificadoEc),
    );

    test('acepta el certificado cuya clave pública está fijada', () {
      expect(
        validador.validate(
            _CertificadoFalso(certificadoEc), 'api.siaa.test', 443),
        isTrue,
      );
    });

    test('rechaza un certificado con otra clave (MITM)', () {
      expect(
        validador.validate(
            _CertificadoFalso(certificadoRsa), 'api.siaa.test', 443),
        isFalse,
      );
    });

    test('rechaza certificado nulo y hosts no protegidos', () {
      expect(validador.validate(null, 'api.siaa.test', 443), isFalse);
      expect(
        validador.validate(_CertificadoFalso(certificadoEc), 'otro.com', 443),
        isFalse,
      );
    });
  });

  group('PoliticaPinning', () {
    CertificatePinningConfig config(String pines, [String url = _api]) =>
        CertificatePinningConfig.desdeEntorno(baseUrl: url, pines: pines);

    test('debug: sin pinning aunque no haya pines', () {
      final p = PoliticaPinning.resolver(
          esDebug: true, baseUrl: _api, config: config(''));
      expect(p.modo, ModoPinning.desactivado);
    });

    test('release sin pines: bloquea con motivo explícito', () {
      final p = PoliticaPinning.resolver(
          esDebug: false, baseUrl: _api, config: config(''));
      expect(p.modo, ModoPinning.bloqueado);
      expect(p.motivo, contains('SIAA_CERT_PINS'));
    });

    test('release con pin mal formado o API en HTTP: bloquea', () {
      expect(
        PoliticaPinning.resolver(
                esDebug: false, baseUrl: _api, config: config('xyz'))
            .modo,
        ModoPinning.bloqueado,
      );
      const http = 'http://api.siaa.test/api/v1';
      expect(
        PoliticaPinning.resolver(
                esDebug: false,
                baseUrl: http,
                config: config(pinCertificadoEc, http))
            .modo,
        ModoPinning.bloqueado,
      );
    });

    test('release con pines válidos y HTTPS: aplica pinning', () {
      final p = PoliticaPinning.resolver(
          esDebug: false, baseUrl: _api, config: config(pinCertificadoEc));
      expect(p.modo, ModoPinning.aplicado);
    });

    test('el interceptor de bloqueo rechaza toda petición con error legible',
        () async {
      final politica = PoliticaPinning.resolver(
          esDebug: false, baseUrl: _api, config: config(''));
      final dio = Dio(BaseOptions(baseUrl: _api))
        ..interceptors.add(PinningBloqueoInterceptor(politica));
      try {
        await dio.get('/me/perfil');
        fail('La petición debía rechazarse');
      } on DioException catch (e) {
        expect(e.type, DioExceptionType.badCertificate);
        expect(mensajeDeError(e), contains('identidad del servidor'));
      }
    });
  });
}
