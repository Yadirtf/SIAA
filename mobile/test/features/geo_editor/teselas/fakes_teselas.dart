// fakes_teselas.dart — Dobles en memoria del almacén y del cliente de teselas
import 'dart:typed_data';

import 'package:siaa_mobile/features/geo_editor/data/teselas/almacen_teselas.dart';
import 'package:siaa_mobile/features/geo_editor/data/teselas/cliente_teselas.dart';
import 'package:siaa_mobile/features/geo_editor/domain/models/clave_tesela.dart';

class AlmacenMemoria implements AlmacenTeselas {
  final Map<ClaveTesela, TeselaGuardada> datos = {};
  DateTime ahora = DateTime(2026, 10, 9);

  @override
  Future<bool> existe(ClaveTesela clave) async => datos.containsKey(clave);

  @override
  Future<void> guardar(ClaveTesela clave, Uint8List bytes) async =>
      datos[clave] = TeselaGuardada(bytes, ahora);

  @override
  Future<TeselaGuardada?> leer(ClaveTesela clave) async => datos[clave];
}

class ClienteFalso implements ClienteTeselas {
  bool sinRed = false;
  final Set<String> fallan = {};
  final List<String> pedidas = [];

  @override
  Future<Uint8List> descargar(String url) async {
    pedidas.add(url);
    if (sinRed || fallan.contains(url)) throw StateError('sin red');
    return Uint8List.fromList(url.codeUnits);
  }
}
