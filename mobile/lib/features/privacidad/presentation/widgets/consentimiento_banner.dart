// consentimiento_banner.dart — Aviso de marcaje deshabilitado sin consentimiento (US-LEG-01 AC-05)
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/consentimiento_cubit.dart';
import '../cubit/consentimiento_state.dart';
import '../screens/aviso_privacidad_screen.dart';

class ConsentimientoBanner extends StatelessWidget {
  const ConsentimientoBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ConsentimientoCubit, ConsentimientoState>(
      builder: (context, state) {
        final contacto = state.contacto.isEmpty
            ? 'el canal institucional de protección de datos'
            : state.contacto;
        return Card(
          color: Colors.amber.shade50,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Row(
                  children: [
                    Icon(Icons.privacy_tip_outlined),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Marcaje deshabilitado',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Para registrar asistencia con ubicación debe aceptar el aviso '
                  'de privacidad. Puede seguir consultando su horario, historial '
                  'y justificaciones. Dudas o reclamos: $contacto.',
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => AvisoPrivacidadScreen.mostrar(context),
                    child: const Text('Revisar aviso de privacidad'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
