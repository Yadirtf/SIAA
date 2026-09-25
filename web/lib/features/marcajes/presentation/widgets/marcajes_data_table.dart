// marcajes_data_table.dart — Tabla paginada de marcajes con indicadores de integridad (US-MAR-09, US-MAR-10)
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../domain/models/marcaje_admin_model.dart';

class MarcajesDataTable extends StatelessWidget {
  final List<MarcajeAdminModel> marcajes;
  final ValueChanged<MarcajeAdminModel> onSeleccionar;

  const MarcajesDataTable({
    super.key,
    required this.marcajes,
    required this.onSeleccionar,
  });

  @override
  Widget build(BuildContext context) {
    if (marcajes.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(48.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.inbox_outlined, size: 64, color: Colors.grey),
              SizedBox(height: 12),
              Text(
                'No se encontraron marcajes con los filtros seleccionados',
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

    final dateFormat = DateFormat('yyyy-MM-dd HH:mm:ss');

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(Colors.grey.shade50),
          columns: const [
            DataColumn(label: Text('Fecha / Hora')),
            DataColumn(label: Text('Usuario')),
            DataColumn(label: Text('Sesión / Asignatura')),
            DataColumn(label: Text('Tipo')),
            DataColumn(label: Text('Resultado')),
            DataColumn(label: Text('Origen')),
            DataColumn(label: Text('Integridad')),
            DataColumn(label: Text('Estado')),
            DataColumn(label: Text('Acción')),
          ],
          rows: marcajes.map((m) {
            return DataRow(
              cells: [
                DataCell(Text(dateFormat.format(m.timestampServidor), style: const TextStyle(fontSize: 13))),
                DataCell(Text(m.usuarioId, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
                DataCell(Text(m.asignatura.isNotEmpty ? m.asignatura : m.sesionId, style: const TextStyle(fontSize: 13))),
                DataCell(Text(m.tipo, style: const TextStyle(fontSize: 13))),
                DataCell(_buildResultadoBadge(m)),
                DataCell(Text(m.origen, style: TextStyle(color: Colors.grey.shade700, fontSize: 12))),
                DataCell(_buildIntegridadBadge(m)),
                DataCell(
                  m.anulado
                      ? const Chip(
                          label: Text('ANULADO', style: TextStyle(fontSize: 10, color: Colors.white)),
                          backgroundColor: Colors.grey,
                          visualDensity: VisualDensity.compact,
                        )
                      : const Text('Activo', style: TextStyle(fontSize: 12, color: Colors.green)),
                ),
                DataCell(
                  ElevatedButton.icon(
                    onPressed: () => onSeleccionar(m),
                    icon: const Icon(Icons.edit_note, size: 16),
                    label: const Text('Ajustar', style: TextStyle(fontSize: 12)),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    ),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildResultadoBadge(MarcajeAdminModel m) {
    Color bg;
    Color fg;
    String label = m.resultado;

    if (m.esAceptado) {
      bg = Colors.green.shade50;
      fg = Colors.green.shade800;
    } else if (m.esAusencia) {
      bg = Colors.orange.shade50;
      fg = Colors.orange.shade800;
      label = 'AUSENCIA';
    } else {
      bg = Colors.red.shade50;
      fg = Colors.red.shade800;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: fg.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(color: fg, fontWeight: FontWeight.bold, fontSize: 11),
      ),
    );
  }

  Widget _buildIntegridadBadge(MarcajeAdminModel m) {
    if (!m.tieneAnomalia) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.shield_outlined, size: 16, color: Colors.green.shade700),
          const SizedBox(width: 4),
          const Text('Confiable', style: TextStyle(fontSize: 12, color: Colors.green)),
        ],
      );
    }

    final alerts = <String>[];
    if (m.mockLocation) alerts.add('Mock GPS');
    if (m.rooteado) alerts.add('Root');
    if (m.emulador) alerts.add('Emulador');
    if (m.saltoImposible) alerts.add('Salto >120km/h');

    return Tooltip(
      message: 'Alertas detectadas: ${alerts.join(', ')}',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.red.shade300),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.warning_amber_rounded, size: 14, color: Colors.red),
            const SizedBox(width: 4),
            Text(
              alerts.first,
              style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}
