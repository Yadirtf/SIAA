// justificacion_form_body.dart — Campos del formulario de radicación (US-JUS-01)
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/models/soporte_adjunto.dart';
import '../cubit/justificacion_form_cubit.dart';
import '../cubit/justificacion_form_state.dart';
import 'soportes_adjuntos_section.dart';
import 'tipo_justificacion_selector.dart';

class JustificacionFormBody extends StatefulWidget {
  final JustificacionFormState state;
  final String? nombreSesion;
  final String? fechaSesion;

  const JustificacionFormBody({
    super.key,
    required this.state,
    this.nombreSesion,
    this.fechaSesion,
  });

  @override
  State<JustificacionFormBody> createState() => _JustificacionFormBodyState();
}

class _JustificacionFormBodyState extends State<JustificacionFormBody> {
  final _descripcion = TextEditingController();

  @override
  void dispose() {
    _descripcion.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final cubit = context.read<JustificacionFormCubit>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.nombreSesion != null) _encabezadoSesion(),
        _titulo('Tipo de justificación'),
        TipoJustificacionSelector(
          seleccionado: state.tipo,
          habilitado: !state.ocupado,
          onSeleccionar: cubit.seleccionarTipo,
        ),
        const SizedBox(height: SIAASpacing.md),
        _titulo('Descripción'),
        TextField(
          controller: _descripcion,
          enabled: !state.enviando,
          minLines: 3,
          maxLines: 6,
          maxLength: 1000,
          decoration: const InputDecoration(
            hintText: 'Explica el motivo (mínimo '
                '${ReglasSoporte.minDescripcion} caracteres)',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: SIAASpacing.sm),
        _titulo('Soportes'),
        SoportesAdjuntosSection(
          soportes: state.soportes,
          puedeAdjuntar: state.puedeAdjuntar,
          puedeQuitar: !state.ocupado,
          onAdjuntar: cubit.adjuntar,
          onQuitar: cubit.quitarSoporte,
        ),
        if (state.error != null) _error(state.error!),
        const SizedBox(height: SIAASpacing.lg),
        FilledButton.icon(
          onPressed:
              state.ocupado ? null : () => cubit.enviar(_descripcion.text),
          icon: state.enviando
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.send_rounded),
          label: Text(state.enviando ? 'Enviando…' : 'Radicar justificación'),
        ),
      ],
    );
  }

  Widget _encabezadoSesion() {
    return Card(
      margin: const EdgeInsets.only(bottom: SIAASpacing.md),
      child: ListTile(
        leading: const Icon(Icons.event_busy_outlined),
        title: Text(widget.nombreSesion!),
        subtitle: widget.fechaSesion == null ? null : Text(widget.fechaSesion!),
      ),
    );
  }

  Widget _titulo(String texto) => Padding(
        padding: const EdgeInsets.only(bottom: SIAASpacing.sm),
        child: Text(texto, style: const TextStyle(fontWeight: FontWeight.w600)),
      );

  Widget _error(String mensaje) {
    return Container(
      margin: const EdgeInsets.only(top: SIAASpacing.md),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red.shade700),
          const SizedBox(width: 8),
          Expanded(
            child: Text(mensaje, style: TextStyle(color: Colors.red.shade800)),
          ),
        ],
      ),
    );
  }
}
