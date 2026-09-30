// privacidad_view.dart — Contenido del aviso de privacidad y decisión (US-LEG-01, RNF-LEG-001)
// Se usa a pantalla completa (primer uso / nueva versión) y desde "Privacidad y datos".
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/consentimiento_cubit.dart';
import '../cubit/consentimiento_state.dart';
import 'decision_consentimiento_panel.dart';
import 'markdown_simple_view.dart';

class PrivacidadView extends StatefulWidget {
  /// Se invoca cuando la decisión quedó registrada en el servidor.
  final void Function(bool acepta)? onDecidido;

  const PrivacidadView({super.key, this.onDecidido});

  @override
  State<PrivacidadView> createState() => _PrivacidadViewState();
}

class _PrivacidadViewState extends State<PrivacidadView> {
  @override
  void initState() {
    super.initState();
    final cubit = context.read<ConsentimientoCubit>();
    if (cubit.state.politica == null) cubit.cargarPolitica();
    if (cubit.state.consentimiento == null) cubit.verificar();
  }

  Future<void> _decidir(bool acepta) async {
    final cubit = context.read<ConsentimientoCubit>();
    if (!acepta && cubit.state.otorgado && !await _confirmarRetiro()) return;
    final ok = await cubit.decidir(acepta: acepta);
    if (ok) widget.onDecidido?.call(acepta);
  }

  Future<bool> _confirmarRetiro() async {
    final r = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Retirar consentimiento'),
        content: const Text(
          'Sin su autorización no podrá registrar asistencia con ubicación. '
          '¿Desea continuar?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Retirar'),
          ),
        ],
      ),
    );
    return r ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ConsentimientoCubit, ConsentimientoState>(
      builder: (context, state) {
        final politica = state.politica;
        if (politica == null) {
          return _sinPolitica(context, state);
        }
        final tema = Theme.of(context).textTheme;
        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          children: [
            if (politica.institucion.isNotEmpty)
              Text(politica.institucion, style: tema.titleMedium),
            Text(
              'Versión ${politica.version}'
              '${politica.actualizadaEn.isEmpty ? '' : ' · actualizada ${politica.actualizadaEn}'}',
              style: tema.bodySmall,
            ),
            const SizedBox(height: 8),
            MarkdownSimpleView(markdown: politica.contenido),
            if (politica.contacto.isNotEmpty) ...[
              const SizedBox(height: 12),
              SelectableText(
                'Consultas y reclamos: ${politica.contacto}',
                style: tema.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
            const Divider(height: 32),
            DecisionConsentimientoPanel(
              state: state,
              onAceptar: () => _decidir(true),
              onRechazar: () => _decidir(false),
            ),
          ],
        );
      },
    );
  }

  Widget _sinPolitica(BuildContext context, ConsentimientoState state) {
    if (state.error == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(state.error!, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () =>
                  context.read<ConsentimientoCubit>().cargarPolitica(),
              child: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}
