import 'package:flutter/material.dart';

/// Campo de solo lectura que abre el selector de hora en formato 24 h y
/// entrega la hora elegida. Se valida dentro del [Form] con [validador].
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
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
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
          child: Text(formatear(valor)),
        ),
      ),
    );
  }
}
