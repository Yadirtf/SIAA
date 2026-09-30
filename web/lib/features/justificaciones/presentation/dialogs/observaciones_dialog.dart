import 'package:flutter/material.dart';

/// Pide observaciones para una decisión. Con [minimo] > 0 son obligatorias.
/// Devuelve el texto (posiblemente vacío) o null si se cancela.
class ObservacionesDialog extends StatefulWidget {
  final String titulo;
  final String descripcion;
  final String textoConfirmar;
  final int minimo;

  const ObservacionesDialog({
    super.key,
    required this.titulo,
    required this.descripcion,
    required this.textoConfirmar,
    this.minimo = 0,
  });

  static Future<String?> show(
    BuildContext context, {
    required String titulo,
    required String descripcion,
    required String textoConfirmar,
    int minimo = 0,
  }) => showDialog<String>(
    context: context,
    builder: (_) => ObservacionesDialog(
      titulo: titulo,
      descripcion: descripcion,
      textoConfirmar: textoConfirmar,
      minimo: minimo,
    ),
  );

  @override
  State<ObservacionesDialog> createState() => _ObservacionesDialogState();
}

class _ObservacionesDialogState extends State<ObservacionesDialog> {
  final _form = GlobalKey<FormState>();
  final _texto = TextEditingController();

  @override
  void dispose() {
    _texto.dispose();
    super.dispose();
  }

  void _confirmar() {
    if (!_form.currentState!.validate()) return;
    Navigator.of(context).pop(_texto.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    final obligatorio = widget.minimo > 0;
    return AlertDialog(
      title: Text(widget.titulo),
      content: SizedBox(
        width: 460,
        child: Form(
          key: _form,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.descripcion),
              const SizedBox(height: 16),
              TextFormField(
                controller: _texto,
                autofocus: true,
                maxLines: 4,
                maxLength: 1000,
                decoration: InputDecoration(
                  labelText: obligatorio
                      ? 'Observaciones (obligatorias)'
                      : 'Observaciones (opcional)',
                  border: const OutlineInputBorder(),
                ),
                validator: (v) {
                  if (!obligatorio) return null;
                  if ((v ?? '').trim().length < widget.minimo) {
                    return 'Escriba al menos ${widget.minimo} caracteres.';
                  }
                  return null;
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
          onPressed: _confirmar,
          child: Text(widget.textoConfirmar),
        ),
      ],
    );
  }
}
