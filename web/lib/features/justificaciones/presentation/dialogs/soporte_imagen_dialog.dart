import 'package:flutter/material.dart';

import '../../../../core/download/descargador_archivos.dart';
import '../../../../core/network/archivo_binario.dart';

/// Vista previa de un soporte de imagen ya descargado.
class SoporteImagenDialog extends StatelessWidget {
  final ArchivoBinario archivo;
  final String nombre;

  const SoporteImagenDialog({
    super.key,
    required this.archivo,
    required this.nombre,
  });

  static Future<void> show(
    BuildContext context,
    ArchivoBinario archivo,
    String nombre,
  ) => showDialog<void>(
    context: context,
    builder: (_) => SoporteImagenDialog(archivo: archivo, nombre: nombre),
  );

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(nombre, overflow: TextOverflow.ellipsis),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900, maxHeight: 640),
        child: InteractiveViewer(
          child: Image.memory(
            archivo.bytes,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) =>
                const Text('No se pudo mostrar la imagen.'),
          ),
        ),
      ),
      actions: [
        TextButton.icon(
          onPressed: () =>
              descargarArchivo(archivo.bytes, nombre, archivo.mime),
          icon: const Icon(Icons.download_rounded),
          label: const Text('Descargar'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cerrar'),
        ),
      ],
    );
  }
}
