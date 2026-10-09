import 'package:flutter/material.dart';

import '../../data/models/cambio_sesion.dart';

/// Motivo obligatorio de un cambio puntual de sesión (mínimo
/// [minimoCaracteresMotivo] caracteres, como exige el backend). Queda en la
/// auditoría y se informa a los afectados.
class CampoMotivo extends StatelessWidget {
  final TextEditingController controller;
  final String etiqueta;
  final String? ayuda;

  const CampoMotivo({
    super.key,
    required this.controller,
    this.etiqueta = 'Motivo del cambio *',
    this.ayuda,
  });

  static String? validar(String? v) {
    final t = (v ?? '').trim();
    if (t.isEmpty) return 'El motivo es obligatorio';
    if (t.length < minimoCaracteresMotivo) {
      return 'Escriba al menos $minimoCaracteresMotivo caracteres';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      maxLines: 2,
      decoration: InputDecoration(
        labelText: etiqueta,
        hintText: ayuda,
        prefixIcon: const Icon(Icons.description_outlined),
      ),
      validator: validar,
    );
  }
}
