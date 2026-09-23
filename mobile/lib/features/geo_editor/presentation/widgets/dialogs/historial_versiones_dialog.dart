import 'package:flutter/material.dart';
import 'package:siaa_mobile/core/theme/app_theme.dart';
import 'package:siaa_mobile/features/geo_editor/domain/models/geometria_historial_item.dart';

/// Modal para consultar el histórico de versiones de geometría de un espacio (US-GEO-06 AC-04).
/// Permite visualizar la fecha, autor, área calculada y superponer la versión sobre el mapa.
class HistorialVersionesDialog extends StatelessWidget {
  final List<GeometriaHistorialItem> versiones;
  final int? versionActivaPreview;
  final ValueChanged<int?> onSeleccionarPreview;

  const HistorialVersionesDialog({
    super.key,
    required this.versiones,
    required this.versionActivaPreview,
    required this.onSeleccionarPreview,
  });

  static Future<void> mostrar(
    BuildContext context, {
    required List<GeometriaHistorialItem> versiones,
    required int? versionActivaPreview,
    required ValueChanged<int?> onSeleccionarPreview,
  }) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: SIAAColors.neutral900,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => HistorialVersionesDialog(
        versiones: versiones,
        versionActivaPreview: versionActivaPreview,
        onSeleccionarPreview: onSeleccionarPreview,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.history_rounded, color: Colors.cyanAccent, size: 24),
                  SizedBox(width: 8),
                  Text(
                    'Historial de Geometrías (US-GEO-06)',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, color: Colors.white70),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Auditoría inmutable de versiones de geocercos archivadas para este espacio.',
            style: TextStyle(fontSize: 13, color: SIAAColors.neutral400),
          ),
          const SizedBox(height: 16),
          if (versiones.isEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: SIAAColors.neutral800,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'No existen versiones históricas archivadas aún.\nEl historial se genera automáticamente a partir de la segunda modificación.',
                textAlign: TextAlign.center,
                style: TextStyle(color: SIAAColors.neutral400, fontSize: 13),
              ),
            )
          else
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.45,
              ),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: versiones.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final v = versiones[index];
                  final isPreviewing = versionActivaPreview == v.version;

                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isPreviewing
                          ? Colors.purpleAccent.withOpacity(0.15)
                          : SIAAColors.neutral800,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isPreviewing ? Colors.purpleAccent : SIAAColors.neutral700,
                        width: isPreviewing ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.purple.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'v${v.version}',
                            style: const TextStyle(
                              color: Colors.purpleAccent,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${v.areaMetrosCuadrados.toStringAsFixed(1)} m²  •  ${v.metodoCaptura ?? "MIXTO"}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Por: ${v.creadoPor}  •  ${_formatearFecha(v.creadoEn)}',
                                style: const TextStyle(
                                  color: SIAAColors.neutral400,
                                  fontSize: 11,
                                ),
                              ),
                              if (v.motivoCambio != null && v.motivoCambio!.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 2),
                                  child: Text(
                                    'Motivo: ${v.motivoCambio}',
                                    style: const TextStyle(
                                      color: Colors.amberAccent,
                                      fontSize: 11,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: isPreviewing ? 'Ocultar superposición' : 'Previsualizar en mapa',
                          icon: Icon(
                            isPreviewing ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                            color: isPreviewing ? Colors.purpleAccent : Colors.white70,
                          ),
                          onPressed: () {
                            onSeleccionarPreview(isPreviewing ? null : v.version);
                            Navigator.of(context).pop();
                          },
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  static String _formatearFecha(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
