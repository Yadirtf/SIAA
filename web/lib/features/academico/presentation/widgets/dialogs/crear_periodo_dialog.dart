import 'package:flutter/material.dart';
import 'package:siaa_web/features/academico/data/academico_models.dart';

class CrearPeriodoDialog extends StatefulWidget {
  final PeriodoModel? existente;
  final Future<void> Function({
    required String codigo,
    required String nombre,
    required String fechaInicio,
    required String fechaFin,
    required String estado,
  }) onGuardar;

  const CrearPeriodoDialog({
    super.key,
    this.existente,
    required this.onGuardar,
  });

  static Future<void> mostrar(
    BuildContext context, {
    PeriodoModel? existente,
    required Future<void> Function({
      required String codigo,
      required String nombre,
      required String fechaInicio,
      required String fechaFin,
      required String estado,
    }) onGuardar,
  }) {
    return showDialog(
      context: context,
      builder: (_) => CrearPeriodoDialog(
        existente: existente,
        onGuardar: onGuardar,
      ),
    );
  }

  @override
  State<CrearPeriodoDialog> createState() => _CrearPeriodoDialogState();
}

class _CrearPeriodoDialogState extends State<CrearPeriodoDialog> {
  late final TextEditingController _codigoCtrl;
  late final TextEditingController _nombreCtrl;
  late final TextEditingController _fIniCtrl;
  late final TextEditingController _fFinCtrl;
  late String _estadoSeleccionado;

  @override
  void initState() {
    super.initState();
    _codigoCtrl = TextEditingController(text: widget.existente?.codigo ?? '');
    _nombreCtrl = TextEditingController(text: widget.existente?.nombre ?? '');
    _fIniCtrl = TextEditingController(text: widget.existente?.fechaInicio ?? '');
    _fFinCtrl = TextEditingController(text: widget.existente?.fechaFin ?? '');
    _estadoSeleccionado = widget.existente?.estado ?? 'PLANEACION';
  }

  @override
  void dispose() {
    _codigoCtrl.dispose();
    _nombreCtrl.dispose();
    _fIniCtrl.dispose();
    _fFinCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final esEdicion = widget.existente != null;

    return AlertDialog(
      title: Text(esEdicion ? 'Editar Periodo' : 'Nuevo Periodo Académico'),
      content: SizedBox(
        width: 460,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _codigoCtrl,
                decoration: const InputDecoration(
                  labelText: 'Código (ej. 2026-2)*',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _nombreCtrl,
                decoration: const InputDecoration(
                  labelText: 'Nombre del Periodo*',
                  border: OutlineInputBorder(),
                ),
              ),
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
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _estadoSeleccionado,
                decoration: const InputDecoration(
                  labelText: 'Estado',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'PLANEACION', child: Text('Planeación')),
                  DropdownMenuItem(value: 'ACTIVO', child: Text('Activo')),
                  DropdownMenuItem(value: 'CERRADO', child: Text('Cerrado')),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => _estadoSeleccionado = val);
                },
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
            if (_codigoCtrl.text.trim().isEmpty ||
                _nombreCtrl.text.trim().isEmpty ||
                _fIniCtrl.text.trim().isEmpty ||
                _fFinCtrl.text.trim().isEmpty) {
              return;
            }
            Navigator.of(context).pop();
            await widget.onGuardar(
              codigo: _codigoCtrl.text.trim(),
              nombre: _nombreCtrl.text.trim(),
              fechaInicio: _fIniCtrl.text.trim(),
              fechaFin: _fFinCtrl.text.trim(),
              estado: _estadoSeleccionado,
            );
          },
          child: Text(esEdicion ? 'Actualizar' : 'Crear Periodo'),
        ),
      ],
    );
  }
}
