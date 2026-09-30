import 'package:flutter/material.dart';

import '../../../../core/network/mensaje_error.dart';
import '../../data/generacion_sesiones_remote_datasource.dart';
import '../../data/models/academico_models.dart';
import '../dialogs/informe_generacion_dialog.dart';

/// Acción "Generar sesiones" de un periodo (US-ACA-05). Convierte las
/// asignaciones del periodo en sesiones fechadas, que es lo que el docente
/// ve y marca en la app. Se puede repetir: no duplica sesiones.
class GenerarSesionesBoton extends StatefulWidget {
  final PeriodoModel periodo;
  final GeneracionSesionesRemoteDataSource? dataSource;

  const GenerarSesionesBoton({
    super.key,
    required this.periodo,
    this.dataSource,
  });

  @override
  State<GenerarSesionesBoton> createState() => _GenerarSesionesBotonState();
}

class _GenerarSesionesBotonState extends State<GenerarSesionesBoton> {
  late final _ds = widget.dataSource ?? GeneracionSesionesRemoteDataSource();
  bool _generando = false;

  Future<bool> _confirmar() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Generar sesiones'),
        content: Text(
          'Se crearán las sesiones de todas las asignaciones de '
          '${widget.periodo.nombre} entre ${widget.periodo.fechaInicio} y '
          '${widget.periodo.fechaFin}. Las que ya existen no se duplican.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Generar'),
          ),
        ],
      ),
    );
    return ok ?? false;
  }

  Future<void> _generar() async {
    if (!await _confirmar()) return;
    setState(() => _generando = true);
    try {
      final informe = await _ds.generar(widget.periodo.id);
      if (!mounted) return;
      setState(() => _generando = false);
      await mostrarInformeGeneracion(context, informe);
    } catch (e) {
      if (!mounted) return;
      setState(() => _generando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se generaron sesiones: ${mensajeDeError(e)}'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.periodo.estado == 'CERRADO') return const SizedBox.shrink();
    return OutlinedButton.icon(
      onPressed: _generando ? null : _generar,
      icon: _generando
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.event_repeat_rounded, size: 18),
      label: const Text('Generar sesiones'),
    );
  }
}
