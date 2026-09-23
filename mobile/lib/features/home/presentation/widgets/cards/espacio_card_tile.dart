import 'package:flutter/material.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../geo_editor/data/espacio_repository.dart';

/// Tarjeta individual para mostrar un aula/espacio y su estado cartográfico (US-GEO-01).
class EspacioCardTile extends StatelessWidget {
  final EspacioModel espacio;
  final VoidCallback onEditarPoligono;

  const EspacioCardTile({
    super.key,
    required this.espacio,
    required this.onEditarPoligono,
  });

  @override
  Widget build(BuildContext context) {
    final tieneGeo = espacio.tieneGeometria;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: SIAAColors.neutral200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: tieneGeo ? SIAAColors.primary50 : Colors.orange.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.meeting_room_rounded,
              color: tieneGeo ? SIAAColors.primary600 : Colors.orange.shade800,
              size: 22,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      espacio.codigo,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: tieneGeo
                            ? SIAAColors.asistenciaPresente.withOpacity(0.15)
                            : Colors.orange.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        tieneGeo
                            ? 'Delimitada (${espacio.areaMetrosCuadrados.toStringAsFixed(1)} m²)'
                            : 'Sin Polígono',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: tieneGeo ? SIAAColors.asistenciaPresente : Colors.orange.shade800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  espacio.nombre,
                  style: const TextStyle(fontSize: 12, color: SIAAColors.neutral700),
                ),
                Text(
                  'Piso ${espacio.piso ?? 1} · Capacidad: ${espacio.capacidad} est. · Tipo: ${espacio.tipo}',
                  style: const TextStyle(fontSize: 10, color: SIAAColors.neutral500),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          FilledButton.tonal(
            style: FilledButton.styleFrom(
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: 10),
            ),
            onPressed: onEditarPoligono,
            child: Text(
              tieneGeo ? 'Editar Polígono' : 'Trazar GPS',
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
