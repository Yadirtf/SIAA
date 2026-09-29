import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../bloc/usuarios_bloc.dart';
import '../bloc/usuarios_state.dart';

/// Diálogo base de las acciones sobre usuarios: envía el evento al
/// [UsuariosBloc], se cierra cuando la acción termina bien y, si el backend
/// responde con error (409, 422, 403...), muestra su `mensaje` sin cerrarse.
class AccionUsuarioDialog extends StatefulWidget {
  final IconData icono;
  final String titulo;
  final Widget contenido;
  final String textoConfirmar;
  final Color? colorConfirmar;
  final double ancho;

  /// Valida el formulario y despacha el evento; devuelve false si no envió.
  final bool Function() onConfirmar;

  const AccionUsuarioDialog({
    super.key,
    required this.icono,
    required this.titulo,
    required this.contenido,
    required this.textoConfirmar,
    required this.onConfirmar,
    this.colorConfirmar,
    this.ancho = 520,
  });

  @override
  State<AccionUsuarioDialog> createState() => _AccionUsuarioDialogState();
}

class _AccionUsuarioDialogState extends State<AccionUsuarioDialog> {
  bool _enviado = false;
  String? _error;

  void _confirmar() {
    setState(() => _error = null);
    if (widget.onConfirmar()) setState(() => _enviado = true);
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<UsuariosBloc, UsuariosState>(
      listenWhen: (a, b) => _enviado && a.procesando && !b.procesando,
      listener: (context, state) {
        _enviado = false;
        if (state.mensajeError == null) {
          Navigator.of(context).pop();
        } else {
          setState(() => _error = state.mensajeError);
        }
      },
      builder: (context, state) {
        final ocupado = _enviado && state.procesando;
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: Row(
            children: [
              Icon(widget.icono, color: AppColors.primaryAccent),
              const SizedBox(width: 10),
              Expanded(child: Text(widget.titulo, style: AppTextStyles.h3)),
            ],
          ),
          content: SizedBox(
            width: widget.ancho,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  widget.contenido,
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    _ErrorBox(mensaje: _error!),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: ocupado ? null : () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              style: widget.colorConfirmar == null
                  ? null
                  : ElevatedButton.styleFrom(
                      backgroundColor: widget.colorConfirmar,
                      foregroundColor: Colors.white,
                    ),
              onPressed: ocupado ? null : _confirmar,
              child: ocupado
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(widget.textoConfirmar),
            ),
          ],
        );
      },
    );
  }
}

class _ErrorBox extends StatelessWidget {
  final String mensaje;

  const _ErrorBox({required this.mensaje});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.statusDangerBg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: AppColors.statusDangerText,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              mensaje,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.statusDangerText,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
