import 'package:flutter/material.dart';

import '../../../../core/widgets/campo_hora.dart';

/// Franja semanal recurrente de una asignación (US-ACA-02).
class FranjaHoraria {
  final int diaSemana; // 1 = Lunes … 6 = Sábado
  final TimeOfDay inicio;
  final TimeOfDay fin;

  const FranjaHoraria({
    required this.diaSemana,
    required this.inicio,
    required this.fin,
  });

  static const porDefecto = FranjaHoraria(
    diaSemana: 1,
    inicio: TimeOfDay(hour: 8, minute: 0),
    fin: TimeOfDay(hour: 10, minute: 0),
  );

  static const dias = <int, String>{
    1: 'Lunes',
    2: 'Martes',
    3: 'Miércoles',
    4: 'Jueves',
    5: 'Viernes',
    6: 'Sábado',
  };

  String get inicioTexto => CampoHora.formatear(inicio);
  String get finTexto => CampoHora.formatear(fin);

  /// Mensaje de error si la hora de fin no es posterior a la de inicio.
  String? get error => CampoHora.minutos(fin) <= CampoHora.minutos(inicio)
      ? 'La hora de fin debe ser posterior a la de inicio'
      : null;

  FranjaHoraria copyWith({int? diaSemana, TimeOfDay? inicio, TimeOfDay? fin}) {
    return FranjaHoraria(
      diaSemana: diaSemana ?? this.diaSemana,
      inicio: inicio ?? this.inicio,
      fin: fin ?? this.fin,
    );
  }
}
