// soporte_revision_tile.dart — Soporte adjunto: vista previa de imágenes en la app;
// los PDF se descargan desde la consola web (la app no incluye visor de PDF).
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../../core/network/api_error.dart';
import '../../../justificaciones/domain/models/justificacion_model.dart';
import '../../../justificaciones/domain/models/soporte_adjunto.dart';

class SoporteRevisionTile extends StatelessWidget {
  final AdjuntoJustificacion adjunto;
  final Future<Uint8List> Function(String soporteId) descargar;

  const SoporteRevisionTile({
    super.key,
    required this.adjunto,
    required this.descargar,
  });

  bool get _esImagen => adjunto.mime.startsWith('image/');

  Future<void> _abrir(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    if (!_esImagen) {
      messenger.showSnackBar(const SnackBar(
        content: Text('Los soportes PDF se consultan en la consola web SIAA.'),
      ));
      return;
    }
    try {
      final bytes = await descargar(adjunto.id);
      if (!context.mounted) return;
      await showDialog<void>(
        context: context,
        builder: (_) => Dialog(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(child: InteractiveViewer(child: Image.memory(bytes))),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cerrar'),
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(mensajeDeError(e))));
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: Icon(_esImagen ? Icons.image_outlined : Icons.picture_as_pdf),
      title: Text(adjunto.nombre, overflow: TextOverflow.ellipsis),
      subtitle: Text(formatearTamano(adjunto.tamano)),
      trailing:
          Icon(_esImagen ? Icons.visibility_outlined : Icons.info_outline),
      onTap: () => _abrir(context),
    );
  }
}
