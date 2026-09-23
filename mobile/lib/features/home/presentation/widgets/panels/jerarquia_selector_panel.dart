import 'package:flutter/material.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../geo_editor/data/espacio_repository.dart';
import '../cards/espacio_card_tile.dart';

/// Panel principal de selección jerárquica Sede → Bloque → Aula (US-GEO-01).
class JerarquiaSelectorPanel extends StatelessWidget {
  final bool isDark;
  final List<SedeModel> sedes;
  final SedeModel? sedeSeleccionada;
  final bool cargandoSedes;
  final ValueChanged<SedeModel?> onSedeChanged;
  final VoidCallback onNuevaSede;

  final List<BloqueModel> bloques;
  final BloqueModel? bloqueSeleccionado;
  final bool cargandoBloques;
  final ValueChanged<BloqueModel?> onBloqueChanged;
  final VoidCallback? onNuevoBloque;

  final List<EspacioModel> espacios;
  final bool cargandoEspacios;
  final VoidCallback? onCrearAula;
  final void Function(EspacioModel) onEditarEspacio;

  const JerarquiaSelectorPanel({
    super.key,
    required this.isDark,
    required this.sedes,
    required this.sedeSeleccionada,
    required this.cargandoSedes,
    required this.onSedeChanged,
    required this.onNuevaSede,
    required this.bloques,
    required this.bloqueSeleccionado,
    required this.cargandoBloques,
    required this.onBloqueChanged,
    required this.onNuevoBloque,
    required this.espacios,
    required this.cargandoEspacios,
    required this.onCrearAula,
    required this.onEditarEspacio,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(SIAASpacing.lg),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: SIAAColors.primary200),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 16),
          _buildSedeSelector(),
          const SizedBox(height: 12),
          _buildBloqueSelector(),
          const SizedBox(height: 16),
          _buildAulasHeader(),
          const SizedBox(height: 8),
          _buildAulasList(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: SIAAColors.primary500,
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.account_tree_rounded, color: Colors.white, size: 24),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'Jerarquía Física y Cartografía',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Text(
                'Sede → Bloque → Aula → Polígono GPS (RF-GEO-001)',
                style: TextStyle(fontSize: 12, color: SIAAColors.neutral500),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSedeSelector() {
    return Row(
      children: [
        Expanded(
          child: cargandoSedes
              ? const LinearProgressIndicator()
              : DropdownButtonFormField<SedeModel>(
                  value: sedeSeleccionada,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: '1. Sede Universitaria',
                    prefixIcon: Icon(Icons.apartment_rounded),
                    isDense: true,
                  ),
                  hint: const Text('Seleccionar o crear sede'),
                  items: sedes.map((s) {
                    return DropdownMenuItem(value: s, child: Text('${s.codigo} — ${s.nombre}'));
                  }).toList(),
                  onChanged: onSedeChanged,
                ),
        ),
        const SizedBox(width: 8),
        IconButton.filledTonal(
          icon: const Icon(Icons.add_business_rounded),
          tooltip: 'Nueva Sede',
          onPressed: onNuevaSede,
        ),
      ],
    );
  }

  Widget _buildBloqueSelector() {
    return Row(
      children: [
        Expanded(
          child: cargandoBloques
              ? const LinearProgressIndicator()
              : DropdownButtonFormField<BloqueModel>(
                  value: bloqueSeleccionado,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: '2. Bloque o Edificio',
                    prefixIcon: Icon(Icons.domain_rounded),
                    isDense: true,
                  ),
                  hint: Text(sedeSeleccionada == null
                      ? 'Seleccione una sede primero'
                      : (bloques.isEmpty ? 'Sin bloques en esta sede' : 'Seleccionar bloque')),
                  items: bloques.map((b) {
                    return DropdownMenuItem(value: b, child: Text('${b.codigo} — ${b.nombre}'));
                  }).toList(),
                  onChanged: sedeSeleccionada == null ? null : onBloqueChanged,
                ),
        ),
        const SizedBox(width: 8),
        IconButton.filledTonal(
          icon: const Icon(Icons.add_home_work_rounded),
          tooltip: 'Nuevo Bloque',
          onPressed: onNuevoBloque,
        ),
      ],
    );
  }

  Widget _buildAulasHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          '3. Aulas / Espacios (${espacios.length})',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        FilledButton.icon(
          style: FilledButton.styleFrom(
            visualDensity: VisualDensity.compact,
            backgroundColor: SIAAColors.primary600,
          ),
          icon: const Icon(Icons.add, size: 16),
          label: const Text('Crear Aula'),
          onPressed: onCrearAula,
        ),
      ],
    );
  }

  Widget _buildAulasList() {
    if (cargandoEspacios) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (bloqueSeleccionado == null) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Text(
          'Seleccione o cree una Sede y un Bloque para gestionar sus aulas y delimitar sus perímetros.',
          style: TextStyle(fontSize: 12, color: SIAAColors.neutral600),
        ),
      );
    }
    if (espacios.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: SIAAColors.neutral200),
        ),
        child: Column(
          children: [
            const Icon(Icons.meeting_room_outlined, size: 32, color: SIAAColors.neutral400),
            const SizedBox(height: 6),
            Text(
              'No hay aulas en ${bloqueSeleccionado!.nombre}',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            const Text(
              'Presiona "+ Crear Aula" para registrar un salón y delimitar su polígono GPS.',
              style: TextStyle(fontSize: 11, color: SIAAColors.neutral500),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: espacios.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, idx) {
        final esp = espacios[idx];
        return EspacioCardTile(
          espacio: esp,
          onEditarPoligono: () => onEditarEspacio(esp),
        );
      },
    );
  }
}
