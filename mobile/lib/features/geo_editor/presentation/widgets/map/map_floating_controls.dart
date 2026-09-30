import 'package:flutter/material.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../domain/models/capa_mapa.dart';

/// Barra de botones flotantes sobre el mapa para control de capas, navegación y zoom.
class MapFloatingControls extends StatelessWidget {
  final CapaMapa capaActual;
  final bool hasGpsPosition;
  final bool hasVertices;
  final VoidCallback onRotarCapa;
  final VoidCallback onCentrarGps;
  final VoidCallback onCentrarPoligono;
  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;

  const MapFloatingControls({
    super.key,
    required this.capaActual,
    required this.hasGpsPosition,
    required this.hasVertices,
    required this.onRotarCapa,
    required this.onCentrarGps,
    required this.onCentrarPoligono,
    required this.onZoomIn,
    required this.onZoomOut,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Botón Rotar Capa (Google Híbrido -> Esri -> OSM)
        MapFloatingButton(
          icon: capaActual.icono,
          tooltip: 'Cambiar capa (Actual: ${capaActual.nombre})',
          onPressed: onRotarCapa,
        ),
        const SizedBox(height: 8),

        // Botón Centrar en mi ubicación GPS
        MapFloatingButton(
          icon: Icons.my_location,
          tooltip: 'Mi ubicación GPS',
          color: hasGpsPosition ? Colors.cyanAccent : SIAAColors.neutral400,
          onPressed: onCentrarGps,
        ),
        const SizedBox(height: 8),

        // Botón Centrar en el polígono completo
        if (hasVertices) ...[
          MapFloatingButton(
            icon: Icons.crop_free,
            tooltip: 'Ver polígono completo',
            onPressed: onCentrarPoligono,
          ),
          const SizedBox(height: 8),
        ],

        // Zoom In (+)
        MapFloatingButton(
          icon: Icons.add,
          tooltip: 'Acercar',
          onPressed: onZoomIn,
        ),
        const SizedBox(height: 8),

        // Zoom Out (-)
        MapFloatingButton(
          icon: Icons.remove,
          tooltip: 'Alejar',
          onPressed: onZoomOut,
        ),
      ],
    );
  }
}

/// Botón circular flotante con diseño glassmorphism oscuro.
class MapFloatingButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final Color? color;

  const MapFloatingButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B).withValues(alpha: 0.90),
        shape: BoxShape.circle,
        boxShadow: const [
          BoxShadow(
            color: Colors.black38,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: IconButton(
        icon: Icon(icon, color: color ?? Colors.white, size: 20),
        tooltip: tooltip,
        onPressed: onPressed,
      ),
    );
  }
}
