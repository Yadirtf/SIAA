import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/hora_12h.dart';
import '../../data/models/sesion_model.dart';
import '../helpers/filtro_sesiones.dart';
import 'acciones_sesion_menu.dart';
import 'estado_sesion_chip.dart';

/// Tabla de sesiones ordenable y paginada: cada fila muestra cuándo, qué,
/// quién y dónde con nombres legibles.
class TablaSesiones extends StatelessWidget {
  static const porPagina = 25;

  final List<SesionModel> sesiones;
  final ColumnaSesion columna;
  final bool ascendente;
  final int pagina;
  final void Function(ColumnaSesion columna, bool ascendente) onOrdenar;
  final ValueChanged<int> onPagina;

  const TablaSesiones({
    super.key,
    required this.sesiones,
    required this.columna,
    required this.ascendente,
    required this.pagina,
    required this.onOrdenar,
    required this.onPagina,
  });

  int get paginas => (sesiones.length / porPagina).ceil().clamp(1, 1 << 20);

  DataColumn _col(String titulo, [ColumnaSesion? c]) => DataColumn(
    label: Text(titulo),
    onSort: c == null ? null : (_, asc) => onOrdenar(c, asc),
  );

  Widget _dosLineas(String arriba, String abajo) => ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 240),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          arriba,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        if (abajo.isNotEmpty)
          Text(
            abajo,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted),
          ),
      ],
    ),
  );

  DataRow _fila(SesionModel s) {
    final cancelada = s.esCancelada && s.motivoCancelacion.isNotEmpty;
    return DataRow(
      cells: [
        DataCell(
          _dosLineas(
            fechaSesion(s.fecha),
            '${hora12hDesdeTexto(s.horaInicio)} - ${hora12hDesdeTexto(s.horaFin)}',
          ),
        ),
        DataCell(_dosLineas(s.asignaturaTexto, s.asignaturaCodigo)),
        DataCell(Text(s.grupoNumero.isEmpty ? s.grupoId : s.grupoNumero)),
        DataCell(
          Text(s.docentesTexto.isEmpty ? 'Por asignar' : s.docentesTexto),
        ),
        DataCell(_dosLineas(s.aulaTexto, s.ubicacionTexto)),
        DataCell(
          cancelada
              ? Tooltip(
                  message: 'Motivo: ${s.motivoCancelacion}',
                  child: EstadoSesionChip(s.estado),
                )
              : EstadoSesionChip(s.estado),
        ),
        DataCell(AccionesSesionMenu(sesion: s)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final inicio = pagina * porPagina;
    final visibles = sesiones.skip(inicio).take(porPagina).toList();
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  sortColumnIndex: columna.index,
                  sortAscending: ascendente,
                  columnSpacing: 28,
                  dataRowMinHeight: 52,
                  dataRowMaxHeight: 60,
                  headingTextStyle: AppTextStyles.bodySmall.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  columns: [
                    _col('Fecha y hora', ColumnaSesion.fecha),
                    _col('Asignatura', ColumnaSesion.asignatura),
                    _col('Grupo', ColumnaSesion.grupo),
                    _col('Docente', ColumnaSesion.docente),
                    _col('Aula', ColumnaSesion.aula),
                    _col('Estado', ColumnaSesion.estado),
                    _col('Acciones'),
                  ],
                  rows: [for (final s in visibles) _fila(s)],
                ),
              ),
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Row(
              children: [
                Text(
                  'Mostrando ${inicio + 1}-${inicio + visibles.length} '
                  'de ${sesiones.length} sesiones',
                  style: AppTextStyles.bodySmall,
                ),
                const Spacer(),
                IconButton(
                  tooltip: 'Página anterior',
                  icon: const Icon(Icons.chevron_left_rounded),
                  onPressed: pagina > 0 ? () => onPagina(pagina - 1) : null,
                ),
                Text('Página ${pagina + 1} de $paginas'),
                IconButton(
                  tooltip: 'Página siguiente',
                  icon: const Icon(Icons.chevron_right_rounded),
                  onPressed: pagina + 1 < paginas
                      ? () => onPagina(pagina + 1)
                      : null,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
