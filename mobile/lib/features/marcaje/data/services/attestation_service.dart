// attestation_service.dart — Tokens de Play Integrity (Standard API) vía canal nativo (US-MAR-10)
// El servidor verifica el token; si no hay token (iOS, sin proyecto configurado o error)
// se envía el marcaje sin él y el servidor decide según su parámetro exigirAttestation.
import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class AttestationService {
  static const canalPorDefecto = MethodChannel('siaa/integridad');

  /// Número de proyecto de Google Cloud vinculado a Play Integrity.
  static const proyectoPorDefecto =
      String.fromEnvironment('PLAY_INTEGRITY_CLOUD_PROJECT');

  final MethodChannel _canal;
  final String _proyectoCloud;
  final bool _plataformaSoportada;

  AttestationService({
    MethodChannel? canal,
    String? proyectoCloud,
    bool? plataformaSoportada,
  })  : _canal = canal ?? canalPorDefecto,
        _proyectoCloud = proyectoCloud ?? proyectoPorDefecto,
        _plataformaSoportada =
            plataformaSoportada ?? (!kIsWeb && Platform.isAndroid);

  /// requestHash que vincula el token al intento: SHA-256 hex (minúsculas) de
  /// "sesionId|TIPO|idempotencyKey", idéntico a HashSolicitud del backend.
  static String hashSolicitud(
    String sesionId,
    String tipo,
    String idempotencyKey,
  ) {
    // El backend trata cualquier tipo distinto de SALIDA como ENTRADA.
    final tipoServidor = tipo == 'SALIDA' ? 'SALIDA' : 'ENTRADA';
    final bytes = utf8.encode('$sesionId|$tipoServidor|$idempotencyKey');
    return sha256.convert(bytes).toString();
  }

  /// Solicita un token fresco para el intento indicado; null si no es posible.
  Future<String?> obtenerToken({
    required String sesionId,
    required String tipo,
    required String? idempotencyKey,
  }) async {
    final numeroProyecto = int.tryParse(_proyectoCloud.trim());
    if (!_plataformaSoportada || numeroProyecto == null) return null;
    if (idempotencyKey == null || idempotencyKey.isEmpty) return null;

    try {
      final token = await _canal.invokeMethod<String>('solicitarToken', {
        'numeroProyecto': numeroProyecto,
        'requestHash': hashSolicitud(sesionId, tipo, idempotencyKey),
      });
      return (token == null || token.isEmpty) ? null : token;
    } catch (_) {
      return null;
    }
  }
}
