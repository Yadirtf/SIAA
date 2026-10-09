import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../usuarios/presentation/widgets/selector_usuario.dart';
import '../bloc/sesiones_bloc.dart';
import '../widgets/campo_motivo.dart';
import 'envio_cambio_sesion.dart';

/// Asigna un docente suplente a una sesión puntual (US-ACA-09). El motivo es
/// obligatorio; si la clase ya comenzó, se pide confirmar.
class DocenteReemplazoDialog extends StatefulWidget {
  final String sesionId;
  final String docenteActual;

  const DocenteReemplazoDialog({
    super.key,
    required this.sesionId,
    required this.docenteActual,
  });

  @override
  State<DocenteReemplazoDialog> createState() => _DocenteReemplazoDialogState();
}

class _DocenteReemplazoDialogState extends State<DocenteReemplazoDialog>
    with EnvioCambioSesion {
  String? _suplenteId;

  void _submit() => enviarCambio(
    (cambio, r) => AsignarDocenteReemplazoEvent(
      sesionId: widget.sesionId,
      docenteId: _suplenteId ?? '',
      cambio: cambio,
      resultado: r,
    ),
  );

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.person_pin_rounded, color: AppColors.primaryAccent),
          const SizedBox(width: 8),
          Text('Docente Suplente (US-ACA-09)', style: AppTextStyles.h3),
        ],
      ),
      content: SizedBox(
        width: 420,
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Titular actual: ${widget.docenteActual}',
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              SelectorUsuario(
                etiqueta: 'Docente suplente *',
                rol: 'DOCENTE',
                requerido: true,
                icono: Icons.person_add_alt_1_outlined,
                onCambio: (u) => setState(() => _suplenteId = u?.id),
              ),
              const SizedBox(height: 12),
              CampoMotivo(
                controller: motivoCtrl,
                etiqueta: 'Motivo de suplencia *',
                ayuda: 'Ej: incapacidad, comisión de estudios',
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: guardando ? null : () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        botonEnviar('Asignar Suplente', _submit),
      ],
    );
  }
}
