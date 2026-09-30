import 'package:flutter/material.dart';

import '../../../../core/widgets/campo_hora.dart';
import 'franja_horaria.dart';

export 'franja_horaria.dart';

/// Día de la semana y horas de inicio/fin (selector de hora en 24 h).
class FranjaHorariaCampos extends StatelessWidget {
  final FranjaHoraria franja;
  final ValueChanged<FranjaHoraria> onCambio;

  const FranjaHorariaCampos({
    super.key,
    required this.franja,
    required this.onCambio,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: DropdownButtonFormField<int>(
            value: franja.diaSemana,
            decoration: const InputDecoration(
              labelText: 'Día Semana *',
              prefixIcon: Icon(Icons.view_week_outlined),
            ),
            items: FranjaHoraria.dias.entries
                .map(
                  (d) =>
                      DropdownMenuItem<int>(value: d.key, child: Text(d.value)),
                )
                .toList(),
            onChanged: (v) => onCambio(franja.copyWith(diaSemana: v ?? 1)),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: CampoHora(
            etiqueta: 'Inicio',
            valor: franja.inicio,
            onCambio: (h) => onCambio(franja.copyWith(inicio: h)),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: CampoHora(
            etiqueta: 'Fin',
            valor: franja.fin,
            validador: (_) => franja.error,
            onCambio: (h) => onCambio(franja.copyWith(fin: h)),
          ),
        ),
      ],
    );
  }
}
