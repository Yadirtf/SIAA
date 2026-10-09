import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// Muestra las advertencias con que el servidor aceptó un guardado (p. ej.
/// franja muy corta o aula sin geometría). No bloquean: solo informan.
Future<void> mostrarAdvertencias(
  BuildContext context, {
  required String titulo,
  required List<String> advertencias,
}) {
  if (advertencias.isEmpty) return Future.value();
  return showDialog<void>(
    context: context,
    builder: (_) =>
        AdvertenciasDialog(titulo: titulo, advertencias: advertencias),
  );
}

class AdvertenciasDialog extends StatelessWidget {
  final String titulo;
  final List<String> advertencias;

  const AdvertenciasDialog({
    super.key,
    required this.titulo,
    required this.advertencias,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      icon: const Icon(
        Icons.info_outline_rounded,
        color: AppColors.accentAmber,
        size: 36,
      ),
      title: Text(titulo, style: AppTextStyles.h3, textAlign: TextAlign.center),
      content: SizedBox(
        width: 460,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final a in advertencias)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.statusWarningBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  a,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.statusWarningText,
                  ),
                ),
              ),
          ],
        ),
      ),
      actions: [
        ElevatedButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Entendido'),
        ),
      ],
    );
  }
}
