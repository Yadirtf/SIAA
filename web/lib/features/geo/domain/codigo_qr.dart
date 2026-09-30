import 'dart:math';

const _alfabeto = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';

/// Genera un código QR aleatorio para un aula (RF-GEO-016) con la forma
/// `SIAA-<codigoEspacio>-<6 alfanuméricos en mayúscula>`.
/// El código del espacio se normaliza a mayúsculas, sin espacios.
String generarCodigoQr(String codigoEspacio, {Random? random}) {
  final rnd = random ?? Random.secure();
  final codigo = codigoEspacio.trim().toUpperCase().replaceAll(
    RegExp(r'[^A-Z0-9-]+'),
    '-',
  );
  final sufijo = List.generate(
    6,
    (_) => _alfabeto[rnd.nextInt(_alfabeto.length)],
  ).join();
  return codigo.isEmpty ? 'SIAA-$sufijo' : 'SIAA-$codigo-$sufijo';
}
