// marcaje_accion_panel.dart — Botón de marcaje según la ventana y permanencia de la salida (US-MAR-15)
import 'package:flutter/material.dart';
import '../bloc/marcaje_state.dart';
import '../helpers/accion_marcaje.dart';
import 'one_touch_button.dart';

class MarcajeAccionPanel extends StatelessWidget {
  final MarcajeState state;

  /// Recibe el tipo (ENTRADA | SALIDA) que corresponde a la ventana vigente.
  final ValueChanged<String> onMarcar;

  const MarcajeAccionPanel({
    super.key,
    required this.state,
    required this.onMarcar,
  });

  /// Permanencia de la salida: la de la respuesta del marcaje o, si no vino,
  /// la del marcaje de salida que informa la sesión activa.
  static int? permanenciaDe(MarcajeState state) {
    final sesion = state.sesionActiva;
    if (sesion == null || !sesion.ventana.esSalida) return null;
    final res = state.ultimoResultado;
    if (res != null && res.esAceptado && res.permanenciaMin != null) {
      return res.permanenciaMin;
    }
    return sesion.permanenciaSalidaMin;
  }

  @override
  Widget build(BuildContext context) {
    final sesion = state.sesionActiva;
    if (sesion == null) return const SizedBox.shrink();
    final accion = AccionMarcaje.de(sesion);
    final permanencia = permanenciaDe(state);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OneTouchButton(
          onPressed: state.puedeMarcar ? () => onMarcar(accion.tipo) : null,
          isSubmitting: state.isSubmitting,
          isEnabled: state.puedeMarcar,
          label: accion.label,
          icon: accion.icon,
        ),
        if (permanencia != null) ...[
          const SizedBox(height: 16),
          Text(
            'Permanencia: ${formatearPermanencia(permanencia)}',
            key: const Key('permanencia_salida'),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ],
        if (sesion.ventana.esSalida && sesion.salidaDesactivada) ...[
          const SizedBox(height: 16),
          Text(
            'El marcaje de salida está desactivado para esta sesión.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade700),
          ),
        ],
      ],
    );
  }
}
