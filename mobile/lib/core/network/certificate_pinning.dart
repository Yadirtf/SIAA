// Package network — Fijación de certificado (certificate pinning) para HTTPS.
// Satisface US-SEG-01 AC-02, US-PLT-03 AC-06 y RNF-SEG-001.
// Los pines NO viven en el código: llegan en la compilación con
//   --dart-define=SIAA_CERT_PINS=<pin1>,<pin2>
// donde cada pin es el SHA-256 en Base64 del SubjectPublicKeyInfo (formato HPKP "pin-sha256").
// Ver mobile/docs/certificate-pinning.md para calcularlos con openssl.
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';

import 'spki_extractor.dart';

/// Configuración de pinning: pines SPKI aceptados y hosts a los que aplican.
class CertificatePinningConfig {
  /// Pines SHA-256 (Base64) válidos: el activo y al menos uno de respaldo para rotar sin caída.
  final List<String> pinesSpki;

  /// Entradas de SIAA_CERT_PINS que no son un SHA-256 en Base64 (error de compilación).
  final List<String> pinesInvalidos;

  /// Hosts protegidos (el host de API_BASE_URL). Cualquier otro host se rechaza.
  final List<String> hosts;

  const CertificatePinningConfig({
    required this.pinesSpki,
    required this.hosts,
    this.pinesInvalidos = const [],
  });

  /// Valor crudo de --dart-define=SIAA_CERT_PINS (vacío si no se definió).
  static const pinesDefinidos = String.fromEnvironment('SIAA_CERT_PINS');

  /// Construye la configuración desde los dart-define y la URL base de la API.
  factory CertificatePinningConfig.desdeEntorno({
    required String baseUrl,
    String pines = pinesDefinidos,
  }) {
    final validos = <String>[];
    final invalidos = <String>[];
    for (final pin in pines.split(',')) {
      final limpio = normalizarPin(pin);
      if (limpio.isEmpty) continue;
      (esPinValido(limpio) ? validos : invalidos).add(limpio);
    }
    final host = Uri.tryParse(baseUrl)?.host ?? '';
    return CertificatePinningConfig(
      pinesSpki: validos,
      pinesInvalidos: invalidos,
      hosts: [if (host.isNotEmpty) host.toLowerCase()],
    );
  }

  bool get tienePines => pinesSpki.isNotEmpty;

  /// Quita espacios y el prefijo opcional "sha256/" (formato de OkHttp).
  static String normalizarPin(String pin) {
    final limpio = pin.trim();
    return limpio.startsWith('sha256/') ? limpio.substring(7) : limpio;
  }

  /// Un pin válido es Base64 de exactamente 32 bytes (SHA-256).
  static bool esPinValido(String pin) {
    try {
      return base64.decode(pin).length == 32;
    } on FormatException {
      return false;
    }
  }
}

/// Validador de pinning: compara el SHA-256 del SPKI del certificado hoja con los pines.
class CertificatePinningValidator {
  final CertificatePinningConfig config;

  const CertificatePinningValidator(this.config);

  /// Pin SHA-256 (Base64) del SPKI de un certificado DER, o null si no se pudo leer.
  static String? pinDe(List<int> der) {
    final spki = SpkiExtractor.extraer(der);
    return spki == null ? null : base64.encode(sha256.convert(spki).bytes);
  }

  /// true solo si el host está protegido y la clave pública coincide con algún pin.
  /// Un certificado nulo (p. ej. HTTP sin TLS) o desconocido se rechaza (anti-MITM).
  bool validate(X509Certificate? cert, String host, int port) {
    if (cert == null || !config.tienePines) return false;
    if (!config.hosts.contains(host.toLowerCase())) return false;
    final pin = pinDe(cert.der);
    return pin != null && config.pinesSpki.contains(pin);
  }
}
