import 'package:flutter/material.dart';
import '../../../data/admin_geo_repository.dart';

class AdminCrearBloqueDialog extends StatefulWidget {
  final List<AdminSede> sedes;
  final void Function({
    required String sedeId,
    required String codigo,
    required String nombre,
    required List<int> pisos,
  }) onConfirmar;

  const AdminCrearBloqueDialog({
    super.key,
    required this.sedes,
    required this.onConfirmar,
  });

  static Future<void> mostrar(
    BuildContext context, {
    required List<AdminSede> sedes,
    required void Function({
      required String sedeId,
      required String codigo,
      required String nombre,
      required List<int> pisos,
    }) onConfirmar,
  }) {
    if (sedes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Crea primero una sede antes de registrar bloques.')),
      );
      return Future.value();
    }
    return showDialog(
      context: context,
      builder: (_) => AdminCrearBloqueDialog(sedes: sedes, onConfirmar: onConfirmar),
    );
  }

  @override
  State<AdminCrearBloqueDialog> createState() => _AdminCrearBloqueDialogState();
}

class _AdminCrearBloqueDialogState extends State<AdminCrearBloqueDialog> {
  late String _selectedSedeId;
  final _codigoCtrl = TextEditingController();
  final _nombreCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedSedeId = widget.sedes.first.id;
  }

  @override
  void dispose() {
    _codigoCtrl.dispose();
    _nombreCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Registrar Nuevo Bloque'),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              initialValue: _selectedSedeId,
              decoration: const InputDecoration(labelText: 'Sede Institucional'),
              items: widget.sedes
                  .map((s) => DropdownMenuItem(
                        value: s.id,
                        child: Text('${s.codigo} - ${s.nombre}'),
                      ))
                  .toList(),
              onChanged: (v) {
                if (v != null) setState(() => _selectedSedeId = v);
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _codigoCtrl,
              decoration: const InputDecoration(labelText: 'Código Bloque (ej: BLOQ-A)'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _nombreCtrl,
              decoration: const InputDecoration(labelText: 'Nombre Bloque'),
            ),
          ],
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
              codigo: codigo,
              nombre: nombre,
              pisos: const [1, 2, 3],
            );
            Navigator.of(context).pop();
          },
          child: const Text('Crear Bloque'),
        ),
      ],
    );
  }
}
