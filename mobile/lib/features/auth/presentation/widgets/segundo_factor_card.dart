// Paso de segundo factor del login (US-AUT-05): muestra la clave y los códigos de
// respaldo cuando hay que enrolar TOTP y pide el código de 6 dígitos o uno de respaldo.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import '../bloc/auth_bloc.dart';

class SegundoFactorCard extends StatefulWidget {
  final AuthSegundoFactorRequerido estado;

  const SegundoFactorCard({super.key, required this.estado});

  @override
  State<SegundoFactorCard> createState() => _SegundoFactorCardState();
}

class _SegundoFactorCardState extends State<SegundoFactorCard> {
  final _codigo = TextEditingController();

  @override
  void dispose() {
    _codigo.dispose();
    super.dispose();
  }

  void _enviar() {
    final codigo = _codigo.text.trim();
    if (codigo.length < 6) return;
    context.read<AuthBloc>().add(AuthSegundoFactorEnviado(codigo));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final enrol = widget.estado.enrolamiento;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(SIAASpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Verificación en dos pasos',
                style: theme.textTheme.titleLarge),
            const SizedBox(height: SIAASpacing.sm),
            Text(enrol == null
                ? 'Escribe el código de 6 dígitos de tu app autenticadora o uno de tus códigos de respaldo.'
                : 'Tu rol exige segundo factor. Agrega esta clave en tu app autenticadora y escribe el primer código que muestre.'),
            if (enrol != null) ...[
              const SizedBox(height: SIAASpacing.md),
              _copiable(context, 'Clave', enrol.secreto),
              const SizedBox(height: SIAASpacing.sm),
              _copiable(context, 'Códigos de respaldo (un solo uso)',
                  enrol.codigosRespaldo.join('  ')),
            ],
            const SizedBox(height: SIAASpacing.md),
            TextField(
              key: const Key('codigoTotp'),
              controller: _codigo,
              keyboardType: TextInputType.visiblePassword,
              maxLength: 8,
              decoration: InputDecoration(
                labelText: 'Código',
                counterText: '',
                errorText: widget.estado.error,
              ),
              onSubmitted: (_) => _enviar(),
            ),
            const SizedBox(height: SIAASpacing.md),
            FilledButton(
              onPressed: widget.estado.enviando ? null : _enviar,
              child: Text(enrol == null ? 'Verificar' : 'Activar y entrar'),
            ),
            TextButton(
              onPressed: widget.estado.enviando
                  ? null
                  : () => context
                      .read<AuthBloc>()
                      .add(AuthSegundoFactorCancelado()),
              child: const Text('Volver'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _copiable(BuildContext context, String titulo, String valor) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(titulo),
      subtitle: SelectableText(valor),
      trailing: IconButton(
        tooltip: 'Copiar',
        icon: const Icon(Icons.copy_rounded),
        onPressed: () => Clipboard.setData(ClipboardData(text: valor)),
      ),
    );
  }
}
