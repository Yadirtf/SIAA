import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Selector de nivel jerárquico para el visualizador de parámetros efectivos.
/// US-PAR-02: permite elegir el ámbito y ver qué valor prevalece para cada clave.
class AmbitoSelector extends StatefulWidget {
  final void Function(AmbitoSeleccion seleccion) onChanged;
  final AmbitoSeleccion seleccionActual;

  const AmbitoSelector({
    super.key,
    required this.onChanged,
    required this.seleccionActual,
  });

  @override
  State<AmbitoSelector> createState() => _AmbitoSelectorState();
}

class _AmbitoSelectorState extends State<AmbitoSelector> {
  late String _nivel;
  final _idCtrl = TextEditingController();

  final _niveles = const [
    ('GLOBAL', 'Global (sistema)'),
    ('SEDE', 'Sede'),
    ('FACULTAD', 'Facultad'),
    ('BLOQUE', 'Bloque'),
    ('AULA', 'Aula'),
  ];

  @override
  void initState() {
    super.initState();
    _nivel = widget.seleccionActual.nivel;
    _idCtrl.text = widget.seleccionActual.nivelId;
  }

  @override
  void dispose() {
    _idCtrl.dispose();
    super.dispose();
  }

  bool get _needsId => _nivel != 'GLOBAL';

  void _emit() {
    widget.onChanged(
      AmbitoSeleccion(nivel: _nivel, nivelId: _idCtrl.text.trim()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          // Selector de nivel
          Expanded(
            flex: 2,
            child: DropdownButtonFormField<String>(
              value: _nivel,
              decoration: InputDecoration(
                labelText: 'Nivel jerárquico',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                isDense: true,
              ),
              items: _niveles
                  .map(
                    (n) => DropdownMenuItem(
                      value: n.$1,
                      child: Text(n.$2, style: const TextStyle(fontSize: 13)),
                    ),
                  )
                  .toList(),
              onChanged: (v) {
                setState(() {
                  _nivel = v ?? 'GLOBAL';
                  if (!_needsId) _idCtrl.clear();
                });
              },
            ),
          ),
          const SizedBox(width: 12),

          // ID del ámbito (cuando no es GLOBAL)
          Expanded(
            flex: 3,
            child: AnimatedOpacity(
              opacity: _needsId ? 1 : 0.35,
              duration: const Duration(milliseconds: 200),
              child: TextField(
                controller: _idCtrl,
                enabled: _needsId,
                style: const TextStyle(fontSize: 13),
                decoration: InputDecoration(
                  labelText: 'ID del ámbito',
                  hintText: _needsId ? 'Ej: sede-001' : 'No aplica',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  isDense: true,
                ),
                onSubmitted: (_) => _emit(),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Botón resolver
          FilledButton.icon(
            onPressed: _emit,
            icon: const Icon(Icons.auto_fix_high_rounded, size: 16),
            label: const Text('Resolver'),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primaryAccent,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              textStyle: const TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

/// Modelo simple para la selección de ámbito en el editor web.
class AmbitoSeleccion {
  final String nivel;
  final String nivelId;

  const AmbitoSeleccion({required this.nivel, required this.nivelId});

  String? get sedeId => nivel == 'SEDE' ? nivelId : null;
  String? get facultadId => nivel == 'FACULTAD' ? nivelId : null;
  String? get bloqueId => nivel == 'BLOQUE' ? nivelId : null;
  String? get espacioId => nivel == 'AULA' ? nivelId : null;

  bool get esGlobal => nivel == 'GLOBAL';
}
