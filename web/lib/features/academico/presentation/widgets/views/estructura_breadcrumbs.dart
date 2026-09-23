import 'package:flutter/material.dart';
import '../../../data/academico_models.dart';

class EstructuraBreadcrumbs extends StatelessWidget {
  final int activeLevel;
  final FacultadModel? selectedFacultad;
  final ProgramaModel? selectedPrograma;
  final AsignaturaModel? selectedAsignatura;
  final ValueChanged<int> onSelectLevel;

  const EstructuraBreadcrumbs({
    super.key,
    required this.activeLevel,
    this.selectedFacultad,
    this.selectedPrograma,
    this.selectedAsignatura,
    required this.onSelectLevel,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      children: [
        ChoiceChip(
          label: const Text('1. Facultades'),
          selected: activeLevel == 0,
          onSelected: (_) => onSelectLevel(0),
        ),
        if (selectedFacultad != null) ...[
          const Icon(Icons.chevron_right, size: 20, color: Colors.grey),
          ChoiceChip(
            label: Text('2. ${selectedFacultad!.nombre}'),
            selected: activeLevel == 1,
            onSelected: (_) => onSelectLevel(1),
          ),
        ],
        if (selectedPrograma != null) ...[
          const Icon(Icons.chevron_right, size: 20, color: Colors.grey),
          ChoiceChip(
            label: Text('3. ${selectedPrograma!.nombre}'),
            selected: activeLevel == 2,
            onSelected: (_) => onSelectLevel(2),
          ),
        ],
        if (selectedAsignatura != null) ...[
          const Icon(Icons.chevron_right, size: 20, color: Colors.grey),
          ChoiceChip(
            label: Text('4. ${selectedAsignatura!.nombre}'),
            selected: activeLevel == 3,
            onSelected: (_) => onSelectLevel(3),
          ),
        ],
      ],
    );
  }
}
