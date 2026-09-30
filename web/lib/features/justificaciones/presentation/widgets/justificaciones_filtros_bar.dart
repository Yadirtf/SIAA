import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/campo_fecha.dart';
import '../../data/models/justificacion_catalogos.dart';
import '../../data/models/justificaciones_filtro.dart';

/// Filtros de la bandeja: estado, tipo de novedad y rango de fechas.
class JustificacionesFiltrosBar extends StatelessWidget {
  final JustificacionesFiltro filtro;
  final ValueChanged<JustificacionesFiltro> onFiltrar;
  final VoidCallback onRecargar;

  const JustificacionesFiltrosBar({
    super.key,
    required this.filtro,
    required this.onFiltrar,
    required this.onRecargar,
  });

  void _aplicar(JustificacionesFiltro f) => onFiltrar(f.copyWith(pagina: 1));

  Widget _selector({
    required String etiqueta,
    required String? valor,
    required Map<String, String> opciones,
    required ValueChanged<String?> onCambio,
  }) {
    return SizedBox(
      width: 200,
      child: DropdownButtonFormField<String?>(
        value: opciones.containsKey(valor) ? valor : null,
        isDense: true,
        isExpanded: true,
        decoration: InputDecoration(
          labelText: etiqueta,
          border: const OutlineInputBorder(),
          isDense: true,
        ),
        items: [
          const DropdownMenuItem<String?>(child: Text('Todos')),
          ...opciones.entries.map(
            (e) =>
                DropdownMenuItem<String?>(value: e.key, child: Text(e.value)),
          ),
        ],
        onChanged: onCambio,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
            etiqueta: 'Estado',
            valor: f.estado,
            opciones: JustificacionCatalogos.estados,
            onCambio: (v) => _aplicar(f.copyWith(estado: () => v)),
          ),
          _selector(
            etiqueta: 'Tipo de novedad',
            valor: f.tipo,
            opciones: JustificacionCatalogos.tipos,
            onCambio: (v) => _aplicar(f.copyWith(tipo: () => v)),
          ),
          CampoFecha(
            etiqueta: 'Sesión desde',
            valor: f.desde,
            onCambio: (v) => _aplicar(f.copyWith(desde: () => v)),
          ),
          CampoFecha(
            etiqueta: 'Sesión hasta',
            valor: f.hasta,
            onCambio: (v) => _aplicar(f.copyWith(hasta: () => v)),
          ),
          IconButton(
            tooltip: 'Recargar',
            onPressed: onRecargar,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
    );
  }
}
