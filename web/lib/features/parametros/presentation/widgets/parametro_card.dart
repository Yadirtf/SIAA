import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/catalogo_parametros.dart';
import '../../domain/models/parametro_model.dart';
import '../bloc/parametros_bloc.dart';
import '../bloc/parametros_event.dart';
import 'info_parametro_dialog.dart';
import 'parametro_badges.dart';
import 'parametro_editor.dart';

/// Fila editable de un parámetro: qué controla, de dónde viene su valor y el
/// valor con su unidad. El icono de información abre la explicación completa.
/// US-PAR-01 AC-02: el rango se avisa aquí, pero el backend es quien valida.
class ParametroCard extends StatefulWidget {
  final ParametroEfectivoModel parametro;
  final String ambitoDestino; // Nivel en que se quiere guardar el override
  final String ambitoDestinoId;
  final bool isSaving;

  const ParametroCard({
    super.key,
    required this.parametro,
    required this.ambitoDestino,
    required this.ambitoDestinoId,
    required this.isSaving,
  });

  @override
  State<ParametroCard> createState() => _ParametroCardState();
}

class _ParametroCardState extends State<ParametroCard> {
  bool _editing = false;
  String? _error;
  late final TextEditingController _ctrl = TextEditingController();

  InfoParametro get _info => infoParametro(widget.parametro.clave);

  /// El valor rige en el ámbito elegido sin venir de un nivel superior.
  bool get _propio => widget.parametro.nivel == widget.ambitoDestino;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  /// Parte siempre del valor efectivo vigente, no de una edición cancelada.
  void _empezarEdicion() {
    _ctrl.text = widget.parametro.valor?.toString() ?? '';
    setState(() {
      _editing = true;
      _error = null;
    });
  }

  void _onSave() {
    final raw = _ctrl.text.trim();
    final error = raw.isEmpty ? 'Escriba un valor' : _info.validar(raw);
    if (error != null) {
      setState(() => _error = error);
      return;
    }
    final current = widget.parametro.valor;
    final Object valor = switch (current) {
      bool() => raw.toLowerCase() == 'true',
      int() => int.tryParse(raw) ?? raw,
      double() => double.tryParse(raw) ?? raw,
      _ => _info.esNumerico ? (int.tryParse(raw) ?? raw) : raw,
    };
    context.read<ParametrosBloc>().add(
      GuardarParametroEvent(
        request: GuardarParametroRequest(
          ambito: widget.ambitoDestino,
          ambitoId: widget.ambitoDestinoId,
          clave: widget.parametro.clave,
          valor: valor,
        ),
      ),
    );
    setState(() => _editing = false);
  }

  Widget _descripcion() {
    final info = _info;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              info.nombre,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            if (!info.aplicado) const AvisoParametro.noAplicado(),
            if (info.soloGlobal) const AvisoParametro.soloGlobal(),
          ],
        ),
        if (info.resumen.isNotEmpty) ...[
          const SizedBox(height: 3),
          Text(
            info.resumen,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ],
    );
  }

  Widget _valor() => InkWell(
    onTap: _empezarEdicion,
    borderRadius: BorderRadius.circular(6),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              _info.formatear(widget.parametro.valor),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.primaryAccent,
              ),
            ),
          ),
          const Icon(Icons.edit_rounded, size: 14, color: AppColors.textMuted),
        ],
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final p = widget.parametro;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: _propio && !p.esGlobal
            ? AppColors.primaryAccent.withValues(alpha: 0.04)
            : AppColors.surface,
        border: const Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          OrigenIcon(nivel: p.nivel),
          const SizedBox(width: 14),
          Expanded(flex: 5, child: _descripcion()),
          IconButton(
            tooltip: '¿Qué configura "${_info.nombre}"?',
            icon: const Icon(Icons.info_outline_rounded, size: 20),
            color: AppColors.primaryAccent,
            onPressed: () => mostrarInfoParametro(context, p),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 150,
            child: NivelBadge(
              nivel: p.nivelLabel,
              texto: widget.ambitoDestino == 'GLOBAL'
                  ? 'Valor global'
                  : (_propio ? 'Definido aquí' : 'Heredado de ${p.nivelLabel}'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 3,
            child: _editing
                ? ParametroEditor(
                    ctrl: _ctrl,
                    isBool: p.valor is bool,
                    opciones: _info.opciones,
                    unidad: _info.unidad,
                    error: _error,
                    onSave: _onSave,
                    onCancel: () => setState(() => _editing = false),
                    isSaving: widget.isSaving,
                  )
                : _valor(),
          ),
        ],
      ),
    );
  }
}
