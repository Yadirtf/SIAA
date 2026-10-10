// spki_extractor.dart — Extrae SubjectPublicKeyInfo de un certificado X.509 en DER (RNF-SEG-001)
// El pin SHA-256 se calcula sobre la clave pública (SPKI) y no sobre el certificado completo:
// así el pin sobrevive a la renovación del certificado si se conserva el par de claves.
//
// Certificate ::= SEQUENCE { tbsCertificate, signatureAlgorithm, signatureValue }
// TBSCertificate ::= SEQUENCE { [0] version OPCIONAL, serialNumber, signature, issuer,
//                               validity, subject, subjectPublicKeyInfo, ... }
import 'dart:typed_data';

class SpkiExtractor {
  const SpkiExtractor._();

  /// Bytes DER (etiqueta + longitud + contenido) del SubjectPublicKeyInfo,
  /// o null si el certificado no tiene la estructura esperada.
  static Uint8List? extraer(List<int> der) {
    try {
      final cert = _leer(der, 0);
      if (cert.etiqueta != _secuencia) return null;
      final tbs = _leer(der, cert.inicioContenido);
      if (tbs.etiqueta != _secuencia) return null;

      var pos = tbs.inicioContenido;
      // [0] EXPLICIT version: solo presente en certificados v2/v3.
      if (der[pos] == _versionExplicita) pos = _leer(der, pos).fin;
      // serialNumber, signature, issuer, validity, subject.
      for (var i = 0; i < 5; i++) {
        pos = _leer(der, pos).fin;
      }
      final spki = _leer(der, pos);
      if (spki.etiqueta != _secuencia || spki.fin > tbs.fin) return null;
      return Uint8List.fromList(der.sublist(pos, spki.fin));
    } on RangeError {
      return null;
    } on FormatException {
      return null;
    }
  }

  static const _secuencia = 0x30;
  static const _versionExplicita = 0xA0;

  static _Tlv _leer(List<int> der, int pos) {
    final etiqueta = der[pos];
    var cursor = pos + 1;
    var longitud = der[cursor++];
    if (longitud & 0x80 != 0) {
      final bytes = longitud & 0x7F;
      if (bytes == 0 || bytes > 4) {
        throw const FormatException('Longitud DER no soportada');
      }
      longitud = 0;
      for (var i = 0; i < bytes; i++) {
        longitud = (longitud << 8) | der[cursor++];
      }
    }
    final fin = cursor + longitud;
    if (fin > der.length) throw const FormatException('DER truncado');
    return _Tlv(etiqueta, cursor, fin);
  }
}

class _Tlv {
  final int etiqueta;
  final int inicioContenido;
  final int fin;

  const _Tlv(this.etiqueta, this.inicioContenido, this.fin);
}
