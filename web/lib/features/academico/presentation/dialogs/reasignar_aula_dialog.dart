import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../geo/presentation/widgets/selector_espacio.dart';
import '../bloc/sesiones_bloc.dart';
import '../widgets/campo_motivo.dart';
import 'envio_cambio_sesion.dart';

/// Cambia el aula de una sesión puntual (US-ACA-06). El motivo es
/// obligatorio; si la clase ya comenzó, se pide confirmar.
class ReasignarAulaDialog extends StatefulWidget {
  final String sesionId;
  final String aulaActual;

  /// Aula actual de la sesión: se excluye y fija la sede de las opciones.
  final String? espacioActualId;

  const ReasignarAulaDialog({
    super.key,
    required this.sesionId,
    required this.aulaActual,
    this.espacioActualId,
  });

  @override
  State<ReasignarAulaDialog> createState() => _ReasignarAulaDialogState();
}

class _ReasignarAulaDialogState extends State<ReasignarAulaDialog>
    with EnvioCambioSesion {
  String? _nuevoEspacioId;

  void _submit() => enviarCambio(
    (cambio, r) => ReasignarAulaSesionEvent(
      sesionId: widget.sesionId,
      nuevoEspacioId: _nuevoEspacioId ?? '',
      cambio: cambio,
      resultado: r,
    ),
  );

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          const Icon(
            Icons.meeting_room_outlined,
            color: AppColors.primaryAccent,
          ),
          const SizedBox(width: 8),
          Text('Reasignar Aula (US-ACA-06)', style: AppTextStyles.h3),
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
                'Aula actual: ${widget.aulaActual}',
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              SelectorEspacio(
                etiqueta: 'Nueva aula *',
                requerido: true,
                sedeDelEspacioId: widget.espacioActualId,
                excluirId: widget.espacioActualId,
                onCambio: (e) => setState(() => _nuevoEspacioId = e?.id),
              ),
              const SizedBox(height: 12),
              CampoMotivo(
                controller: motivoCtrl,
                ayuda: 'Ej: daño en el video beam, aula en mantenimiento',
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
        botonEnviar('Reasignar Aula', _submit),
      ],
    );
  }
}
