// almacen_teselas.dart — Persistencia de teselas en disco para el modo mapa sin conexión
// Se guardan en el directorio de soporte de la app (no en el de caché), para que el sistema
// operativo no las borre mientras el administrador levanta un espacio sin señal.
import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';

import '../../domain/models/clave_tesela.dart';

class TeselaGuardada {
  final Uint8List bytes;
  final DateTime guardadaEn;

  const TeselaGuardada(this.bytes, this.guardadaEn);
}

abstract class AlmacenTeselas {
  Future<TeselaGuardada?> leer(ClaveTesela clave);
  Future<void> guardar(ClaveTesela clave, Uint8List bytes);
  Future<bool> existe(ClaveTesela clave);
}

class AlmacenTeselasArchivo implements AlmacenTeselas {
  final Future<Directory> Function() _raiz;
  Future<Directory>? _directorio;

  AlmacenTeselasArchivo({Future<Directory> Function()? raiz})
      : _raiz = raiz ?? getApplicationSupportDirectory;

  Future<Directory> _base() => _directorio ??= () async {
        final r = await _raiz();
        return Directory('${r.path}${Platform.pathSeparator}teselas_mapa');
      }();

  Future<File> _archivo(ClaveTesela c) async {
    final base = await _base();
    final s = Platform.pathSeparator;
    return File('${base.path}$s${c.capa}$s${c.z}$s${c.x}$s${c.y}.tile');
  }

  @override
  Future<TeselaGuardada?> leer(ClaveTesela clave) async {
    try {
      final f = await _archivo(clave);
      if (!await f.exists()) return null;
      final bytes = await f.readAsBytes();
      if (bytes.isEmpty) return null;
      return TeselaGuardada(bytes, await f.lastModified());
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> guardar(ClaveTesela clave, Uint8List bytes) async {
    if (bytes.isEmpty) return;
    try {
      final f = await _archivo(clave);
      await f.parent.create(recursive: true);
      // Escritura atómica: un corte a mitad no deja una tesela corrupta.
      final tmp = File('${f.path}.tmp');
      await tmp.writeAsBytes(bytes, flush: true);
      await tmp.rename(f.path);
    } catch (_) {
      // Sin espacio o sin permisos: el mapa sigue funcionando en línea.
    }
  }

  @override
  Future<bool> existe(ClaveTesela clave) async {
    try {
      return await (await _archivo(clave)).exists();
    } catch (_) {
      return false;
    }
  }
}
