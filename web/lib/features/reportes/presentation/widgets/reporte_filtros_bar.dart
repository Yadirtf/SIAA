import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/campo_fecha.dart';
import '../../data/models/filtro_reporte_model.dart';
import '../bloc/catalogo_reporte_cubit.dart';

/// Filtros del reporte: periodo, facultad, programa y rango de fechas.
class ReporteFiltrosBar extends StatelessWidget {
  final FiltroReporteModel filtro;
  final ValueChanged<FiltroReporteModel> onCambio;
  final VoidCallback onConsultar;
  final bool consultando;

  const ReporteFiltrosBar({
    super.key,
    required this.filtro,
    required this.onCambio,
    required this.onConsultar,
    this.consultando = false,
  });

  Widget _selector({
    required String etiqueta,
    required String? valor,
    required List<(String, String)> opciones,
    required ValueChanged<String?> onCambio,
    String textoVacio = 'Todos',
    double ancho = 220,
  }) {
    final ids = opciones.map((o) => o.$1).toSet();
    return SizedBox(
      width: ancho,
      child: DropdownButtonFormField<String?>(
        value: ids.contains(valor) ? valor : null,
        isDense: true,
        isExpanded: true,
        decoration: InputDecoration(
          labelText: etiqueta,
          border: const OutlineInputBorder(),
          isDense: true,
        ),
        items: [
          DropdownMenuItem<String?>(child: Text(textoVacio)),
          ...opciones.map(
            (o) => DropdownMenuItem<String?>(
              value: o.$1,
              child: Text(o.$2, overflow: TextOverflow.ellipsis),
            ),
          ),
        ],
        onChanged: onCambio,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final catalogo = context.watch<CatalogoReporteCubit>().state;
    final f = filtro;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          _selector(
            etiqueta: 'Periodo académico',
            valor: f.periodoId,
            textoVacio: 'Sin periodo (usar fechas)',
            opciones: catalogo.periodos.map((p) => (p.id, p.nombre)).toList(),
            onCambio: (v) => onCambio(f.copyWith(periodoId: () => v)),
            ancho: 240,
          ),
          _selector(
            etiqueta: 'Facultad',
            valor: f.facultadId,
            textoVacio: 'Todas',
            opciones: catalogo.facultades.map((x) => (x.id, x.nombre)).toList(),
            onCambio: (v) {
              onCambio(f.copyWith(facultadId: () => v, programaId: () => null));
              context.read<CatalogoReporteCubit>().cargarProgramas(v);
            },
          ),
          _selector(
            etiqueta: 'Programa',
            valor: f.programaId,
            opciones: catalogo.programas.map((x) => (x.id, x.nombre)).toList(),
            onCambio: (v) => onCambio(f.copyWith(programaId: () => v)),
          ),
          CampoFecha(
            etiqueta: 'Desde',
            valor: f.desde,
            onCambio: (v) => onCambio(f.copyWith(desde: () => v)),
          ),
          CampoFecha(
            etiqueta: 'Hasta',
            valor: f.hasta,
            onCambio: (v) => onCambio(f.copyWith(hasta: () => v)),
          ),
          ElevatedButton.icon(
            onPressed: consultando ? null : onConsultar,
            icon: const Icon(Icons.search_rounded, size: 18),
            label: const Text('Consultar'),
          ),
        ],
      ),
    );
  }
}
