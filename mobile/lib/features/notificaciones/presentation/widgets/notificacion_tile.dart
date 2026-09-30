// notificacion_tile.dart — Elemento de la bandeja de notificaciones (US-NOT-01/02)
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../domain/models/notificacion_model.dart';

class NotificacionTile extends StatelessWidget {
  final NotificacionModel notificacion;
  final VoidCallback onTap;

  const NotificacionTile({
    super.key,
    required this.notificacion,
    required this.onTap,
  });

  static IconData _icono(String tipo) {
    switch (tipo) {
      case 'RECORDATORIO_SESION':
        return Icons.alarm_rounded;
      case 'CIERRE_VENTANA':
        return Icons.timer_off_rounded;
      case 'RESULTADO_JUSTIFICACION':
        return Icons.fact_check_rounded;
      case 'CAMBIO_HORARIO':
        return Icons.event_repeat_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final n = notificacion;
    final fecha = n.creadaEn == null
        ? ''
        : DateFormat('dd/MM HH:mm').format(n.creadaEn!.toLocal());
    return ListTile(
      leading: Icon(_icono(n.tipo)),
      title: Text(
        n.titulo,
        style:
            TextStyle(fontWeight: n.leida ? FontWeight.w400 : FontWeight.w700),
      ),
      subtitle: Text(n.cuerpo, maxLines: 3, overflow: TextOverflow.ellipsis),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(fecha, style: const TextStyle(fontSize: 11)),
          if (!n.leida)
            const Padding(
              padding: EdgeInsets.only(top: 4),
              child: Icon(Icons.circle, size: 10, color: Colors.blue),
            ),
        ],
      ),
      onTap: onTap,
    );
  }
}
