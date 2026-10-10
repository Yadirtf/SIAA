import 'package:flutter/material.dart';

import '../network/api_exception.dart';
import '../network/confirmacion_requerida.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// Ejecuta [accion] sin confirmar; si el servidor responde
/// CONFIRMACION_REQUERIDA, muestra su mensaje y, si el usuario acepta, la
/// repite con `confirmar = true`. Devuelve false si el usuario no confirmó.
/// Cualquier otro error se propaga para que el formulario lo explique.
/// [alPreguntar] avisa (true) cuando se abre la pregunta y (false) cuando el
/// usuario confirmó, p. ej. para pausar el indicador de guardado.
Future<bool> ejecutarConConfirmacion(
  BuildContext context,
  Future<void> Function(bool confirmar) accion, {
  String titulo = 'Confirme la operación',
  String textoConfirmar = 'Sí, continuar',
  void Function(bool preguntando)? alPreguntar,
}) async {
  try {
    await accion(false);
    return true;
  } catch (e) {
    if (!requiereConfirmacion(e) || !context.mounted) rethrow;
    alPreguntar?.call(true);
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => ConfirmacionRequeridaDialog(
        titulo: titulo,
        mensaje: (e as ApiException).message,
        textoConfirmar: textoConfirmar,
      ),
    );
    if (ok != true) return false;
    alPreguntar?.call(false);
    await accion(true);
    return true;
  }
}

/// Pregunta si se repite una operación que el servidor marcó como delicada.
class ConfirmacionRequeridaDialog extends StatelessWidget {
  final String titulo;
  final String mensaje;
  final String textoConfirmar;

  const ConfirmacionRequeridaDialog({
    super.key,
    required this.titulo,
    required this.mensaje,
    this.textoConfirmar = 'Sí, continuar',
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      icon: const Icon(
        Icons.warning_amber_rounded,
        color: AppColors.accentAmber,
        size: 36,
      ),
      title: Text(titulo, style: AppTextStyles.h3, textAlign: TextAlign.center),
      content: SizedBox(
        width: 440,
        child: Text(mensaje, style: AppTextStyles.bodyMedium),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('No, volver'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text(textoConfirmar),
        ),
      ],
    );
  }
}
