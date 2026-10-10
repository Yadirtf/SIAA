// cliente_teselas.dart — Descarga HTTP de una tesela desde el proveedor cartográfico
import 'dart:typed_data';

import 'package:dio/dio.dart';

abstract class ClienteTeselas {
  /// Bytes de la imagen; lanza si no hay red o el servidor no responde 200.
  Future<Uint8List> descargar(String url);
}

class ClienteTeselasDio implements ClienteTeselas {
  final Dio _dio;

  ClienteTeselasDio({Dio? dio})
      : _dio = dio ??
            Dio(BaseOptions(
              connectTimeout: const Duration(seconds: 8),
              receiveTimeout: const Duration(seconds: 12),
              responseType: ResponseType.bytes,
              headers: {'User-Agent': 'com.siaa.mobile'},
            ));

  @override
  Future<Uint8List> descargar(String url) async {
    final r = await _dio.get<List<int>>(url);
    final datos = r.data;
    if (r.statusCode != 200 || datos == null || datos.isEmpty) {
      throw StateError('Tesela no disponible (${r.statusCode}): $url');
    }
    return Uint8List.fromList(datos);
  }
}
