import 'package:siaa_web/features/geo/data/buscador_espacios.dart';
import 'package:siaa_web/features/geo/data/models/espacio_opcion.dart';
import 'package:siaa_web/features/geo/data/models/geo_models.dart';
import 'package:siaa_web/features/usuarios/data/buscador_usuarios.dart';
import 'package:siaa_web/features/usuarios/data/models/usuario_model.dart';

/// Buscador de usuarios en memoria que registra las consultas recibidas.
class FakeBuscadorUsuarios implements BuscadorUsuarios {
  final List<UsuarioModel> usuarios;
  final consultas = <({String texto, String? rol})>[];

  FakeBuscadorUsuarios(this.usuarios);

  @override
  Future<List<UsuarioModel>> buscar(
    String consulta, {
    String? rol,
    bool soloActivos = true,
    int limite = 20,
  }) async {
    consultas.add((texto: consulta, rol: rol));
    final q = consulta.toLowerCase();
    return usuarios
        .where((u) => u.nombreCompleto.toLowerCase().contains(q))
        .toList();
  }

  @override
  Future<UsuarioModel?> porId(String id) async =>
      usuarios.where((u) => u.id == id).firstOrNull;
}

/// Buscador de espacios en memoria que registra la sede pedida.
class FakeBuscadorEspacios implements BuscadorEspacios {
  final List<EspacioOpcion> espacios;
  final sedesPedidas = <String?>[];

  FakeBuscadorEspacios(this.espacios);

  @override
  Future<List<EspacioOpcion>> listar({String? sedeId}) async {
    sedesPedidas.add(sedeId);
    return espacios.where((e) => sedeId == null || e.sedeId == sedeId).toList();
  }
}

UsuarioModel docente(String id, String nombre, String apellido) => UsuarioModel(
  id: id,
  correo: '${nombre.toLowerCase()}@uni.edu.co',
  nombre: nombre,
  apellido: apellido,
  activo: true,
  roles: const ['DOCENTE'],
);

EspacioOpcion aula(String id, String sedeId, String codigo, String nombre) =>
    EspacioOpcion(
      espacio: EspacioModel(
        id: id,
        sedeId: sedeId,
        codigo: codigo,
        nombre: nombre,
        capacidad: 30,
        tipo: 'AULA',
        estado: 'ACTIVO',
        bufferMetros: 0,
        areaMetrosCuadrados: 0,
        activo: true,
      ),
    );
