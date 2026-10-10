import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/campo_fecha.dart';
import '../../../../core/widgets/campo_hora.dart';
import '../../data/models/cambio_sesion.dart';
import '../../data/models/sesion_model.dart';
import '../bloc/sesiones_bloc.dart';
import '../widgets/campo_motivo.dart';
import '../widgets/franja_horaria.dart';
import 'envio_cambio_sesion.dart';

/// Mueve una sesión puntual a otra fecha u hora (US-ACA-06 AC-01) sin tocar
/// la asignación recurrente. El servidor valida cruces de aula y docente; si
/// la clase ya comenzó, se pide confirmar.
class ReprogramarSesionDialog extends StatefulWidget {
  final SesionModel sesion;

  const ReprogramarSesionDialog({super.key, required this.sesion});

  @override
  State<ReprogramarSesionDialog> createState() =>
      _ReprogramarSesionDialogState();
}

class _ReprogramarSesionDialogState extends State<ReprogramarSesionDialog>
    with EnvioCambioSesion {
  late String _fecha = widget.sesion.fecha.length >= 10
      ? widget.sesion.fecha.substring(0, 10)
      : widget.sesion.fecha;
  late FranjaHoraria _franja = FranjaHoraria.desdeTexto(
    1,
    widget.sesion.horaInicio,
    widget.sesion.horaFin,
  );

  void _submit() => enviarCambio(
    (cambio, r) => ReprogramarSesionEvent(
      sesionId: widget.sesion.id,
      nueva: ReprogramacionSesion(
        fecha: _fecha,
        horaInicio: CampoHora.formatear(_franja.inicio),
        horaFin: CampoHora.formatear(_franja.fin),
      ),
      cambio: cambio,
      resultado: r,
    ),
  );

  String? _validarFin(TimeOfDay fin) =>
      CampoHora.minutos(fin) <= CampoHora.minutos(_franja.inicio)
      ? 'Debe terminar después de la hora de inicio'
      : null;

  @override
  Widget build(BuildContext context) {
    final s = widget.sesion;
    return AlertDialog(
      title: Row(
        children: [
          const Icon(
            Icons.event_repeat_rounded,
            color: AppColors.primaryAccent,
          ),
          const SizedBox(width: 8),
          Text('Reprogramar Sesión (US-ACA-06)', style: AppTextStyles.h3),
        ],
      ),
      content: SizedBox(
        width: 440,
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${s.grupoTexto} · ${s.fecha} ${s.horaInicio}–${s.horaFin}',
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Solo cambia esta clase; la asignación recurrente sigue igual.',
                style: AppTextStyles.bodySmall,
              ),
              const SizedBox(height: 12),
              CampoFecha(
                etiqueta: 'Nueva fecha *',
                valor: _fecha,
                ancho: double.infinity,
                onCambio: (v) => setState(() => _fecha = v ?? _fecha),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: CampoHora(
                      etiqueta: 'Hora de inicio *',
                      valor: _franja.inicio,
                      onCambio: (h) => setState(
                        () => _franja = FranjaHoraria(
                          diaSemana: _franja.diaSemana,
                          inicio: h,
                          fin: _franja.fin,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CampoHora(
                      etiqueta: 'Hora de fin *',
                      valor: _franja.fin,
                      validador: _validarFin,
                      onCambio: (h) => setState(
                        () => _franja = FranjaHoraria(
                          diaSemana: _franja.diaSemana,
                          inicio: _franja.inicio,
                          fin: h,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              CampoMotivo(
                controller: motivoCtrl,
                etiqueta: 'Motivo de la reprogramación *',
                ayuda: 'Ej: evento institucional, cruce con parcial',
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
        botonEnviar('Reprogramar', _submit),
      ],
    );
  }
}
