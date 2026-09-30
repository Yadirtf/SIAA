import 'package:flutter/material.dart';

/// Diálogo modal para registrar una nueva Aula / Espacio dentro de un Bloque (US-GEO-01).
class CrearEspacioDialog extends StatefulWidget {
  final String bloqueNombre;
  final List<int> pisosDisponibles;
  final Future<void> Function({
    required String codigo,
    required String nombre,
    required int piso,
    required int capacidad,
    required String tipo,
  }) onGuardar;

  const CrearEspacioDialog({
    super.key,
    required this.bloqueNombre,
    required this.pisosDisponibles,
    required this.onGuardar,
  });

  @override
  State<CrearEspacioDialog> createState() => _CrearEspacioDialogState();
}

class _CrearEspacioDialogState extends State<CrearEspacioDialog> {
  final TextEditingController _codCtrl =
      TextEditingController(text: 'AULA-101');
  final TextEditingController _nomCtrl =
      TextEditingController(text: 'Aula Magistral 101');
  final TextEditingController _capCtrl = TextEditingController(text: '35');
  late int _pisoSeleccionado;
  String _tipoSeleccionado = 'AULA';
  bool _enviando = false;

  @override
  void initState() {
    super.initState();
    _pisoSeleccionado =
        widget.pisosDisponibles.isNotEmpty ? widget.pisosDisponibles.first : 1;
  }

  @override
  void dispose() {
    _codCtrl.dispose();
    _nomCtrl.dispose();
    _capCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final cod = _codCtrl.text.trim();
    final nom = _nomCtrl.text.trim();
    if (cod.isEmpty || nom.isEmpty) return;

    final cap = int.tryParse(_capCtrl.text.trim()) ?? 30;
    setState(() => _enviando = true);
    Navigator.of(context).pop();

    await widget.onGuardar(
      codigo: cod,
      nombre: nom,
      piso: _pisoSeleccionado,
      capacidad: cap,
      tipo: _tipoSeleccionado,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Nueva Aula en ${widget.bloqueNombre}'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _codCtrl,
              decoration:
                  const InputDecoration(labelText: 'Código Aula (ej: A-101)'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _nomCtrl,
              decoration:
                  const InputDecoration(labelText: 'Nombre del Espacio'),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<int>(
                    value: _pisoSeleccionado,
                    decoration: const InputDecoration(labelText: 'Piso'),
                    items: widget.pisosDisponibles
                        .map((p) =>
                            DropdownMenuItem(value: p, child: Text('Piso $p')))
                        .toList(),
                    onChanged: (p) =>
                        setState(() => _pisoSeleccionado = p ?? 1),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _capCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Capacidad'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _tipoSeleccionado,
              decoration: const InputDecoration(labelText: 'Tipo de Espacio'),
              items: const [
                DropdownMenuItem(value: 'AULA', child: Text('Aula Magistral')),
                DropdownMenuItem(
                    value: 'LABORATORIO', child: Text('Laboratorio')),
                DropdownMenuItem(value: 'AUDITORIO', child: Text('Auditorio')),
                DropdownMenuItem(value: 'TALLER', child: Text('Taller')),
                DropdownMenuItem(
                    value: 'OFICINA', child: Text('Oficina / Sala')),
              ],
              onChanged: (t) => setState(() => _tipoSeleccionado = t ?? 'AULA'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _enviando ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _enviando ? null : _submit,
          child: const Text('Crear Aula'),
        ),
      ],
    );
  }
}
