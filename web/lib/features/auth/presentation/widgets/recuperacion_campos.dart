import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

/// Longitud mínima que exige el backend (PASSWORD_MIN_LENGTH, 12 por defecto).
const int longitudMinimaClave = 12;

/// Valida la política de contraseña del backend: longitud, mayúscula, minúscula y dígito.
String? validarNuevaClave(String? valor) {
  final v = valor ?? '';
  if (v.length < longitudMinimaClave) {
    return 'Debe tener al menos $longitudMinimaClave caracteres';
  }
  if (!RegExp(r'[A-Z]').hasMatch(v) ||
      !RegExp(r'[a-z]').hasMatch(v) ||
      !RegExp(r'\d').hasMatch(v)) {
    return 'Combina mayúsculas, minúsculas y números';
  }
  return null;
}

/// Campo con etiqueta y el estilo del formulario de acceso.
class CampoRecuperacion extends StatelessWidget {
  final String etiqueta;
  final String hint;
  final IconData icono;
  final TextEditingController controller;
  final bool oculto;
  final String? Function(String?)? validator;
  final TextInputType? teclado;

  const CampoRecuperacion({
    super.key,
    required this.etiqueta,
    required this.hint,
    required this.icono,
    required this.controller,
    this.oculto = false,
    this.validator,
    this.teclado,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(etiqueta, style: AppTextStyles.label),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: oculto,
          keyboardType: teclado,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icono, size: 20, color: AppColors.textMuted),
          ),
          validator: validator,
        ),
      ],
    );
  }
}

/// Botón principal con indicador de carga.
class BotonRecuperacion extends StatelessWidget {
  final String texto;
  final bool cargando;
  final VoidCallback onPressed;

  const BotonRecuperacion({
    super.key,
    required this.texto,
    required this.cargando,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ElevatedButton(
        onPressed: cargando ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryAccent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: cargando
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Text(texto, style: AppTextStyles.button),
      ),
    );
  }
}
