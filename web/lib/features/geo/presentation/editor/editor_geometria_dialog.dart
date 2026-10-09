import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as ll;

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../data/models/geo_models.dart';
import '../bloc/geo_bloc.dart';
import '../bloc/geo_event.dart';
import 'barra_editor_geometria.dart';
import 'confirmar_descartar.dart';
import 'editor_geometria_cubit.dart';
import 'editor_geometria_state.dart';
import 'ir_a_coordenadas.dart';
import 'mapa_geometria.dart';
import 'solapamiento_dialog.dart';

/// Abre el editor de polígono por escritorio de un aula (SRS §9.2,
/// US-GEO-07): dibuja un polígono nuevo o edita los vértices del guardado.
Future<void> mostrarEditorGeometria(
  BuildContext context,
  EspacioModel espacio,
) {
  final geoBloc = context.read<GeoBloc>();
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => BlocProvider(
      create: (_) => EditorGeometriaCubit(espacio: espacio),
      child: BlocProvider.value(value: geoBloc, child: const EditorGeometria()),
    ),
  );
}

/// Contenido del editor; requiere [EditorGeometriaCubit] y [GeoBloc].
class EditorGeometria extends StatefulWidget {
  const EditorGeometria({super.key});

  @override
  State<EditorGeometria> createState() => _EditorGeometriaState();
}

class _EditorGeometriaState extends State<EditorGeometria> {
  final _mapa = MapController();
  bool _satelite = true;

  Future<void> _alCambiar(BuildContext context, EditorGeometriaState s) async {
    final cubit = context.read<EditorGeometriaCubit>();
    if (s.guardado != null) {
      context.read<GeoBloc>().add(EspacioActualizadoEvent(s.guardado!));
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Polígono de ${s.guardado!.codigo} guardado.')),
      );
      return;
    }
    if (s.solapamiento != null) {
      final motivo = await pedirMotivoSolapamiento(context, s.solapamiento!);
      if (motivo == null) {
        cubit.descartarSolapamiento();
      } else {
        await cubit.guardar(confirmarSolapamiento: true, motivo: motivo);
      }
    }
  }

  /// US-GEO-07 AC-05: con cambios sin guardar se pide confirmación.
  Future<void> _alSalir(bool salio, Object? _) async {
    if (salio) return;
    final navegador = Navigator.of(context);
    if (await confirmarDescartarCambios(context)) navegador.pop();
  }

  @override
  Widget build(BuildContext context) {
    final espacio = context.read<EditorGeometriaCubit>().espacio;
    return BlocConsumer<EditorGeometriaCubit, EditorGeometriaState>(
      listenWhen: (a, b) =>
          a.guardado != b.guardado || a.solapamiento != b.solapamiento,
      listener: _alCambiar,
      builder: (context, s) => PopScope(
        canPop: !s.modificado || s.guardado != null,
        onPopInvokedWithResult: _alSalir,
        child: Dialog(
          insetPadding: const EdgeInsets.all(24),
          child: SizedBox(
            width: 1100,
            height: 760,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _encabezado(context, espacio, s),
                  const SizedBox(height: 12),
                  Expanded(child: _mapaConCapas(context, s)),
                  if (s.error != null) _aviso(s.error!),
                  const SizedBox(height: 12),
                  BarraEditorGeometria(
                    estado: s,
                    irACoordenadas: IrACoordenadas(
                      onIr: (lat, lon) => _mapa.move(ll.LatLng(lat, lon), 19),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _encabezado(
    BuildContext context,
    EspacioModel espacio,
    EditorGeometriaState s,
  ) {
    final ayuda = s.modo == ModoEditor.editar
        ? 'Arrastre un vértice para moverlo, haga clic sobre un lado para '
              'insertar uno nuevo y clic derecho (o seleccione y use '
              '"Eliminar vértice") para quitarlo. Mínimo 3 vértices.'
        : 'Haga clic en cada esquina del aula, en orden alrededor del '
              'perímetro. El backend cierra el polígono y le suma el buffer '
              'de ${espacio.bufferMetros.toStringAsFixed(0)} m.';
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Polígono de ${espacio.nombre} (${espacio.codigo})'
                '${espacio.tieneGeometria ? ' · versión ${espacio.versionGeometria}' : ''}',
                style: AppTextStyles.h3,
              ),
              const SizedBox(height: 4),
              Text(ayuda, style: AppTextStyles.bodyMedium),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.close_rounded),
          tooltip: 'Cerrar sin guardar',
          onPressed: () => Navigator.maybePop(context),
        ),
      ],
    );
  }

  Widget _mapaConCapas(BuildContext context, EditorGeometriaState s) {
    final cubit = context.read<EditorGeometriaCubit>();
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Stack(
        children: [
          MapaGeometria(
            controller: _mapa,
            vertices: s.vertices,
            satelite: _satelite,
            modo: s.modo,
            seleccionado: s.seleccionado,
            onToque: cubit.agregarVertice,
            onInsertar: cubit.insertarVertice,
            onMover: cubit.moverVertice,
            onSeleccionar: cubit.seleccionar,
            onEliminar: cubit.eliminarVertice,
          ),
          Positioned(
            top: 12,
            right: 12,
            child: FloatingActionButton.small(
              heroTag: null,
              tooltip: _satelite ? 'Ver mapa de calles' : 'Ver satélite',
              onPressed: () => setState(() => _satelite = !_satelite),
              child: Icon(_satelite ? Icons.map_outlined : Icons.satellite_alt),
            ),
          ),
        ],
      ),
    );
  }

  Widget _aviso(String texto) => Padding(
    padding: const EdgeInsets.only(top: 8),
    child: Text(
      texto,
      style: AppTextStyles.bodyMedium.copyWith(color: AppColors.accentRose),
    ),
  );
}
