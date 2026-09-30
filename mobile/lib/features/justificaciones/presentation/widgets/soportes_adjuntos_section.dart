// soportes_adjuntos_section.dart — Botones de captura y lista de soportes adjuntos
import 'package:flutter/material.dart';

import '../../data/services/soporte_picker_service.dart';
import '../../domain/models/soporte_adjunto.dart';

class SoportesAdjuntosSection extends StatelessWidget {
  final List<SoporteAdjunto> soportes;
  final bool puedeAdjuntar;
  final bool puedeQuitar;
  final ValueChanged<OrigenSoporte> onAdjuntar;
  final ValueChanged<int> onQuitar;

  const SoportesAdjuntosSection({
    super.key,
    required this.soportes,
    required this.puedeAdjuntar,
    required this.puedeQuitar,
    required this.onAdjuntar,
    required this.onQuitar,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'JPG, PNG o PDF · máximo 10 MB cada uno · hasta '
          '${ReglasSoporte.maxArchivos} archivos',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _boton(Icons.photo_camera_outlined, 'Cámara', OrigenSoporte.camara),
            _boton(Icons.image_outlined, 'Galería', OrigenSoporte.galeria),
            _boton(Icons.picture_as_pdf_outlined, 'PDF', OrigenSoporte.pdf),
          ],
        ),
        const SizedBox(height: 8),
        for (var i = 0; i < soportes.length; i++) _tile(i, soportes[i]),
      ],
    );
  }

  Widget _boton(IconData icono, String etiqueta, OrigenSoporte origen) {
    return OutlinedButton.icon(
      onPressed: puedeAdjuntar ? () => onAdjuntar(origen) : null,
      icon: Icon(icono, size: 18),
      label: Text(etiqueta),
    );
  }

  Widget _tile(int indice, SoporteAdjunto soporte) {
    return Card(
      margin: const EdgeInsets.only(top: 6),
      child: ListTile(
        dense: true,
        leading: Icon(
          soporte.esPdf ? Icons.picture_as_pdf : Icons.image,
          color: soporte.esPdf ? Colors.red.shade700 : Colors.blue.shade700,
        ),
        title: Text(soporte.nombre, overflow: TextOverflow.ellipsis),
        subtitle: Text(formatearTamano(soporte.tamano)),
        trailing: IconButton(
          icon: const Icon(Icons.close),
          tooltip: 'Quitar soporte',
          onPressed: puedeQuitar ? () => onQuitar(indice) : null,
        ),
      ),
    );
  }
}
