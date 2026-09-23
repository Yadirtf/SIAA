import 'package:flutter/material.dart';

class EstructuraHeader extends StatelessWidget {
  final int activeLevel;
  final VoidCallback onCrearElemento;

  const EstructuraHeader({
    super.key,
    required this.activeLevel,
    required this.onCrearElemento,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Estructura Académica (US-ACA-01 AC-04)',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Jerarquía institucional: Facultad → Programa → Asignatura → Grupos',
              style: TextStyle(color: Colors.black54),
            ),
          ],
        ),
        FilledButton.icon(
          onPressed: onCrearElemento,
          icon: const Icon(Icons.add),
          label: Text(activeLevel == 0
              ? 'Nueva Facultad'
              : activeLevel == 1
                  ? 'Nuevo Programa'
                  : activeLevel == 2
                      ? 'Nueva Asignatura'
                      : 'Nuevo Grupo'),
        ),
      ],
    );
  }
}
