import 'package:flutter/material.dart';

import '../theme/app_text_styles.dart';
import 'campo_fecha.dart';
import 'error_operacion_dialog.dart';

enum TipoCampo { texto, entero, fecha, opciones }

/// Un campo del formulario de edición. `opciones` mapea valor → etiqueta.
class CampoEdicion {
  final String clave;
  final String etiqueta;
  final String valor;
  final TipoCampo tipo;
  final bool requerido;
  final Map<String, String> opciones;
  final IconData? icono;
  final String? ayuda;

  const CampoEdicion({
    required this.clave,
    required this.etiqueta,
    required this.valor,
    this.tipo = TipoCampo.texto,
    this.requerido = true,
    this.opciones = const {},
    this.icono,
    this.ayuda,
  });
}

/// Abre un formulario de edición con los datos actuales. `guardar` recibe los
/// valores (texto) por clave; si el servidor rechaza, el error se explica en un
/// modal y el formulario sigue abierto. Devuelve true si se guardó.
Future<bool> editarConFormulario(
  BuildContext context, {
  required String titulo,
  required List<CampoEdicion> campos,
  required Future<void> Function(Map<String, String> valores) guardar,
  String? nota,
}) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (_) => FormularioEdicionDialog(
      titulo: titulo,
      campos: campos,
      guardar: guardar,
      nota: nota,
    ),
  );
  return ok == true;
}

class FormularioEdicionDialog extends StatefulWidget {
  final String titulo;
  final List<CampoEdicion> campos;
  final Future<void> Function(Map<String, String> valores) guardar;
  final String? nota;

  const FormularioEdicionDialog({
    super.key,
    required this.titulo,
    required this.campos,
    required this.guardar,
    this.nota,
  });

  @override
  State<FormularioEdicionDialog> createState() =>
      _FormularioEdicionDialogState();
}

class _FormularioEdicionDialogState extends State<FormularioEdicionDialog> {
  final _form = GlobalKey<FormState>();
  late final Map<String, String> _valores = {
    for (final c in widget.campos) c.clave: c.valor,
  };
  bool _guardando = false;

  Future<void> _guardar() async {
    if (_guardando || !_form.currentState!.validate()) return;
    setState(() => _guardando = true);
    try {
      await widget.guardar(_valores.map((k, v) => MapEntry(k, v.trim())));
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _guardando = false);
      await mostrarErrorOperacion(context, e);
    }
  }

  String? _validar(CampoEdicion c, String? v) {
    final t = (v ?? '').trim();
    if (c.requerido && t.isEmpty) return '${c.etiqueta} es obligatorio';
    if (c.tipo == TipoCampo.entero && t.isNotEmpty && int.tryParse(t) == null) {
      return 'Escriba un número entero';
    }
    return null;
  }

  Widget _campo(CampoEdicion c) {
    switch (c.tipo) {
      case TipoCampo.fecha:
        return FormField<String>(
          initialValue: _valores[c.clave],
          validator: (v) => _validar(c, _valores[c.clave]),
          builder: (estado) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CampoFecha(
                etiqueta: c.etiqueta,
                valor: _valores[c.clave],
                ancho: double.infinity,
                onCambio: (v) => setState(() => _valores[c.clave] = v ?? ''),
              ),
              if (estado.hasError)
                Padding(
                  padding: const EdgeInsets.only(top: 4, left: 12),
                  child: Text(
                    estado.errorText!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                      fontSize: 12,
                    ),
                  ),
                ),
            ],
          ),
        );
      case TipoCampo.opciones:
        return DropdownButtonFormField<String>(
          initialValue: c.opciones.containsKey(_valores[c.clave])
              ? _valores[c.clave]
              : null,
          isExpanded: true,
          decoration: InputDecoration(
            labelText: c.etiqueta,
            prefixIcon: c.icono == null ? null : Icon(c.icono),
            helperText: c.ayuda,
          ),
          items: [
            for (final e in c.opciones.entries)
              DropdownMenuItem(value: e.key, child: Text(e.value)),
          ],
          validator: (v) => _validar(c, v),
          onChanged: (v) => setState(() => _valores[c.clave] = v ?? ''),
        );
      case TipoCampo.texto:
      case TipoCampo.entero:
        return TextFormField(
          initialValue: c.valor,
          keyboardType: c.tipo == TipoCampo.entero
              ? TextInputType.number
              : TextInputType.text,
          decoration: InputDecoration(
            labelText: c.etiqueta,
            prefixIcon: c.icono == null ? null : Icon(c.icono),
            helperText: c.ayuda,
          ),
          validator: (v) => _validar(c, v),
          onChanged: (v) => _valores[c.clave] = v,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.titulo, style: AppTextStyles.h3),
      content: SizedBox(
        width: 440,
        child: Form(
          key: _form,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.nota != null) ...[
                  Text(widget.nota!, style: AppTextStyles.bodySmall),
                  const SizedBox(height: 12),
                ],
                for (final c in widget.campos) ...[
                  _campo(c),
                  const SizedBox(height: 12),
                ],
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _guardando ? null : () => Navigator.pop(context, false),
          child: const Text('Cancelar'),
        ),
        ElevatedButton.icon(
          onPressed: _guardando ? null : _guardar,
          icon: _guardando
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.save_rounded, size: 18),
          label: Text(_guardando ? 'Guardando…' : 'Guardar cambios'),
        ),
      ],
    );
  }
}
