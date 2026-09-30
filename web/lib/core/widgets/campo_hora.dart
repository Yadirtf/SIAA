import 'package:flutter/material.dart';

import '../utils/hora_12h.dart';

/// Campo de solo lectura que abre el selector de hora en formato de 12 h con
/// a. m./p. m. (como se lee en Colombia) y entrega la hora elegida. Al backend
/// se envía en 24 h con [formatear]. Se valida dentro del [Form] con [validador].
class CampoHora extends StatelessWidget {
  final String etiqueta;
  final TimeOfDay valor;
  final ValueChanged<TimeOfDay> onCambio;
  final String? Function(TimeOfDay valor)? validador;

  const CampoHora({
    super.key,
    required this.etiqueta,
    required this.valor,
    required this.onCambio,
    this.validador,
  });

  /// `HH:mm`, el formato que espera el backend en las franjas.
  static String formatear(TimeOfDay h) =>
      '${h.hour.toString().padLeft(2, '0')}:'
      '${h.minute.toString().padLeft(2, '0')}';

  static int minutos(TimeOfDay h) => h.hour * 60 + h.minute;

  Future<void> _elegir(BuildContext context) async {
    final hora = await showTimePicker(
      context: context,
      initialTime: valor,
      helpText: etiqueta,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: false),
        child: child!,
      ),
    );
    if (hora != null) onCambio(hora);
  }

  @override
  Widget build(BuildContext context) {
    return FormField<TimeOfDay>(
      validator: (_) => validador?.call(valor),
      builder: (field) => InkWell(
        onTap: () => _elegir(context),
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: etiqueta,
            errorText: field.errorText,
            errorMaxLines: 2,
            suffixIcon: const Icon(Icons.schedule_rounded, size: 18),
          ),
          child: Text(hora12h(valor.hour, valor.minute)),
        ),
      ),
    );
  }
}
