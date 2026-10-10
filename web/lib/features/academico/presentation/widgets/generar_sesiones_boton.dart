import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/generacion_sesiones_remote_datasource.dart';
import '../../data/models/academico_models.dart';
import '../cubit/generacion_sesiones_cubit.dart';
import '../dialogs/confirmar_generacion_dialog.dart';
import '../dialogs/informe_generacion_dialog.dart';

/// Acción "Generar sesiones" de un periodo (US-ACA-05). Convierte las
/// asignaciones del periodo en sesiones fechadas, que es lo que el docente
/// ve y marca en la app. Se ejecuta en segundo plano en el servidor y al
/// terminar muestra el informe. Se puede repetir: no duplica sesiones.
class GenerarSesionesBoton extends StatefulWidget {
  final PeriodoModel periodo;
  final GeneracionSesionesRemoteDataSource? dataSource;

  /// Cada cuánto se consulta el trabajo en el servidor.
  final Duration intervaloConsulta;

  const GenerarSesionesBoton({
    super.key,
    required this.periodo,
    this.dataSource,
    this.intervaloConsulta = const Duration(seconds: 2),
  });

  @override
  State<GenerarSesionesBoton> createState() => _GenerarSesionesBotonState();
}

class _GenerarSesionesBotonState extends State<GenerarSesionesBoton> {
  late final _cubit = GeneracionSesionesCubit(
    dataSource: widget.dataSource ?? GeneracionSesionesRemoteDataSource(),
    intervalo: widget.intervaloConsulta,
  );

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  Future<void> _generar() async {
    final incluirPasadas = await confirmarGeneracion(context, widget.periodo);
    if (incluirPasadas == null) return;
    await _cubit.generar(widget.periodo.id, incluirPasadas: incluirPasadas);
  }

  void _alTerminar(BuildContext context, GeneracionSesionesState s) {
    if (s.fase == FaseGeneracion.completada && s.informe != null) {
      mostrarInformeGeneracion(context, s.informe!);
    } else if (s.fase == FaseGeneracion.fallida) {
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        SnackBar(content: Text('No se generaron sesiones: ${s.error ?? ''}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.periodo.estado == 'CERRADO') return const SizedBox.shrink();
    return BlocConsumer<GeneracionSesionesCubit, GeneracionSesionesState>(
      bloc: _cubit,
      listenWhen: (a, b) => a.fase != b.fase,
      listener: _alTerminar,
      builder: (context, s) => OutlinedButton.icon(
        onPressed: s.enCurso ? null : _generar,
        icon: s.enCurso
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.event_repeat_rounded, size: 18),
        label: Text(
          s.enCurso
              ? (s.progreso > 0 ? 'Generando… ${s.progreso} %' : 'Generando…')
              : 'Generar sesiones',
        ),
      ),
    );
  }
}
