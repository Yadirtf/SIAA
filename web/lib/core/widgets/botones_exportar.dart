import 'package:flutter/material.dart';

/// Botones "Exportar XLSX" y "Exportar PDF". [exportando] indica el formato
/// en curso (muestra un indicador y deshabilita ambos).
class BotonesExportar extends StatelessWidget {
  final String? exportando;
  final ValueChanged<String> onExportar;
  final bool habilitado;

  const BotonesExportar({
    super.key,
    required this.onExportar,
    this.exportando,
    this.habilitado = true,
  });

  Widget _boton(String formato, IconData icono) {
    final activo = exportando == formato;
    return OutlinedButton.icon(
      onPressed: habilitado && exportando == null
          ? () => onExportar(formato)
          : null,
      icon: activo
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Icon(icono, size: 18),
      label: Text('Exportar ${formato.toUpperCase()}'),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 8,
      children: [
        _boton('xlsx', Icons.table_view_rounded),
        _boton('pdf', Icons.picture_as_pdf_rounded),
      ],
    );
  }
}
