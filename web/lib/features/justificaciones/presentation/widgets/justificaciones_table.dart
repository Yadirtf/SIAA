import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/formatos.dart';
import '../../data/models/justificacion_catalogos.dart';
import '../../data/models/justificacion_model.dart';
import 'justificacion_estado_badge.dart';

/// Tabla de la bandeja: sesión, docente, tipo, estado y soportes.
class JustificacionesTable extends StatelessWidget {
  final List<JustificacionModel> justificaciones;
  final String Function(String docenteId) nombreDocente;
  final ValueChanged<JustificacionModel> onVer;

  const JustificacionesTable({
    super.key,
    required this.justificaciones,
    required this.nombreDocente,
    required this.onVer,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(AppColors.surfaceMuted),
          headingTextStyle: AppTextStyles.label,
          showCheckboxColumn: false,
          columns: const [
            DataColumn(label: Text('Fecha sesión')),
            DataColumn(label: Text('Sesión')),
            DataColumn(label: Text('Docente')),
            DataColumn(label: Text('Tipo')),
            DataColumn(label: Text('Estado')),
            DataColumn(label: Text('Soportes'), numeric: true),
            DataColumn(label: Text('Radicada')),
            DataColumn(label: Text('')),
          ],
          rows: justificaciones.map(_fila).toList(),
        ),
      ),
    );
  }

  DataRow _fila(JustificacionModel j) {
    return DataRow(
      onSelectChanged: (_) => onVer(j),
      cells: [
        DataCell(Text(j.fechaSesion.isEmpty ? '—' : j.fechaSesion)),
        DataCell(
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 240),
            child: Text(
              j.nombreSesion ?? j.sesionId,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        DataCell(
          Text(
            nombreDocente(j.docenteId),
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        DataCell(Text(JustificacionCatalogos.etiquetaTipo(j.tipo))),
        DataCell(JustificacionEstadoBadge(estado: j.estado)),
        DataCell(Text('${j.adjuntos.length}')),
        DataCell(Text(Formatos.fechaHora(j.creadoEn))),
        DataCell(
          TextButton.icon(
            onPressed: () => onVer(j),
            icon: const Icon(Icons.visibility_outlined, size: 18),
            label: const Text('Ver'),
          ),
        ),
      ],
    );
  }
}
