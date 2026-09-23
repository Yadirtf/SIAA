import 'package:flutter/material.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../geo_editor/data/espacio_repository.dart';
import '../cards/espacio_card_tile.dart';

class AulasSelectionList extends StatelessWidget {
  final BloqueModel? bloqueSeleccionado;
  final List<EspacioModel> espacios;
  final bool cargandoEspacios;
  final VoidCallback? onCrearAula;
  final void Function(EspacioModel) onEditarEspacio;

  const AulasSelectionList({
    super.key,
    required this.bloqueSeleccionado,
    required this.espacios,
    required this.cargandoEspacios,
    required this.onCrearAula,
    required this.onEditarEspacio,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '3. Aulas / Espacios (${espacios.length})',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                visualDensity: VisualDensity.compact,
                backgroundColor: SIAAColors.primary600,
              ),
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Crear Aula'),
              onPressed: onCrearAula,
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (cargandoEspacios)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (bloqueSeleccionado == null)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'Seleccione o cree una Sede y un Bloque para gestionar sus aulas y delimitar sus perímetros.',
              style: TextStyle(fontSize: 12, color: SIAAColors.neutral600),
            ),
          )
        else if (espacios.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: SIAAColors.neutral200),
            ),
            child: Column(
              children: [
                const Icon(Icons.meeting_room_outlined, size: 32, color: SIAAColors.neutral400),
                const SizedBox(height: 6),
                Text(
                  'No hay aulas en ${bloqueSeleccionado!.nombre}',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Presiona "+ Crear Aula" para registrar un salón y delimitar su polígono GPS.',
                  style: TextStyle(fontSize: 11, color: SIAAColors.neutral500),
                ),
              ],
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: espacios.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, idx) {
              final esp = espacios[idx];
              return EspacioCardTile(
                espacio: esp,
                onEditarPoligono: () => onEditarEspacio(esp),
              );
            },
          ),
      ],
    );
  }
}
