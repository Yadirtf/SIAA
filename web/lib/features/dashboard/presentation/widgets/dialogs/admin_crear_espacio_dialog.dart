import 'package:flutter/material.dart';
import '../../../data/admin_geo_repository.dart';

class AdminCrearEspacioDialog extends StatefulWidget {
  final List<AdminSede> sedes;
  final List<AdminBloque> bloques;
  final void Function({
    required String sedeId,
    String? bloqueId,
    required int piso,
    required String codigo,
    required String nombre,
    required int capacidad,
    required String tipo,
  }) onConfirmar;

  const AdminCrearEspacioDialog({
    super.key,
    required this.sedes,
    required this.bloques,
    required this.onConfirmar,
  });

  static Future<void> mostrar(
    BuildContext context, {
    required List<AdminSede> sedes,
    required List<AdminBloque> bloques,
    required void Function({
      required String sedeId,
      String? bloqueId,
      required int piso,
      required String codigo,
      required String nombre,
      required int capacidad,
      required String tipo,
    }) onConfirmar,
  }) {
    if (sedes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Crea primero una sede para registrar espacios.')),
      );
      return Future.value();
    }
    return showDialog(
      context: context,
      builder: (_) => AdminCrearEspacioDialog(
        sedes: sedes,
        bloques: bloques,
        onConfirmar: onConfirmar,
      ),
    );
  }

  @override
  State<AdminCrearEspacioDialog> createState() => _AdminCrearEspacioDialogState();
}

class _AdminCrearEspacioDialogState extends State<AdminCrearEspacioDialog> {
  late String _selectedSedeId;
  String? _selectedBloqueId;
  String _selectedTipo = 'AULA';
  final _codigoCtrl = TextEditingController();
  final _nombreCtrl = TextEditingController();
  final _capacidadCtrl = TextEditingController(text: '30');

  @override
  void initState() {
    super.initState();
    _selectedSedeId = widget.sedes.first.id;
    _selectedBloqueId = widget.bloques.isNotEmpty ? widget.bloques.first.id : null;
  }

  @override
  void dispose() {
    _codigoCtrl.dispose();
    _nombreCtrl.dispose();
    _capacidadCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Registrar Nuevo Espacio / Aula'),
      content: SizedBox(
        width: 440,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: _selectedSedeId,
                decoration: const InputDecoration(labelText: 'Sede Institucional'),
                items: widget.sedes
                    .map((s) => DropdownMenuItem(value: s.id, child: Text(s.nombre)))
                    .toList(),
                onChanged: (v) {
                  if (v != null) setState(() => _selectedSedeId = v);
                },
              ),
              const SizedBox(height: 12),
              if (widget.bloques.isNotEmpty) ...[
                DropdownButtonFormField<String>(
                  initialValue: _selectedBloqueId,
                  decoration: const InputDecoration(labelText: 'Bloque (Opcional)'),
                  items: widget.bloques
                      .map((b) => DropdownMenuItem(value: b.id, child: Text(b.nombre)))
                      .toList(),
                  onChanged: (v) => setState(() => _selectedBloqueId = v),
                ),
                const SizedBox(height: 12),
              ],
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _codigoCtrl,
                      decoration: const InputDecoration(labelText: 'Código (ej: AULA-101)'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _capacidadCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Capacidad personas'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _nombreCtrl,
                decoration: const InputDecoration(labelText: 'Nombre del Espacio'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _selectedTipo,
                decoration: const InputDecoration(labelText: 'Tipo de Espacio'),
                items: const [
                  DropdownMenuItem(value: 'AULA', child: Text('Aula Magistral')),
                  DropdownMenuItem(value: 'LABORATORIO', child: Text('Laboratorio')),
                  DropdownMenuItem(value: 'AUDITORIO', child: Text('Auditorio')),
                  DropdownMenuItem(value: 'TALLER', child: Text('Taller')),
                ],
                onChanged: (v) {
                  if (v != null) setState(() => _selectedTipo = v);
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
        ElevatedButton(
          onPressed: () {
            final codigo = _codigoCtrl.text.trim();
            final nombre = _nombreCtrl.text.trim();
            if (codigo.isEmpty || nombre.isEmpty) return;

            widget.onConfirmar(
              sedeId: _selectedSedeId,
              bloqueId: _selectedBloqueId,
              piso: 1,
              codigo: codigo,
              nombre: nombre,
              capacidad: int.tryParse(_capacidadCtrl.text) ?? 30,
              tipo: _selectedTipo,
            );
            Navigator.of(context).pop();
          },
          child: const Text('Registrar Espacio'),
        ),
      ],
    );
  }
}
