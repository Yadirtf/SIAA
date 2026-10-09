// repositorio_teselas.dart — Teselas con caché persistente para el modo mapa (US-GEO-03 AC-04)
// En línea: sirve la copia guardada si es reciente y, si no, la descarga y la guarda.
// Sin conexión: sirve la copia guardada aunque esté vencida; si no existe, falla la tesela.
import 'dart:typed_data';

import '../../domain/models/clave_tesela.dart';
import '../../domain/services/teselas_area.dart';
import 'almacen_teselas.dart';
import 'cliente_teselas.dart';

class ResumenDescarga {
  final int descargadas;
  final int yaGuardadas;
  final int fallidas;

  const ResumenDescarga({
    required this.descargadas,
    required this.yaGuardadas,
    required this.fallidas,
  });

  int get total => descargadas + yaGuardadas + fallidas;
}

class RepositorioTeselas {
  /// Antigüedad a partir de la cual se intenta refrescar una tesela con red.
  static const frescura = Duration(days: 30);

  final AlmacenTeselas _almacen;
  final ClienteTeselas _cliente;
  final DateTime Function() _ahora;

  RepositorioTeselas({
    AlmacenTeselas? almacen,
    ClienteTeselas? cliente,
    DateTime Function()? ahora,
  })  : _almacen = almacen ?? AlmacenTeselasArchivo(),
        _cliente = cliente ?? ClienteTeselasDio(),
        _ahora = ahora ?? DateTime.now;

  Future<Uint8List> obtener(ClaveTesela clave, String url) async {
    final guardada = await _almacen.leer(clave);
    if (guardada != null &&
        _ahora().difference(guardada.guardadaEn) < frescura) {
      return guardada.bytes;
    }
    try {
      final bytes = await _cliente.descargar(url);
      await _almacen.guardar(clave, bytes);
      return bytes;
    } catch (_) {
      if (guardada != null) return guardada.bytes;
      rethrow;
    }
  }

  /// Cuántas de [claves] existen en el almacén.
  Future<int> contarGuardadas(Iterable<ClaveTesela> claves) async {
    var n = 0;
    for (final c in claves) {
      if (await _almacen.existe(c)) n++;
    }
    return n;
  }

  /// Descarga (con [paralelas] peticiones simultáneas) las teselas de [area] que aún
  /// no estén guardadas. [onProgreso] recibe (procesadas, total).
  Future<ResumenDescarga> predescargar({
    required String capa,
    required String plantillaUrl,
    required AreaGeo area,
    required int zMin,
    required int zMax,
    void Function(int procesadas, int total)? onProgreso,
    int paralelas = 4,
  }) async {
    final claves = TeselasArea.enArea(capa, area, zMin, zMax).toList();
    var descargadas = 0, yaGuardadas = 0, fallidas = 0, procesadas = 0;
    var siguiente = 0;

    Future<void> trabajador() async {
      while (siguiente < claves.length) {
        final clave = claves[siguiente++];
        if (await _almacen.existe(clave)) {
          yaGuardadas++;
        } else {
          try {
            final bytes =
                await _cliente.descargar(TeselasArea.url(plantillaUrl, clave));
            await _almacen.guardar(clave, bytes);
            descargadas++;
          } catch (_) {
            fallidas++;
          }
        }
        onProgreso?.call(++procesadas, claves.length);
      }
    }

    await Future.wait(List.generate(paralelas, (_) => trabajador()));
    return ResumenDescarga(
      descargadas: descargadas,
      yaGuardadas: yaGuardadas,
      fallidas: fallidas,
    );
  }
}
