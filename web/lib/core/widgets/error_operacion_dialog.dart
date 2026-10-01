import 'package:flutter/material.dart';

import '../network/api_exception.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../utils/hora_12h.dart';

/// Muestra por qué el servidor rechazó un guardado, encima del formulario, para
/// que el usuario lo cierre, corrija y vuelva a intentar sin perder lo escrito.
Future<void> mostrarErrorOperacion(BuildContext context, Object error) {
  return showDialog<void>(
    context: context,
    builder: (_) => ErrorOperacionDialog(error: error),
  );
}

class ErrorOperacionDialog extends StatelessWidget {
  final Object error;

  const ErrorOperacionDialog({super.key, required this.error});

  Map<String, dynamic> get _cuerpo {
    final e = error;
    if (e is ApiException && e.details is Map) {
      return Map<String, dynamic>.from(e.details as Map);
    }
    return const {};
  }

  String get _mensaje {
    final e = error;
    if (e is ApiException) return e.message;
    return 'No fue posible guardar. Revise su conexión e intente de nuevo.';
  }

  Map<String, String> get _contexto {
    final c = _cuerpo['contexto'];
    if (c is! Map) return const {};
    return c.map((k, v) => MapEntry(k.toString(), v.toString()));
  }

  bool get _esChoque => _cuerpo['codigo'] == 'CONFLICTO_HORARIO';

  String get _titulo {
    return switch (_contexto['tipo']) {
      'COLISION_DOCENTE' => 'El docente ya tiene clase a esa hora',
      'COLISION_AULA' => 'El aula ya está ocupada a esa hora',
      _ when _esChoque => 'Hay un cruce de horario',
      _ => 'No se pudo guardar',
    };
  }

  @override
  Widget build(BuildContext context) {
    final contexto = _contexto;
    return AlertDialog(
      icon: Icon(
        _esChoque ? Icons.event_busy_rounded : Icons.error_outline_rounded,
        color: AppColors.accentRose,
        size: 36,
      ),
      title: Text(
        _titulo,
        style: AppTextStyles.h3,
        textAlign: TextAlign.center,
      ),
      content: SizedBox(
        width: 460,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_mensaje, style: AppTextStyles.bodyMedium),
            if (_esChoque && contexto.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'Clase que ya ocupa ese horario',
                style: AppTextStyles.bodySmall.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              _ClaseExistente(datos: contexto),
            ],
          ],
        ),
      ),
      actions: [
        ElevatedButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Revisar el formulario'),
        ),
      ],
    );
  }
}

class _ClaseExistente extends StatelessWidget {
  final Map<String, String> datos;

  const _ClaseExistente({required this.datos});

  @override
  Widget build(BuildContext context) {
    final dia = datos['dia'] ?? '';
    final horario =
        '${dia.isEmpty ? '' : '${dia[0].toUpperCase()}${dia.substring(1)}, '}'
        '${hora12hDesdeTexto(datos['horaInicio'] ?? '')} a '
        '${hora12hDesdeTexto(datos['horaFin'] ?? '')}';
    final filas = <(String, String?)>[
      ('Asignatura', datos['asignatura']),
      ('Grupo', datos['grupo']),
      ('Docente', datos['docente']),
      ('Aula', datos['aula']),
      ('Horario', horario),
    ].where((f) => (f.$2 ?? '').trim().isNotEmpty);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.statusInfoBg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final (etiqueta, valor) in filas)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 90,
                    child: Text(etiqueta, style: AppTextStyles.bodySmall),
                  ),
                  Expanded(
                    child: Text(
                      valor!,
                      style: AppTextStyles.bodySmall.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
