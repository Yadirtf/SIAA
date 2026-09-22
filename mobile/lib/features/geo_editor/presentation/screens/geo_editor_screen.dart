import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/models/tagged_vertex.dart';
import '../bloc/geo_editor_bloc.dart';
import '../bloc/geo_editor_event.dart';
import '../bloc/geo_editor_state.dart';
import '../widgets/gps_traffic_light_badge.dart';

/// Pantalla interactiva de levantamiento cartográfico perimetral (US-GEO-02, US-GEO-03).
/// Cumple:
/// - US-GEO-02: Muestreo GPS, semáforo de precisión, promedio de lecturas y descarte por umbral.
/// - US-GEO-03: Captura por toque en mapa, alternancia de modos (recorrido / mapa),
///   conservación de vértices (MIXTO), aviso offline de teselas (AC-04) y omisión de precisión en TOQUE_MAPA.
class GeoEditorScreen extends StatelessWidget {
  final String espacioId;
  final String espacioCodigo;
  final String espacioNombre;

  const GeoEditorScreen({
    super.key,
    required this.espacioId,
    required this.espacioCodigo,
    required this.espacioNombre,
  });

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<GeoEditorBloc, GeoEditorState>(
      listener: (context, state) {
        if (state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage!),
              backgroundColor: SIAAColors.asistenciaAusente,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        if (state.successMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.successMessage!),
              backgroundColor: SIAAColors.asistenciaPresente,
              behavior: SnackBarBehavior.floating,
            ),
          );
          Navigator.of(context).pop(true);
        }
      },
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Cartografía: $espacioCodigo', style: const TextStyle(fontSize: 16)),
                Text(
                  espacioNombre,
                  style: const TextStyle(fontSize: 12, color: SIAAColors.neutral400),
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                tooltip: 'Reiniciar polígono',
                onPressed: state.vertices.isNotEmpty
                    ? () => _confirmarReinicio(context)
                    : null,
              ),
            ],
          ),
          body: Column(
            children: [
              // ─── Selector de Modo de Captura (AC-03) ──────────────
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: Colors.white,
                child: Row(
                  children: [
                    Expanded(
                      child: SegmentedButton<ModoCapturaEditor>(
                        segments: const [
                          ButtonSegment<ModoCapturaEditor>(
                            value: ModoCapturaEditor.recorrido,
                            icon: Icon(Icons.directions_walk, size: 18),
                            label: Text('Recorrido GPS'),
                          ),
                          ButtonSegment<ModoCapturaEditor>(
                            value: ModoCapturaEditor.mapa,
                            icon: Icon(Icons.touch_app, size: 18),
                            label: Text('Toque Mapa'),
                          ),
                        ],
                        selected: {state.modoCaptura},
                        onSelectionChanged: (Set<ModoCapturaEditor> newSelection) {
                          context.read<GeoEditorBloc>().add(
                                CambiarModoCapturaRequested(newSelection.first),
                              );
                        },
                      ),
                    ),
                  ],
                ),
              ),

              // ─── Barra de estado y método de captura ─────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: SIAAColors.neutral100,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (state.modoCaptura == ModoCapturaEditor.recorrido)
                      GpsTrafficLightBadge(
                        status: state.accuracyStatus,
                        accuracyMetros: state.currentPosition?.accuracy,
                      )
                    else
                      _buildModoMapaBadge(state),
                    Row(
                      children: [
                        _buildMetodoBadge(state.metodoCapturaEfectivo),
                        const SizedBox(width: 8),
                        Text(
                          '${state.vertices.length} pts',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: SIAAColors.neutral700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // ─── Banner de advertencia offline en modo mapa (AC-04) ─
              if (state.modoCaptura == ModoCapturaEditor.mapa)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  color: const Color(0xFFFEF3C7), // Amber 100
                  child: Row(
                    children: const [
                      Icon(Icons.layers_outlined, size: 16, color: Color(0xFFB45309)),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Modo Toque: Toque en el lienzo para añadir vértices. En ausencia de red se utilizan capas satelitales en caché local.',
                          style: TextStyle(fontSize: 11, color: Color(0xFF92400E)),
                        ),
                      ),
                    ],
                  ),
                ),

              // ─── Área de visualización interactiva del mapa / polígono ───────────
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final size = Size(constraints.maxWidth, constraints.maxHeight);
                    final fallbackCenter = state.currentPosition != null
                        ? [state.currentPosition!.longitude, state.currentPosition!.latitude]
                        : [-74.08175, 4.60971];
                    final bb = _BoundingBox.fromPoints(state.vertices, fallbackCenter: fallbackCenter);

                    return GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTapUp: (details) {
                        if (state.modoCaptura == ModoCapturaEditor.mapa && !state.isClosed) {
                          const padding = 40.0;
                          final coords = bb.fromCanvas(details.localPosition, size, padding);
                          context.read<GeoEditorBloc>().add(
                                ToqueEnMapaRequested(
                                  longitud: coords[0],
                                  latitud: coords[1],
                                ),
                              );
                        }
                      },
                      child: Container(
                        color: state.modoCaptura == ModoCapturaEditor.mapa
                            ? const Color(0xFF0F172A) // Satelital Dark
                            : SIAAColors.backgroundLight,
                        child: CustomPaint(
                          painter: _PolygonPreviewPainter(
                            vertices: state.vertices,
                            taggedVertices: state.verticesEtiquetados,
                            isClosed: state.isClosed,
                            isMapMode: state.modoCaptura == ModoCapturaEditor.mapa,
                            boundingBox: bb,
                          ),
                          child: const SizedBox.expand(),
                        ),
                      ),
                    );
                  },
                ),
              ),

              // ─── Tarjeta de métricas cartográficas ─────────────
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 4,
                      offset: Offset(0, -2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _MetricaItem(
                          label: 'Área estimada (AC-06)',
                          valor: '${state.areaCalculadaM2.toStringAsFixed(1)} m²',
                          icono: Icons.crop_square,
                          color: SIAAColors.primary500,
                        ),
                        _MetricaItem(
                          label: 'Perímetro',
                          valor: '${state.perimetroMetros.toStringAsFixed(1)} m',
                          icono: Icons.linear_scale,
                          color: SIAAColors.neutral700,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // ─── Botonera de acciones ──────────────────────
                    Row(
                      children: [
                        // AC-05: Deshacer último vértice
                        Expanded(
                          flex: 1,
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.undo, size: 18),
                            label: const Text('Deshacer'),
                            onPressed: state.canUndo
                                ? () => context.read<GeoEditorBloc>().add(const DeshacerVerticeRequested())
                                : null,
                          ),
                        ),
                        const SizedBox(width: 8),

                        // AC-01 (GPS) o Instrucción (Mapa)
                        if (state.modoCaptura == ModoCapturaEditor.recorrido)
                          Expanded(
                            flex: 2,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: SIAAColors.primary500,
                                foregroundColor: Colors.white,
                              ),
                              icon: state.status == GeoEditorStatus.capturing
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Icon(Icons.add_location_alt, size: 18),
                              label: Text(
                                state.status == GeoEditorStatus.capturing
                                    ? 'Muestreando...'
                                    : 'Capturar Vértice',
                              ),
                              onPressed: state.canCapture
                                  ? () => context.read<GeoEditorBloc>().add(const CapturarVerticeRequested())
                                  : null,
                            ),
                          )
                        else
                          Expanded(
                            flex: 2,
                            child: Container(
                              height: 48,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: const Color(0xFFEFF6FF),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: SIAAColors.primary200),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: const [
                                  Icon(Icons.touch_app, size: 18, color: SIAAColors.primary600),
                                  SizedBox(width: 6),
                                  Text(
                                    'Toque mapa para marcar',
                                    style: TextStyle(
                                      color: SIAAColors.primary700,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Cierre y guardado
                    Row(
                      children: [
                        // AC-06: Cerrar polígono
                        if (!state.isClosed)
                          Expanded(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: SIAAColors.neutral800,
                                foregroundColor: Colors.white,
                              ),
                              icon: const Icon(Icons.check_circle_outline, size: 18),
                              label: const Text('Cerrar Polígono'),
                              onPressed: state.canClose
                                  ? () => context.read<GeoEditorBloc>().add(const CerrarPoligonoRequested())
                                  : null,
                            ),
                          ),

                        // AC-07: Guardar en el backend
                        if (state.isClosed) ...[
                          Expanded(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: SIAAColors.asistenciaPresente,
                                foregroundColor: Colors.white,
                              ),
                              icon: state.status == GeoEditorStatus.saving
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Icon(Icons.cloud_upload, size: 18),
                              label: Text(
                                state.status == GeoEditorStatus.saving
                                    ? 'Guardando...'
                                    : 'Guardar Geometría',
                              ),
                              onPressed: state.status != GeoEditorStatus.saving
                                  ? () => context.read<GeoEditorBloc>().add(
                                        GuardarGeometriaBackendRequested(espacioId: espacioId),
                                      )
                                  : null,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildModoMapaBadge(GeoEditorState state) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(Icons.map, size: 14, color: Colors.cyanAccent),
          SizedBox(width: 6),
          Text(
            'Mapa Interactivo',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.cyanAccent,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetodoBadge(String metodo) {
    Color bg;
    Color fg;
    switch (metodo) {
      case 'TOQUE_MAPA':
        bg = const Color(0xFFFEF3C7);
        fg = const Color(0xFFB45309);
        break;
      case 'MIXTO':
        bg = const Color(0xFFF3E8FF);
        fg = const Color(0xFF7E22CE);
        break;
      default:
        bg = const Color(0xFFEFF6FF);
        fg = const Color(0xFF1D4ED8);
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        metodo,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: fg),
      ),
    );
  }

  void _confirmarReinicio(BuildContext context) {
    showDialog(
      context: context,
      builder: (dlgContext) => AlertDialog(
        title: const Text('¿Reiniciar polígono?'),
        content: const Text('Se descartarán todos los vértices capturados.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dlgContext).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: SIAAColors.asistenciaAusente),
            onPressed: () {
              Navigator.of(dlgContext).pop();
              context.read<GeoEditorBloc>().add(const LimpiarVerticesRequested());
            },
            child: const Text('Reiniciar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class _MetricaItem extends StatelessWidget {
  final String label;
  final String valor;
  final IconData icono;
  final Color color;

  const _MetricaItem({
    required this.label,
    required this.valor,
    required this.icono,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icono, color: color, size: 24),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 11, color: SIAAColors.neutral500)),
            Text(valor, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ],
    );
  }
}

/// BoundingBox geográfico con utilidades de proyección bidireccional entre coordenadas y canvas.
class _BoundingBox {
  final double minX;
  final double maxX;
  final double minY;
  final double maxY;

  _BoundingBox({
    required this.minX,
    required this.maxX,
    required this.minY,
    required this.maxY,
  });

  factory _BoundingBox.fromPoints(
    List<List<double>> points, {
    List<double>? fallbackCenter,
  }) {
    if (points.isEmpty) {
      final centerLon = fallbackCenter != null ? fallbackCenter[0] : -74.08175;
      final centerLat = fallbackCenter != null ? fallbackCenter[1] : 4.60971;
      const span = 0.0008; // ~80-90 metros
      return _BoundingBox(
        minX: centerLon - span / 2,
        maxX: centerLon + span / 2,
        minY: centerLat - span / 2,
        maxY: centerLat + span / 2,
      );
    }

    double minX = points.first[0], maxX = points.first[0];
    double minY = points.first[1], maxY = points.first[1];
    for (final p in points) {
      if (p[0] < minX) minX = p[0];
      if (p[0] > maxX) maxX = p[0];
      if (p[1] < minY) minY = p[1];
      if (p[1] > maxY) maxY = p[1];
    }

    // Asegurar margen mínimo si es un solo punto o puntos muy cercanos
    final dx = maxX - minX;
    final dy = maxY - minY;
    const minSpan = 0.0005;
    if (dx < minSpan) {
      final pad = (minSpan - dx) / 2;
      minX -= pad;
      maxX += pad;
    }
    if (dy < minSpan) {
      final pad = (minSpan - dy) / 2;
      minY -= pad;
      maxY += pad;
    }

    return _BoundingBox(minX: minX, maxX: maxX, minY: minY, maxY: maxY);
  }

  Offset toCanvas(List<double> v, Size size, double padding) {
    final availableW = size.width - 2 * padding;
    final availableH = size.height - 2 * padding;
    final dx = maxX - minX;
    final dy = maxY - minY;
    final scale = (dx > 0 && dy > 0)
        ? (availableW / dx < availableH / dy ? availableW / dx : availableH / dy)
        : 1.0;
    final x = padding + (v[0] - minX) * scale;
    final y = size.height - (padding + (v[1] - minY) * scale);
    return Offset(x, y);
  }

  List<double> fromCanvas(Offset offset, Size size, double padding) {
    final availableW = size.width - 2 * padding;
    final availableH = size.height - 2 * padding;
    final dx = maxX - minX;
    final dy = maxY - minY;
    final scale = (dx > 0 && dy > 0)
        ? (availableW / dx < availableH / dy ? availableW / dx : availableH / dy)
        : 1.0;
    final lon = minX + (offset.dx - padding) / scale;
    final lat = minY + (size.height - padding - offset.dy) / scale;
    return [lon, lat];
  }
}

/// Canvas interactivo para dibujar la forma del polígono normalizado o sobre mapa satelital.
class _PolygonPreviewPainter extends CustomPainter {
  final List<List<double>> vertices;
  final List<TaggedVertex> taggedVertices;
  final bool isClosed;
  final bool isMapMode;
  final _BoundingBox boundingBox;

  _PolygonPreviewPainter({
    required this.vertices,
    required this.taggedVertices,
    required this.isClosed,
    required this.isMapMode,
    required this.boundingBox,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const padding = 40.0;

    // Si está en modo mapa, dibujamos una retícula sutil de cuadrícula satelital (AC-04)
    if (isMapMode) {
      final gridPaint = Paint()
        ..color = Colors.white.withOpacity(0.08)
        ..strokeWidth = 1.0;

      for (double x = 0; x < size.width; x += 50) {
        canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
      }
      for (double y = 0; y < size.height; y += 50) {
        canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
      }
    }

    if (vertices.isEmpty) {
      final mensaje = isMapMode
          ? 'MODO MAPA SATELITAL\nToca en cualquier punto de la pantalla para\nposicionar los vértices del espacio (AC-01).'
          : 'MODO RECORRIDO PERIMETRAL\nPárese en una esquina del aula y presione\n"Capturar Vértice" para iniciar el recorrido.';

      final textPainter = TextPainter(
        text: TextSpan(
          text: mensaje,
          style: TextStyle(
            color: isMapMode ? Colors.cyanAccent.withOpacity(0.8) : SIAAColors.neutral400,
            fontSize: 13,
            height: 1.4,
          ),
        ),
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: size.width - 40);
      textPainter.paint(
        canvas,
        Offset((size.width - textPainter.width) / 2, size.height / 2 - 20),
      );
      return;
    }

    final points = vertices.map((v) => boundingBox.toCanvas(v, size, padding)).toList();

    // Relleno si está cerrado
    if (isClosed && points.length >= 3) {
      final fillPaint = Paint()
        ..color = (isMapMode ? Colors.cyanAccent : SIAAColors.primary500).withOpacity(0.18)
        ..style = PaintingStyle.fill;
      final path = Path()..moveTo(points.first.dx, points.first.dy);
      for (int i = 1; i < points.length; i++) {
        path.lineTo(points[i].dx, points[i].dy);
      }
      path.close();
      canvas.drawPath(path, fillPaint);
    }

    // Trazar aristas
    final strokePaint = Paint()
      ..color = isMapMode ? Colors.cyanAccent : SIAAColors.primary500
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < points.length - 1; i++) {
      canvas.drawLine(points[i], points[i + 1], strokePaint);
    }

    // Dibujar vértices con numeración y distinción de origen (GPS vs Toque)
    for (int i = 0; i < points.length; i++) {
      final isToque = i < taggedVertices.length &&
          taggedVertices[i].origen == OrigenVertice.toqueMapa;

      final dotColor = isToque
          ? const Color(0xFFF59E0B) // Amber para toque
          : (isMapMode ? const Color(0xFF06B6D4) : SIAAColors.primary600); // Azul/Cyan para GPS

      final dotPaint = Paint()
        ..color = dotColor
        ..style = PaintingStyle.fill;

      canvas.drawCircle(points[i], 7.5, dotPaint);
      canvas.drawCircle(
        points[i],
        7.5,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );

      final labelPainter = TextPainter(
        text: TextSpan(
          text: '${i + 1}',
          style: TextStyle(
            color: isMapMode ? Colors.white : SIAAColors.neutral700,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      labelPainter.paint(canvas, points[i] + const Offset(9, -8));
    }
  }

  @override
  bool shouldRepaint(covariant _PolygonPreviewPainter oldDelegate) {
    return oldDelegate.vertices.length != vertices.length ||
        oldDelegate.isClosed != isClosed ||
        oldDelegate.isMapMode != isMapMode;
  }
}
