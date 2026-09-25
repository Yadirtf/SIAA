import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../bloc/sesiones_bloc.dart';

class CancelarSesionDialog extends StatefulWidget {
  final String sesionId;
  const CancelarSesionDialog({super.key, required this.sesionId});

  @override
  State<CancelarSesionDialog> createState() => _CancelarSesionDialogState();
}

class _CancelarSesionDialogState extends State<CancelarSesionDialog> {
  final _motivoCtrl = TextEditingController();

  @override
  void dispose() {
    _motivoCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    final motivo = _motivoCtrl.text.trim();
    if (motivo.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El motivo de cancelación es obligatorio')),
      );
      return;
    }
    context.read<SesionesBloc>().add(
          CancelarSesionEvent(sesionId: widget.sesionId, motivo: motivo),
        );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.cancel_outlined, color: AppColors.accentRose),
          const SizedBox(width: 8),
          Text('Cancelar Sesión de Clase (US-ACA-06)', style: AppTextStyles.h3),
        ],
      ),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Esta acción cancelará la sesión puntual en el calendario sin afectar la asignación base recurrente.',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _motivoCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Motivo de la cancelación *',
                hintText: 'Ej: Evento institucional, mantenimiento de bloque...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Volver'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.accentRose),
          onPressed: _submit,
          child: const Text('Confirmar Cancelación'),
        ),
      ],
    );
  }
}

class ReasignarAulaDialog extends StatefulWidget {
  final String sesionId;
  final String aulaActual;

  const ReasignarAulaDialog({
    super.key,
    required this.sesionId,
    required this.aulaActual,
  });

  @override
  State<ReasignarAulaDialog> createState() => _ReasignarAulaDialogState();
}

class _ReasignarAulaDialogState extends State<ReasignarAulaDialog> {
  final _nuevoEspacioCtrl = TextEditingController();
  final _motivoCtrl = TextEditingController();

  @override
  void dispose() {
    _nuevoEspacioCtrl.dispose();
    _motivoCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    final nuevo = _nuevoEspacioCtrl.text.trim();
    if (nuevo.isEmpty) return;
    context.read<SesionesBloc>().add(
          ReasignarAulaSesionEvent(
            sesionId: widget.sesionId,
            nuevoEspacioId: nuevo,
            motivo: _motivoCtrl.text.trim(),
          ),
        );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.meeting_room_outlined, color: AppColors.primaryAccent),
          const SizedBox(width: 8),
          Text('Reasignar Aula (US-ACA-06)', style: AppTextStyles.h3),
        ],
      ),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Aula actual: ${widget.aulaActual}',
                style: AppTextStyles.bodyMedium
                    .copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            TextField(
              controller: _nuevoEspacioCtrl,
              decoration: const InputDecoration(
                labelText: 'ID / Código de la Nueva Aula *',
                prefixIcon: Icon(Icons.add_location_alt_outlined),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _motivoCtrl,
              decoration: const InputDecoration(
                labelText: 'Motivo del cambio (opcional)',
                prefixIcon: Icon(Icons.info_outline),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _submit,
          child: const Text('Reasignar Aula'),
        ),
      ],
    );
  }
}

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

class _DocenteReemplazoDialogState extends State<DocenteReemplazoDialog> {
  final _docenteCtrl = TextEditingController();
  final _motivoCtrl = TextEditingController();

  @override
  void dispose() {
    _docenteCtrl.dispose();
    _motivoCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    final doc = _docenteCtrl.text.trim();
    if (doc.isEmpty) return;
    context.read<SesionesBloc>().add(
          AsignarDocenteReemplazoEvent(
            sesionId: widget.sesionId,
            docenteId: doc,
            motivo: _motivoCtrl.text.trim(),
          ),
        );
    Navigator.pop(context);
  }

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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Titular actual: ${widget.docenteActual}',
                style: AppTextStyles.bodyMedium
                    .copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            TextField(
              controller: _docenteCtrl,
              decoration: const InputDecoration(
                labelText: 'ID / Documento del Docente Suplente *',
                prefixIcon: Icon(Icons.person_add_alt_1_outlined),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _motivoCtrl,
              decoration: const InputDecoration(
                labelText: 'Motivo de suplencia (ej: incapacidad, comisión)',
                prefixIcon: Icon(Icons.description_outlined),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _submit,
          child: const Text('Asignar Suplente'),
        ),
      ],
    );
  }
}
