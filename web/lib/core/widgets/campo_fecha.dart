import 'package:flutter/material.dart';

/// Campo de solo lectura que abre un selector de fecha y entrega
/// `AAAA-MM-DD` (o null al limpiarlo).
class CampoFecha extends StatelessWidget {
  final String etiqueta;
  final String? valor;
  final ValueChanged<String?> onCambio;
  final double ancho;

  const CampoFecha({
    super.key,
    required this.etiqueta,
    required this.valor,
    required this.onCambio,
    this.ancho = 170,
  });

  static String formatear(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  Future<void> _elegir(BuildContext context) async {
    final inicial = DateTime.tryParse(valor ?? '') ?? DateTime.now();
    final fecha = await showDatePicker(
      context: context,
      initialDate: inicial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (fecha != null) onCambio(formatear(fecha));
  }

  @override
  Widget build(BuildContext context) {
    final vacio = valor == null || valor!.isEmpty;
    return SizedBox(
      width: ancho,
      child: InkWell(
        onTap: () => _elegir(context),
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: etiqueta,
            border: const OutlineInputBorder(),
            isDense: true,
            suffixIcon: vacio
                ? const Icon(Icons.calendar_today_rounded, size: 18)
                : IconButton(
                    tooltip: 'Limpiar $etiqueta',
                    icon: const Icon(Icons.clear_rounded, size: 18),
                    onPressed: () => onCambio(null),
                  ),
          ),
          child: Text(vacio ? 'AAAA-MM-DD' : valor!),
        ),
      ),
    );
  }
}
