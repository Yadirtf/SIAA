import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';

/// Paso de segundo factor del login (US-AUT-05). Muestra la clave y los códigos de respaldo
/// cuando hay que enrolar TOTP y pide el código de 6 dígitos (o uno de respaldo).
class SegundoFactorPanel extends StatefulWidget {
  final SegundoFactorRequerido estado;

  const SegundoFactorPanel({super.key, required this.estado});

  @override
  State<SegundoFactorPanel> createState() => _SegundoFactorPanelState();
}

class _SegundoFactorPanelState extends State<SegundoFactorPanel> {
  final _codigo = TextEditingController();

  @override
  void dispose() {
    _codigo.dispose();
    super.dispose();
  }

  void _enviar() {
    final codigo = _codigo.text.trim();
    if (codigo.length < 6) return;
    context.read<AuthBloc>().add(SegundoFactorEnviadoEvent(codigo));
  }

  @override
  Widget build(BuildContext context) {
    final estado = widget.estado;
    final enrol = estado.enrolamiento;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Verificación en dos pasos', style: AppTextStyles.h2),
        const SizedBox(height: 8),
        Text(
          enrol == null
              ? 'Escribe el código de 6 dígitos de tu app autenticadora o uno '
                    'de tus códigos de respaldo.'
              : 'Tu rol exige segundo factor. Agrega esta clave en tu app '
                    'autenticadora (Google Authenticator, Microsoft '
                    'Authenticator…) y escribe el primer código que muestre.',
          style: AppTextStyles.bodyMedium,
        ),
        if (enrol != null) ...[
          const SizedBox(height: 16),
          _bloqueCopiable('Clave', enrol.secreto),
          const SizedBox(height: 8),
          _bloqueCopiable('Enlace otpauth', enrol.uri(estado.correo)),
          const SizedBox(height: 16),
          Text('Códigos de respaldo (un solo uso)', style: AppTextStyles.label),
          const SizedBox(height: 6),
          _bloqueCopiable('Guárdalos ahora', enrol.codigosRespaldo.join('  ')),
        ],
        const SizedBox(height: 20),
        TextField(
          key: const Key('codigoTotp'),
          controller: _codigo,
          autofocus: true,
          maxLength: 8,
          decoration: InputDecoration(
            labelText: 'Código',
            counterText: '',
            errorText: estado.error,
            prefixIcon: const Icon(Icons.pin_outlined, size: 20),
          ),
          onSubmitted: (_) => _enviar(),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 48,
          child: ElevatedButton(
            onPressed: estado.enviando ? null : _enviar,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryAccent,
            ),
            child: estado.enviando
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    enrol == null ? 'Verificar' : 'Activar y entrar',
                    style: AppTextStyles.button,
                  ),
          ),
        ),
        TextButton(
          onPressed: estado.enviando
              ? null
              : () => context.read<AuthBloc>().add(
                  const SegundoFactorCanceladoEvent(),
                ),
          child: const Text('Volver'),
        ),
      ],
    );
  }

  Widget _bloqueCopiable(String titulo, String valor) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(titulo, style: AppTextStyles.bodySmall),
                SelectableText(valor, style: AppTextStyles.bodyMedium),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Copiar',
            icon: const Icon(Icons.copy_rounded, size: 18),
            onPressed: () => Clipboard.setData(ClipboardData(text: valor)),
          ),
        ],
      ),
    );
  }
}
