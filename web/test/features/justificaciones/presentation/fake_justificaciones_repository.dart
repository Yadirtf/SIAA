import 'dart:typed_data';

import 'package:siaa_web/core/models/pagina.dart';
import 'package:siaa_web/core/network/api_exception.dart';
import 'package:siaa_web/core/network/archivo_binario.dart';
import 'package:siaa_web/features/justificaciones/data/models/justificacion_model.dart';
import 'package:siaa_web/features/justificaciones/data/models/justificaciones_filtro.dart';
import 'package:siaa_web/features/justificaciones/domain/justificaciones_repository.dart';

/// Repositorio en memoria para probar los cubits sin red.
class FakeJustificacionesRepository implements JustificacionesRepository {
  List<JustificacionModel> justificaciones = [];
  Map<String, String> nombres = {};
  ApiException? error;
  ApiException? errorRevisar;
  JustificacionesFiltro? ultimoFiltro;
  final List<String> llamadas = [];

  @override
  Future<Pagina<JustificacionModel>> listar(JustificacionesFiltro f) async {
    llamadas.add('listar');
    ultimoFiltro = f;
    if (error != null) throw error!;
    final lista = justificaciones
        .where((j) => f.estado == null || j.estado == f.estado)
        .toList();
    return Pagina(
      items: lista,
      total: lista.length,
      pagina: f.pagina,
      limite: f.limite,
    );
  }

  @override
  Future<JustificacionModel> obtener(String id) async {
    llamadas.add('obtener');
    return justificaciones.firstWhere((j) => j.id == id);
  }

  @override
  Future<JustificacionModel> revisar(
    String id, {
    required String estado,
    String? observaciones,
  }) async {
    llamadas.add('revisar:$estado');
    if (errorRevisar != null) throw errorRevisar!;
    final i = justificaciones.indexWhere((j) => j.id == id);
    final a = justificaciones[i];
    justificaciones[i] = JustificacionModel(
      id: a.id,
      sesionId: a.sesionId,
      docenteId: a.docenteId,
      tipo: a.tipo,
      descripcion: a.descripcion,
      estado: estado,
      observaciones: observaciones,
      revisorId: 'rev',
    );
    return justificaciones[i];
  }

  @override
  Future<ArchivoBinario> descargarSoporte(String id, String soporteId) async {
    llamadas.add('soporte:$soporteId');
    return ArchivoBinario(
      bytes: Uint8List.fromList([1, 2]),
      mime: 'application/pdf',
    );
  }

  @override
  Future<String?> nombreUsuario(String id) async {
    llamadas.add('nombre:$id');
    return nombres[id];
  }
}
