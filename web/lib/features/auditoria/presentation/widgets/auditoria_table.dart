import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/formatos.dart';
import '../../data/models/entrada_auditoria_model.dart';

/// Tabla de solo lectura de la bitácora; cada fila abre su detalle.
class AuditoriaTable extends StatelessWidget {
  final List<EntradaAuditoriaModel> entradas;
  final ValueChanged<EntradaAuditoriaModel> onVer;

  const AuditoriaTable({
    super.key,
    required this.entradas,
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
            DataColumn(label: Text('Fecha')),
            DataColumn(label: Text('Acción')),
            DataColumn(label: Text('Entidad')),
            DataColumn(label: Text('Id entidad')),
            DataColumn(label: Text('Actor')),
            DataColumn(label: Text('Rol')),
            DataColumn(label: Text('IP')),
            DataColumn(label: Text('')),
          ],
          rows: entradas.map(_fila).toList(),
        ),
      ),
    );
  }

  DataRow _fila(EntradaAuditoriaModel e) {
    return DataRow(
      onSelectChanged: (_) => onVer(e),
      cells: [
        DataCell(Text(Formatos.fechaHoraSegundos(e.creadoEn))),
        DataCell(
          Text(
            e.accion,
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        DataCell(Text(e.entidad)),
        DataCell(
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 200),
            child: Text(e.entidadId, overflow: TextOverflow.ellipsis),
          ),
        ),
        DataCell(Text(e.actor)),
        DataCell(Text(e.rolActivo ?? '—')),
        DataCell(Text(e.ipOrigen ?? '—')),
        DataCell(
          IconButton(
            tooltip: 'Ver detalle',
            onPressed: () => onVer(e),
            icon: const Icon(Icons.visibility_outlined, size: 18),
          ),
        ),
      ],
    );
  }
}
