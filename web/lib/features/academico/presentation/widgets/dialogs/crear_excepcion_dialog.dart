import 'package:flutter/material.dart';

class CrearExcepcionDialog extends StatefulWidget {
  final Future<void> Function({
    required String nombre,
    required String tipo,
    required String ambito,
    String? ambitoId,
    required String fechaInicio,
    required String fechaFin,
  }) onGuardar;

  const CrearExcepcionDialog({super.key, required this.onGuardar});

  static Future<void> mostrar(
    BuildContext context, {
    required Future<void> Function({
      required String nombre,
      required String tipo,
      required String ambito,
      String? ambitoId,
      required String fechaInicio,
      required String fechaFin,
    }) onGuardar,
  }) {
    return showDialog(
      context: context,
      builder: (_) => CrearExcepcionDialog(onGuardar: onGuardar),
    );
  }

  @override
  State<CrearExcepcionDialog> createState() => _CrearExcepcionDialogState();
}

class _CrearExcepcionDialogState extends State<CrearExcepcionDialog> {
  final _nombreCtrl = TextEditingController();
  final _fIniCtrl = TextEditingController();
  final _fFinCtrl = TextEditingController();
  final _ambitoIdCtrl = TextEditingController();
  String _tipo = 'FESTIVO';
  String _ambito = 'GLOBAL';

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _fIniCtrl.dispose();
    _fFinCtrl.dispose();
    _ambitoIdCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Nueva Excepción de Calendario (US-ACA-04)'),
      content: SizedBox(
        width: 440,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _nombreCtrl,
                decoration: const InputDecoration(
                  labelText: 'Nombre / Motivo (ej. Día de la Raza)*',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _tipo,
                decoration: const InputDecoration(
                  labelText: 'Tipo de Excepción',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'FESTIVO', child: Text('Festivo')),
                  DropdownMenuItem(value: 'RECESO', child: Text('Receso Académico')),
                  DropdownMenuItem(
                    value: 'JORNADA_INSTITUCIONAL',
                    child: Text('Jornada Institucional'),
                  ),
                  DropdownMenuItem(value: 'PARO', child: Text('Paro / Cese de Actividades')),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => _tipo = val);
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _ambito,
                decoration: const InputDecoration(
                  labelText: 'Ámbito de Aplicación (AC-01, AC-05)',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'GLOBAL', child: Text('Global (Todo el Campus)')),
                  DropdownMenuItem(value: 'SEDE', child: Text('Por Sede')),
                  DropdownMenuItem(value: 'FACULTAD', child: Text('Por Facultad')),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => _ambito = val);
                },
              ),
              if (_ambito != 'GLOBAL') ...[
                const SizedBox(height: 12),
                TextField(
                  controller: _ambitoIdCtrl,
                  decoration: InputDecoration(
                    labelText: 'ID de la $_ambito*',
                    border: const OutlineInputBorder(),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _fIniCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Fecha Inicio (YYYY-MM-DD)*',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _fFinCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Fecha Fin (YYYY-MM-DD)*',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () async {
            if (_nombreCtrl.text.trim().isEmpty ||
                _fIniCtrl.text.trim().isEmpty ||
                _fFinCtrl.text.trim().isEmpty) {
              return;
            }
            Navigator.of(context).pop();
            await widget.onGuardar(
              nombre: _nombreCtrl.text.trim(),
              tipo: _tipo,
              ambito: _ambito,
              ambitoId: _ambito != 'GLOBAL' ? _ambitoIdCtrl.text.trim() : null,
              fechaInicio: _fIniCtrl.text.trim(),
              fechaFin: _fFinCtrl.text.trim(),
            );
          },
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}
