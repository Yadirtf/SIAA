import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as ll;

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../data/models/geo_models.dart';
import '../bloc/geo_bloc.dart';
import '../bloc/geo_event.dart';
import 'editor_geometria_cubit.dart';
import 'editor_geometria_state.dart';
import 'ir_a_coordenadas.dart';
import 'mapa_geometria.dart';
import 'solapamiento_dialog.dart';

/// Abre el editor de polígono por escritorio de un aula (SRS §9.2).
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
      child: BlocProvider.value(
        value: geoBloc,
        child: const _EditorGeometria(),
      ),
    ),
  );
}

class _EditorGeometria extends StatefulWidget {
  const _EditorGeometria();

  @override
  State<_EditorGeometria> createState() => _EditorGeometriaState();
}

class _EditorGeometriaState extends State<_EditorGeometria> {
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

  @override
  Widget build(BuildContext context) {
    final espacio = context.read<EditorGeometriaCubit>().espacio;
    return Dialog(
      insetPadding: const EdgeInsets.all(24),
      child: SizedBox(
        width: 1100,
        height: 760,
        child: BlocConsumer<EditorGeometriaCubit, EditorGeometriaState>(
          listenWhen: (a, b) =>
              a.guardado != b.guardado || a.solapamiento != b.solapamiento,
          listener: _alCambiar,
          builder: (context, s) => Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _encabezado(context, espacio),
                const SizedBox(height: 12),
                Expanded(child: _mapaConCapas(context, s)),
                if (s.error != null) _aviso(s.error!),
                const SizedBox(height: 12),
                _barra(context, s),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _encabezado(BuildContext context, EspacioModel espacio) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Polígono de ${espacio.nombre} (${espacio.codigo})',
                style: AppTextStyles.h3,
              ),
              const SizedBox(height: 4),
              Text(
                'Haga clic en cada esquina del aula, en orden alrededor del '
                'perímetro. El backend cierra el polígono y le suma el buffer '
                'de ${espacio.bufferMetros.toStringAsFixed(0)} m.',
                style: AppTextStyles.bodyMedium,
              ),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.close_rounded),
          tooltip: 'Cerrar sin guardar',
          onPressed: () => Navigator.pop(context),
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
            onToque: cubit.agregarVertice,
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

  Widget _barra(BuildContext context, EditorGeometriaState s) {
    final cubit = context.read<EditorGeometriaCubit>();
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        IrACoordenadas(onIr: (lat, lon) => _mapa.move(ll.LatLng(lat, lon), 19)),
        OutlinedButton.icon(
          onPressed: s.vertices.isEmpty ? null : cubit.deshacer,
          icon: const Icon(Icons.undo_rounded, size: 18),
          label: const Text('Deshacer'),
        ),
        OutlinedButton.icon(
          onPressed: s.vertices.isEmpty ? null : cubit.limpiar,
          icon: const Icon(Icons.layers_clear_outlined, size: 18),
          label: const Text('Borrar todo'),
        ),
        Text('${s.vertices.length} esquinas', style: AppTextStyles.bodyMedium),
        ElevatedButton.icon(
          onPressed: s.puedeGuardar ? cubit.guardar : null,
          icon: s.guardando
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.save_rounded, size: 18),
          label: const Text('Guardar polígono'),
        ),
      ],
    );
  }
}
