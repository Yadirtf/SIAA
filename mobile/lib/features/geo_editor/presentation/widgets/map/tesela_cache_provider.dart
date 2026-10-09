// tesela_cache_provider.dart — TileProvider de flutter_map respaldado por el caché persistente
// Cada tesela pasa por RepositorioTeselas: así el modo mapa funciona sin conexión con lo
// que se haya visto o descargado antes (US-GEO-03 AC-04).
import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_map/flutter_map.dart';

import '../../../data/teselas/repositorio_teselas.dart';
import '../../../domain/models/clave_tesela.dart';

class TeselaCacheTileProvider extends TileProvider {
  final RepositorioTeselas repositorio;
  final String capa;

  TeselaCacheTileProvider({required this.repositorio, required this.capa});

  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) {
    return TeselaCacheImage(
      repositorio: repositorio,
      clave: ClaveTesela(
        capa: capa,
        z: coordinates.z,
        x: coordinates.x,
        y: coordinates.y,
      ),
      url: getTileUrl(coordinates, options),
    );
  }
}

class TeselaCacheImage extends ImageProvider<TeselaCacheImage> {
  final RepositorioTeselas repositorio;
  final ClaveTesela clave;
  final String url;

  const TeselaCacheImage({
    required this.repositorio,
    required this.clave,
    required this.url,
  });

  @override
  Future<TeselaCacheImage> obtainKey(ImageConfiguration configuration) =>
      SynchronousFuture<TeselaCacheImage>(this);

  @override
  ImageStreamCompleter loadImage(
    TeselaCacheImage key,
    ImageDecoderCallback decode,
  ) {
    return MultiFrameImageStreamCompleter(
      codec: _cargar(key, decode),
      scale: 1.0,
      debugLabel: url,
    );
  }

  Future<ui.Codec> _cargar(
    TeselaCacheImage key,
    ImageDecoderCallback decode,
  ) async {
    try {
      final bytes = await repositorio.obtener(clave, url);
      return await decode(await ui.ImmutableBuffer.fromUint8List(bytes));
    } catch (_) {
      // Se saca de la caché de imágenes para reintentar cuando vuelva la red.
      scheduleMicrotask(() => PaintingBinding.instance.imageCache.evict(key));
      rethrow;
    }
  }

  @override
  bool operator ==(Object other) =>
      other is TeselaCacheImage && other.clave == clave && other.url == url;

  @override
  int get hashCode => Object.hash(clave, url);
}
