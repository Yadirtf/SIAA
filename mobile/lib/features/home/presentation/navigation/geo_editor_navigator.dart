import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../geo_editor/data/espacio_repository.dart';
import '../../../geo_editor/presentation/bloc/geo_editor_bloc.dart';
import '../../../geo_editor/presentation/screens/geo_editor_screen.dart';

/// Coordinador de navegación hacia el editor cartográfico GeoEditor (US-GEO-02, US-GEO-07).
class GeoEditorNavigator {
  static Future<void> navegar({
    required BuildContext context,
    required EspacioModel espacio,
    required EspacioRepository espacioRepo,
    required VoidCallback onRetorno,
  }) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BlocProvider<GeoEditorBloc>(
          create: (_) => GeoEditorBloc(
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
            },
            onFetchHistorial: (id) => espacioRepo.obtenerVersionesGeometria(id),
          ),
          child: GeoEditorScreen(
            espacioId: espacio.id,
            espacioCodigo: espacio.codigo,
            espacioNombre: espacio.nombre,
            coordenadasExistentes: espacio.coordenadas,
          ),
        ),
      ),
    );
    onRetorno();
  }
}
