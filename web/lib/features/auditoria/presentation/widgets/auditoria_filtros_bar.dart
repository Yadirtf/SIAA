import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/campo_fecha.dart';
import '../../data/models/filtro_auditoria_model.dart';

/// Filtros de la bitácora: entidad, id, actor, prefijo de acción y fechas.
class AuditoriaFiltrosBar extends StatefulWidget {
  final FiltroAuditoriaModel filtro;
  final ValueChanged<FiltroAuditoriaModel> onFiltrar;
  final VoidCallback onRecargar;

  const AuditoriaFiltrosBar({
    super.key,
    required this.filtro,
    required this.onFiltrar,
    required this.onRecargar,
  });

  @override
  State<AuditoriaFiltrosBar> createState() => _AuditoriaFiltrosBarState();
}

class _AuditoriaFiltrosBarState extends State<AuditoriaFiltrosBar> {
  late final _entidad = TextEditingController(text: widget.filtro.entidad);
  late final _entidadId = TextEditingController(text: widget.filtro.entidadId);
  late final _actorId = TextEditingController(text: widget.filtro.actorId);
  late final _accion = TextEditingController(text: widget.filtro.accion);

  @override
  void dispose() {
    for (final c in [_entidad, _entidadId, _actorId, _accion]) {
      c.dispose();
    }
    super.dispose();
  }

  String? _valor(TextEditingController c) {
    final t = c.text.trim();
    return t.isEmpty ? null : t;
  }

  /// Aplica los textos escritos junto con [base] (fechas) desde la página 1.
  void _buscar([FiltroAuditoriaModel? base]) {
    widget.onFiltrar(
      (base ?? widget.filtro).copyWith(
        entidad: () => _valor(_entidad),
        entidadId: () => _valor(_entidadId),
        actorId: () => _valor(_actorId),
        accion: () => _valor(_accion),
        pagina: 1,
      ),
    );
  }

  Widget _campo(
    TextEditingController c,
    String etiqueta, {
    double ancho = 180,
  }) {
    return SizedBox(
      width: ancho,
      child: TextField(
        controller: c,
        textInputAction: TextInputAction.search,
        onSubmitted: (_) => _buscar(),
        decoration: InputDecoration(
          labelText: etiqueta,
          border: const OutlineInputBorder(),
          isDense: true,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final f = widget.filtro;
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
          _campo(_entidad, 'Entidad'),
          _campo(_entidadId, 'Id de entidad', ancho: 220),
          _campo(_actorId, 'Id del actor', ancho: 220),
          _campo(_accion, 'Acción (prefijo)'),
          CampoFecha(
            etiqueta: 'Desde',
            valor: f.desde,
            onCambio: (v) => _buscar(f.copyWith(desde: () => v)),
          ),
          CampoFecha(
            etiqueta: 'Hasta',
            valor: f.hasta,
            onCambio: (v) => _buscar(f.copyWith(hasta: () => v)),
          ),
          ElevatedButton.icon(
            onPressed: _buscar,
            icon: const Icon(Icons.search_rounded, size: 18),
            label: const Text('Buscar'),
          ),
          IconButton(
            tooltip: 'Recargar',
            onPressed: widget.onRecargar,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
    );
  }
}
