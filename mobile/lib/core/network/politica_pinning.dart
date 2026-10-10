// politica_pinning.dart — Decide cómo se aplica la fijación de certificado (US-SEG-01 AC-02)
// - Debug: sin pinning (servidor local con HTTP o certificados autofirmados).
// - Release/profile con pines válidos y API en HTTPS: pinning obligatorio.
// - Release/profile sin pines, con pines mal formados o con API en HTTP: la app NO hace
//   ninguna petición (falla cerrada) y lo informa con un error claro. Es la opción segura:
//   un binario de producción sin pinning quedaría expuesto a MITM sin que nadie lo note.
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'certificate_pinning.dart';

enum ModoPinning { desactivado, aplicado, bloqueado }

class PoliticaPinning {
  final ModoPinning modo;

  /// Explicación del bloqueo (solo en [ModoPinning.bloqueado]).
  final String? motivo;

  const PoliticaPinning._(this.modo, [this.motivo]);

  static PoliticaPinning resolver({
    required bool esDebug,
    required String baseUrl,
    required CertificatePinningConfig config,
  }) {
    if (esDebug) return const PoliticaPinning._(ModoPinning.desactivado);
    if (config.pinesInvalidos.isNotEmpty) {
      return PoliticaPinning._(
        ModoPinning.bloqueado,
        'SIAA_CERT_PINS contiene valores que no son SHA-256 en Base64: '
        '${config.pinesInvalidos.join(', ')}.',
      );
    }
    if (!config.tienePines) {
      return const PoliticaPinning._(
        ModoPinning.bloqueado,
        'Compilación release sin SIAA_CERT_PINS: se bloquean todas las peticiones. '
        'Compile con --dart-define=SIAA_CERT_PINS=<pin_activo>,<pin_respaldo>.',
      );
    }
    if (Uri.tryParse(baseUrl)?.scheme != 'https') {
      return const PoliticaPinning._(
        ModoPinning.bloqueado,
        'API_BASE_URL debe usar https en compilaciones release.',
      );
    }
    return const PoliticaPinning._(ModoPinning.aplicado);
  }
}

/// Rechaza toda petición cuando la política está bloqueada (falla cerrada).
class PinningBloqueoInterceptor extends Interceptor {
  final PoliticaPinning politica;

  PinningBloqueoInterceptor(this.politica) {
    // Aviso ruidoso también en release: queda en el log del dispositivo.
    debugPrint('[SIAA-SEGURIDAD] Pinning bloqueado: ${politica.motivo}');
  }

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    handler.reject(DioException(
      requestOptions: options,
      type: DioExceptionType.badCertificate,
      message: politica.motivo,
      error: StateError(politica.motivo ?? 'Pinning bloqueado'),
    ));
  }
}
