import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import '../bloc/geo_editor_bloc.dart';
import '../bloc/geo_editor_event.dart';
import '../bloc/geo_editor_state.dart';
import '../widgets/gps_traffic_light_badge.dart';

/// Pantalla interactiva de levantamiento cartográfico perimetral (US-GEO-02, T-GEO-02.5).
/// Cumple AC-01..AC-07:
/// - Muestreo y promedio de lecturas GPS
/// - Semáforo de precisión con bloqueo de botón de captura
/// - Deshacer último vértice
/// - Cierre de polígono con previsualización de área en m²
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
              // ─── Barra superior de estado GPS ─────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                color: SIAAColors.neutral100,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GpsTrafficLightBadge(
                      status: state.accuracyStatus,
                      accuracyMetros: state.currentPosition?.accuracy,
                    ),
                    Text(
                      '${state.vertices.length} vértices',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: SIAAColors.neutral700,
                      ),
                    ),
                  ],
                ),
              ),

              // ─── Área de visualización del polígono ───────────
              Expanded(
                child: Container(
                  color: SIAAColors.backgroundLight,
                  child: CustomPaint(
                    painter: _PolygonPreviewPainter(
                      vertices: state.vertices,
                      isClosed: state.isClosed,
                    ),
                    child: const SizedBox.expand(),
                  ),
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

                        // AC-01, AC-04: Capturar vértice (bloqueado si precisión insuficiente)
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

/// Canvas para dibujar la forma del polígono normalizado en pantalla.
class _PolygonPreviewPainter extends CustomPainter {
  final List<List<double>> vertices;
  final bool isClosed;

  _PolygonPreviewPainter({required this.vertices, required this.isClosed});

  @override
  void paint(Canvas canvas, Size size) {
    if (vertices.isEmpty) {
      final textPainter = TextPainter(
        text: const TextSpan(
          text: 'Párese en una esquina del aula y presione\n"Capturar Vértice" para iniciar el recorrido.',
          style: TextStyle(color: SIAAColors.neutral400, fontSize: 13, height: 1.4),
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

    // Normalizar coordenadas al canvas
    double minX = vertices.first[0], maxX = vertices.first[0];
    double minY = vertices.first[1], maxY = vertices.first[1];
    for (final v in vertices) {
      if (v[0] < minX) minX = v[0];
      if (v[0] > maxX) maxX = v[0];
      if (v[1] < minY) minY = v[1];
      if (v[1] > maxY) maxY = v[1];
    }

    final dx = maxX - minX;
    final dy = maxY - minY;
    final padding = 40.0;
    final availableW = size.width - 2 * padding;
    final availableH = size.height - 2 * padding;

    final scale = (dx > 0 && dy > 0)
        ? (availableW / dx < availableH / dy ? availableW / dx : availableH / dy)
        : 1.0;

    Offset toCanvas(List<double> v) {
      if (dx == 0 && dy == 0) {
        return Offset(size.width / 2, size.height / 2);
      }
      final x = padding + (v[0] - minX) * scale;
      // Invertir Y porque en pantalla el eje Y va hacia abajo y la latitud hacia arriba
      final y = size.height - (padding + (v[1] - minY) * scale);
      return Offset(x, y);
    }

    final points = vertices.map(toCanvas).toList();

    // Relleno si está cerrado
    if (isClosed && points.length >= 3) {
      final fillPaint = Paint()
        ..color = SIAAColors.primary500.withOpacity(0.15)
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
      ..color = SIAAColors.primary500
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < points.length - 1; i++) {
      canvas.drawLine(points[i], points[i + 1], strokePaint);
    }

    // Dibujar vértices con numeración
    final dotPaint = Paint()
      ..color = SIAAColors.primary600
      ..style = PaintingStyle.fill;

    for (int i = 0; i < points.length; i++) {
      canvas.drawCircle(points[i], 7, dotPaint);
      canvas.drawCircle(
        points[i],
        7,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );

      final labelPainter = TextPainter(
        text: TextSpan(
          text: '${i + 1}',
          style: const TextStyle(color: SIAAColors.neutral700, fontSize: 11, fontWeight: FontWeight.bold),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      labelPainter.paint(canvas, points[i] + const Offset(9, -8));
    }
  }

  @override
  bool shouldRepaint(covariant _PolygonPreviewPainter oldDelegate) {
    return oldDelegate.vertices.length != vertices.length || oldDelegate.isClosed != isClosed;
  }
}
