// sesion_card.dart — Tarjeta de sesión activa y cuenta regresiva de ventana (US-MAR-01)
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../domain/models/sesion_activa_model.dart';

class SesionCard extends StatefulWidget {
  final SesionActivaModel sesion;

  const SesionCard({super.key, required this.sesion});

  @override
  State<SesionCard> createState() => _SesionCardState();
}

class _SesionCardState extends State<SesionCard> {
  Timer? _timer;
  late Duration _restante;

  @override
  void initState() {
    super.initState();
    _actualizarRestante();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _actualizarRestante());
  }

  void _actualizarRestante() {
    final ahora = DateTime.now();
    final ventana = widget.sesion.ventana;
    if (ventana.estaAbierta) {
      _restante = ventana.cierraEn.isAfter(ahora)
          ? ventana.cierraEn.difference(ahora)
          : Duration.zero;
    } else if (ventana.noAbierta) {
      _restante = ventana.abreEn.isAfter(ahora)
          ? ventana.abreEn.difference(ahora)
          : Duration.zero;
    } else {
      _restante = Duration.zero;
    }
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    if (d.inHours > 0) {
      return '${d.inHours}h ${m}m ${s}s';
    }
    return '${m}m ${s}s';
  }

  @override
  Widget build(BuildContext context) {
    final sesion = widget.sesion;
    final timeFormat = DateFormat('hh:mm a');
    final horarioStr =
        '${timeFormat.format(sesion.inicioProgramado)} - ${timeFormat.format(sesion.finProgramado)}';

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Grupo ${sesion.grupo}',
                    style: TextStyle(
                      color: Colors.blue.shade800,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: sesion.ventana.estaAbierta ? Colors.green.shade50 : Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.timer_outlined,
                        size: 14,
                        color: sesion.ventana.estaAbierta ? Colors.green.shade800 : Colors.orange.shade800,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        sesion.ventana.estaAbierta
                            ? 'Cierra en: ${_formatDuration(_restante)}'
                            : sesion.ventana.noAbierta
                                ? 'Abre en: ${_formatDuration(_restante)}'
                                : 'Ventana cerrada',
                        style: TextStyle(
                          color: sesion.ventana.estaAbierta ? Colors.green.shade800 : Colors.orange.shade800,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              sesion.asignatura,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.meeting_room_outlined, size: 18, color: Colors.grey),
                const SizedBox(width: 6),
                Text(
                  '${sesion.espacio.codigo} — ${sesion.espacio.nombre}',
                  style: const TextStyle(fontSize: 14, color: Colors.black87),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.access_time_rounded, size: 18, color: Colors.grey),
                const SizedBox(width: 6),
                Text(
                  horarioStr,
                  style: const TextStyle(fontSize: 14, color: Colors.black87),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
