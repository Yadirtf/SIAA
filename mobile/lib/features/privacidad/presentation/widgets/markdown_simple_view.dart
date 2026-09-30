// markdown_simple_view.dart — Render mínimo de Markdown para el aviso de privacidad (US-LEG-01)
// Soporta encabezados (#, ##, ###), viñetas (-, *), párrafos y quita **énfasis**.
import 'package:flutter/material.dart';

class MarkdownSimpleView extends StatelessWidget {
  final String markdown;

  const MarkdownSimpleView({super.key, required this.markdown});

  static final _enfasis = RegExp(r'(\*\*|__|`)');

  static String _limpiar(String s) => s.replaceAll(_enfasis, '').trim();

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context).textTheme;
    final hijos = <Widget>[];
    for (final linea in markdown.split('\n')) {
      final t = linea.trimRight();
      if (t.trim().isEmpty) {
        hijos.add(const SizedBox(height: 8));
      } else if (t.startsWith('### ')) {
        hijos.add(_titulo(t.substring(4), tema.titleSmall));
      } else if (t.startsWith('## ')) {
        hijos.add(_titulo(t.substring(3), tema.titleMedium));
      } else if (t.startsWith('# ')) {
        hijos.add(_titulo(t.substring(2), tema.titleLarge));
      } else if (RegExp(r'^\s*[-*] ').hasMatch(t)) {
        hijos.add(_vineta(t.replaceFirst(RegExp(r'^\s*[-*] '), ''), tema));
      } else {
        hijos.add(SelectableText(_limpiar(t), style: tema.bodyMedium));
      }
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: hijos,
    );
  }

  Widget _titulo(String texto, TextStyle? estilo) => Padding(
        padding: const EdgeInsets.only(top: 12, bottom: 4),
        child: SelectableText(
          _limpiar(texto),
          style: estilo?.copyWith(fontWeight: FontWeight.w700),
        ),
      );

  Widget _vineta(String texto, TextTheme tema) => Padding(
        padding: const EdgeInsets.only(left: 8, bottom: 2),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('•  ', style: tema.bodyMedium),
            Expanded(
              child: SelectableText(_limpiar(texto), style: tema.bodyMedium),
            ),
          ],
        ),
      );
}
