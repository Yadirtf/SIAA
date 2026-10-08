// cuenta_regresiva_ventana.dart — Tiempo restante de la ventana estudiantil según el
// cierraEn del servidor (US-MAR-13). Avisa una sola vez cuando llega a cero.
import 'dart:async';

import 'package:flutter/material.dart';

class CuentaRegresivaVentana extends StatefulWidget {
  final DateTime cierraEn;

  /// Hora actual corregida con el reloj del servidor.
  final DateTime Function() ahora;
  final VoidCallback onVencida;

  const CuentaRegresivaVentana({
    super.key,
    required this.cierraEn,
    required this.ahora,
    required this.onVencida,
  });

  static String formato(Duration d) {
    final m = d.inMinutes.toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  State<CuentaRegresivaVentana> createState() => _CuentaRegresivaVentanaState();
}

class _CuentaRegresivaVentanaState extends State<CuentaRegresivaVentana> {
  Timer? _timer;
  Duration _restante = Duration.zero;
  bool _avisado = false;

  @override
  void initState() {
    super.initState();
    _tick();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  @override
  void didUpdateWidget(CuentaRegresivaVentana oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.cierraEn != widget.cierraEn) {
      _avisado = false;
      _tick();
    }
  }

  void _tick() {
    final diff = widget.cierraEn.difference(widget.ahora());
    final restante = diff.isNegative ? Duration.zero : diff;
    if (mounted) setState(() => _restante = restante);
    if (restante == Duration.zero && !_avisado) {
      _avisado = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) widget.onVencida();
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = Colors.green.shade800;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.timer_outlined, color: color),
        const SizedBox(width: 8),
        Text(
          'Cierra en ${CuentaRegresivaVentana.formato(_restante)}',
          style: TextStyle(
            color: color,
            fontSize: 22,
            fontWeight: FontWeight.bold,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}
