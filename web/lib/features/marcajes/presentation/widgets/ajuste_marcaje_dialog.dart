// ajuste_marcaje_dialog.dart — Modal para anulación o corrección administrativa con auditoría (US-MAR-09)
import 'package:flutter/material.dart';
import '../../domain/models/marcaje_admin_model.dart';

class AjusteMarcajeDialog extends StatefulWidget {
  final MarcajeAdminModel marcaje;
  final void Function({
    required String accion,
    String? nuevoResultado,
    required bool anulado,
    required String motivo,
  }) onConfirmar;

  const AjusteMarcajeDialog({
    super.key,
    required this.marcaje,
    required this.onConfirmar,
  });

  static Future<void> show(
    BuildContext context, {
    required MarcajeAdminModel marcaje,
    required void Function({
      required String accion,
      String? nuevoResultado,
      required bool anulado,
      required String motivo,
    }) onConfirmar,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AjusteMarcajeDialog(marcaje: marcaje, onConfirmar: onConfirmar),
    );
  }

  @override
  State<AjusteMarcajeDialog> createState() => _AjusteMarcajeDialogState();
}

class _AjusteMarcajeDialogState extends State<AjusteMarcajeDialog> {
  String _accion = 'AJUSTAR'; // AJUSTAR | ANULAR
  late String _nuevoResultado;
  final _motivoCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _nuevoResultado = widget.marcaje.esAceptado ? 'RECHAZADO' : 'ACEPTADO';
  }

  @override
  Widget build(BuildContext context) {
    final m = widget.marcaje;
    final chars = _motivoCtrl.text.trim().length;
    final puedeGuardar = chars >= 20;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Icon(Icons.admin_panel_settings_rounded, color: Colors.blue.shade800),
          const SizedBox(width: 8),
          const Expanded(
            child: Text('Ajuste Administrativo de Marcaje'),
          ),
        ],
      ),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    _buildRow('ID Marcaje:', m.id),
                    _buildRow('Usuario:', m.usuarioId),
                    _buildRow('Sesión:', m.sesionId),
                    _buildRow('Tipo:', m.tipo),
                    _buildRow('Resultado Actual:', m.resultado),
                    _buildRow('Origen:', m.origen),
                    if (m.motivoRechazo != null) _buildRow('Motivo Original:', m.motivoRechazo!),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text('Tipo de Corrección:', style: TextStyle(fontWeight: FontWeight.bold)),
              Row(
                children: [
                  Radio<String>(
                    value: 'AJUSTAR',
                    groupValue: _accion,
                    onChanged: (val) => setState(() => _accion = val!),
                  ),
                  const Text('Modificar Resultado'),
                  const SizedBox(width: 20),
                  Radio<String>(
                    value: 'ANULAR',
                    groupValue: _accion,
                    onChanged: (val) => setState(() => _accion = val!),
                  ),
                  const Text('Anular Registro'),
                ],
              ),
              if (_accion == 'AJUSTAR') ...[
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _nuevoResultado,
                  decoration: const InputDecoration(labelText: 'Nuevo Resultado', isDense: true),
                  items: const [
                    DropdownMenuItem(value: 'ACEPTADO', child: Text('ACEPTADO')),
                    DropdownMenuItem(value: 'RECHAZADO', child: Text('RECHAZADO')),
                  ],
                  onChanged: (val) => setState(() => _nuevoResultado = val!),
                ),
              ],
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Motivo Obligatorio (Auditoría):', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(
                    '$chars / 20 mín',
                    style: TextStyle(
                      color: puedeGuardar ? Colors.green : Colors.red,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _motivoCtrl,
                maxLines: 3,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  hintText: 'Explique detalladamente el motivo de la corrección administrativa.',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: puedeGuardar
              ? () {
                  Navigator.pop(context);
                  widget.onConfirmar(
                    accion: _accion,
                    nuevoResultado: _accion == 'AJUSTAR' ? _nuevoResultado : null,
                    anulado: _accion == 'ANULAR',
                    motivo: _motivoCtrl.text.trim(),
                  );
                }
              : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: _accion == 'ANULAR' ? Colors.red.shade700 : Colors.blue.shade800,
            foregroundColor: Colors.white,
          ),
          child: Text(_accion == 'ANULAR' ? 'Anular Marcaje' : 'Aplicar Ajuste'),
        ),
      ],
    );
  }

  Widget _buildRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
