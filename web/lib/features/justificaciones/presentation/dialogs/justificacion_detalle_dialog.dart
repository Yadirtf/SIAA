import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/download/descargador_archivos.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../data/models/adjunto_model.dart';
import '../../data/models/justificacion_catalogos.dart';
import '../../data/models/justificacion_model.dart';
import '../../domain/justificaciones_repository.dart';
import '../bloc/justificacion_detalle_cubit.dart';
import '../widgets/justificacion_acciones.dart';
import '../widgets/justificacion_historial.dart';
import '../widgets/justificacion_resumen.dart';
import '../widgets/justificacion_soportes.dart';
import 'observaciones_dialog.dart';
import 'soporte_imagen_dialog.dart';

/// Detalle de una justificación con soportes, historial y decisiones.
/// Devuelve true si el estado cambió (para recargar la bandeja).
class JustificacionDetalleDialog extends StatefulWidget {
  final bool puedeAprobar;

  const JustificacionDetalleDialog({super.key, required this.puedeAprobar});

  static Future<bool> show(
    BuildContext context, {
    required JustificacionModel justificacion,
    required bool puedeAprobar,
    Map<String, String> nombres = const {},
  }) async {
    final repo = context.read<JustificacionesRepository>();
    final cambio = await showDialog<bool>(
      context: context,
      builder: (_) => BlocProvider(
        create: (_) => JustificacionDetalleCubit(
          repository: repo,
          inicial: justificacion,
          nombres: nombres,
        )..cargar(),
        child: JustificacionDetalleDialog(puedeAprobar: puedeAprobar),
      ),
    );
    return cambio ?? false;
  }

  @override
  State<JustificacionDetalleDialog> createState() =>
      _JustificacionDetalleDialogState();
}

class _JustificacionDetalleDialogState
    extends State<JustificacionDetalleDialog> {
  bool _cambio = false;

  JustificacionDetalleCubit get _cubit =>
      context.read<JustificacionDetalleCubit>();

  Future<void> _ver(AdjuntoModel a) async {
    final archivo = await _cubit.descargarSoporte(a);
    if (archivo == null || !mounted) return;
    if (archivo.esImagen) {
      await SoporteImagenDialog.show(context, archivo, a.nombre);
    } else {
      abrirArchivo(archivo.bytes, archivo.mime);
    }
  }

  Future<void> _descargar(AdjuntoModel a) async {
    final archivo = await _cubit.descargarSoporte(a);
    if (archivo == null) return;
    descargarArchivo(archivo.bytes, a.nombre, archivo.mime);
  }

  Future<void> _decidir(String estado) async {
    final rechazo = estado == JustificacionCatalogos.rechazada;
    String? obs;
    if (estado != JustificacionCatalogos.enRevision) {
      obs = await ObservacionesDialog.show(
        context,
        titulo: rechazo ? 'Rechazar justificación' : 'Aprobar justificación',
        descripcion: rechazo
            ? 'Explique al docente el motivo del rechazo.'
            : 'La ausencia quedará justificada en los reportes de '
                  'cumplimiento.',
        textoConfirmar: rechazo ? 'Rechazar' : 'Aprobar',
        minimo: rechazo ? JustificacionCatalogos.minObservaciones : 0,
      );
      if (obs == null) return;
    }
    final ok = await _cubit.revisar(estado, observaciones: obs);
    if (ok) _cambio = true;
  }

  void _snack(String texto, Color color) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(texto), backgroundColor: color));
  }

  Widget _seccion(String titulo, Widget hijo) => Padding(
    padding: const EdgeInsets.only(top: 20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(titulo, style: AppTextStyles.h3),
        const SizedBox(height: 8),
        hijo,
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<JustificacionDetalleCubit, JustificacionDetalleState>(
      listenWhen: (a, b) =>
          (b.error != null && a.error != b.error) ||
          (b.mensajeExito != null && a.mensajeExito != b.mensajeExito),
      listener: (context, s) {
        if (s.error != null) _snack(s.error!, AppColors.statusDangerText);
        if (s.mensajeExito != null) {
          _snack(s.mensajeExito!, AppColors.statusSuccessText);
        }
      },
      builder: (context, s) {
        final j = s.justificacion;
        return AlertDialog(
          title: const Text('Detalle de la justificación'),
          content: SizedBox(
            width: 820,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (s.procesando) const LinearProgressIndicator(),
                  JustificacionResumen(justificacion: j, nombreDe: s.nombreDe),
                  _seccion(
                    'Soportes',
                    JustificacionSoportes(
                      adjuntos: j.adjuntos,
                      habilitado: !s.procesando,
                      onVer: _ver,
                      onDescargar: _descargar,
                    ),
                  ),
                  _seccion(
                    'Historial',
                    JustificacionHistorial(
                      historial: j.historial,
                      nombreActor: s.nombreDe,
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            if (widget.puedeAprobar)
              JustificacionAcciones(
                estado: j.estado,
                habilitado: !s.procesando,
                onRevision: () => _decidir(JustificacionCatalogos.enRevision),
                onAprobar: () => _decidir(JustificacionCatalogos.aprobada),
                onRechazar: () => _decidir(JustificacionCatalogos.rechazada),
              ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(_cambio),
              child: const Text('Cerrar'),
            ),
          ],
        );
      },
    );
  }
}
