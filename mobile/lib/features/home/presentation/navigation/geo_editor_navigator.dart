import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/geo/offline_cartografia_service.dart';
import '../../../../core/network/conectividad.dart';
import '../../../geo_editor/data/espacio_repository.dart';
import '../../../geo_editor/presentation/bloc/geo_editor_bloc.dart';
import '../../../geo_editor/presentation/screens/geo_editor_screen.dart';

/// Coordinador de navegación hacia el editor cartográfico GeoEditor (US-GEO-02, US-GEO-07).
/// Sin conexión, la geometría cerrada se guarda cifrada en el dispositivo (US-GEO-10).
class GeoEditorNavigator {
  /// [captura]: corrige una captura offline rechazada o en conflicto; el editor abre
  /// con sus vértices y, al guardarse en el servidor, sale de la cola local.
  static Future<void> navegar({
    required BuildContext context,
    required EspacioModel espacio,
    required EspacioRepository espacioRepo,
    required VoidCallback onRetorno,
    CapturaOfflineEspacio? captura,
    OfflineCartografiaService? cola,
    Future<bool> Function()? hayConexion,
  }) async {
    final colaOffline = cola ?? OfflineCartografiaService.instancia;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BlocProvider<GeoEditorBloc>(
          create: (_) => GeoEditorBloc(
            hayConexion: hayConexion ?? hayConexionDeRed,
            onSaveGeometry: ({
              required String espacioId,
              required List<List<double>> coordenadas,
              required String metodoCaptura,
              double? precisionPromedioMetros,
              bool confirmarSolapamiento = false,
              String? motivoSolapamiento,
            }) async {
              await espacioRepo.guardarGeometria(
                espacioId: espacioId,
                coordenadas: coordenadas,
                metodoCaptura: metodoCaptura,
                precisionPromedioMetros: precisionPromedioMetros,
                confirmarSolapamiento: confirmarSolapamiento,
                motivoSolapamiento: motivoSolapamiento,
              );
              if (captura != null) await colaOffline.eliminar(captura.id);
            },
            onSaveOffline: ({
              required String espacioId,
              required List<List<double>> coordenadas,
              required String metodoCaptura,
              double? precisionPromedioMetros,
            }) =>
                colaOffline.guardarCapturaOffline(CapturaOfflineEspacio(
              id: captura?.id ?? const Uuid().v4(),
              espacioId: espacioId,
              espacioCodigo: espacio.codigo,
              espacioNombre: espacio.nombre,
              vertices: coordenadas,
              metodoCaptura: metodoCaptura,
              precisionPromedioMetros: precisionPromedioMetros,
              capturadoEn: DateTime.now(),
              // Versión vista al abrir el editor (al corregir, la recién consultada).
              versionEsperada: espacio.versionGeometria,
            )),
            onFetchHistorial: (id) => espacioRepo.obtenerVersionesGeometria(id),
          ),
          child: GeoEditorScreen(
            espacioId: espacio.id,
            espacioCodigo: espacio.codigo,
            espacioNombre: espacio.nombre,
            coordenadasExistentes: captura?.vertices ?? espacio.coordenadas,
          ),
        ),
      ),
    );
    onRetorno();
  }
}
