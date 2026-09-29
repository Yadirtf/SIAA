import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../widgets/accion_usuario_dialog.dart';

/// Acción que exige un motivo obligatorio (desactivar usuario, cerrar
/// sesiones). [onMotivo] despacha el evento con el motivo escrito.
class MotivoUsuarioDialog extends StatefulWidget {
  final String titulo;
  final String descripcion;
  final String textoConfirmar;
  final IconData icono;
  final ValueChanged<String> onMotivo;

  const MotivoUsuarioDialog({
    super.key,
    required this.titulo,
    required this.descripcion,
    required this.textoConfirmar,
    required this.icono,
    required this.onMotivo,
  });

  static Future<void> show(
    BuildContext context, {
    required String titulo,
    required String descripcion,
    required String textoConfirmar,
    required IconData icono,
    required ValueChanged<String> onMotivo,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => MotivoUsuarioDialog(
        titulo: titulo,
        descripcion: descripcion,
        textoConfirmar: textoConfirmar,
        icono: icono,
        onMotivo: onMotivo,
      ),
    );
  }

  @override
  State<MotivoUsuarioDialog> createState() => _MotivoUsuarioDialogState();
}

class _MotivoUsuarioDialogState extends State<MotivoUsuarioDialog> {
  final _formKey = GlobalKey<FormState>();
  final _motivo = TextEditingController();

  @override
  void dispose() {
    _motivo.dispose();
    super.dispose();
  }

  bool _enviar() {
    if (!(_formKey.currentState?.validate() ?? false)) return false;
    widget.onMotivo(_motivo.text.trim());
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return AccionUsuarioDialog(
      icono: widget.icono,
      titulo: widget.titulo,
      textoConfirmar: widget.textoConfirmar,
      colorConfirmar: AppColors.accentRose,
      ancho: 460,
      onConfirmar: _enviar,
      contenido: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.descripcion, style: AppTextStyles.bodyMedium),
            const SizedBox(height: 16),
            TextFormField(
              controller: _motivo,
              maxLines: 2,
              autofocus: true,
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'El motivo es obligatorio'
                  : null,
              decoration: const InputDecoration(
                labelText: 'Motivo *',
                hintText: 'Queda registrado en la auditoría',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
