import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import 'markdown_bloques.dart';

/// Renderiza Markdown sencillo (encabezados, párrafos y listas) como texto
/// seleccionable, sin dependencias externas.
class MarkdownSimple extends StatelessWidget {
  final String markdown;

  const MarkdownSimple({super.key, required this.markdown});

  @override
  Widget build(BuildContext context) {
    final bloques = parsearMarkdown(markdown);
    return SelectionArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [for (final b in bloques) _bloque(b)],
      ),
    );
  }

  Widget _bloque(BloqueMd b) {
    switch (b.tipo) {
      case TipoBloqueMd.encabezado:
        final estilo = b.nivel <= 1
            ? AppTextStyles.h1
            : b.nivel == 2
            ? AppTextStyles.h2
            : AppTextStyles.h3;
        return Padding(
          padding: EdgeInsets.only(top: b.nivel <= 2 ? 20 : 14, bottom: 8),
          child: _texto(b.texto, estilo),
        );
      case TipoBloqueMd.parrafo:
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _texto(b.texto, _cuerpo),
        );
      case TipoBloqueMd.vineta:
      case TipoBloqueMd.numerada:
        final marcador = b.tipo == TipoBloqueMd.vineta ? '•' : '${b.nivel}.';
        return Padding(
          padding: const EdgeInsets.only(left: 12, bottom: 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(width: 24, child: Text(marcador, style: _cuerpo)),
              Expanded(child: _texto(b.texto, _cuerpo)),
            ],
          ),
        );
    }
  }

  TextStyle get _cuerpo =>
      AppTextStyles.bodyLarge.copyWith(color: AppColors.textSecondary);

  Widget _texto(String texto, TextStyle estilo) {
    return Text.rich(
      TextSpan(
        style: estilo,
        children: [
          for (final t in parsearEnLinea(texto))
            TextSpan(
              text: t.texto,
              style: TextStyle(
                fontWeight: t.negrita ? FontWeight.w700 : null,
                fontStyle: t.cursiva ? FontStyle.italic : null,
              ),
            ),
        ],
      ),
    );
  }
}
