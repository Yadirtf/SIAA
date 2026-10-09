import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../data/models/sesion_model.dart';
import '../dialogs/sesion_detalle_dialog.dart';
import '../dialogs/sesion_ops_dialogs.dart';

/// Menú de acciones puntuales sobre una sesión: ver su detalle, reasignar
/// aula, asignar suplente, reprogramar o cancelarla (US-ACA-06, US-ACA-09).
class AccionesSesionMenu extends StatelessWidget {
  final SesionModel sesion;

  const AccionesSesionMenu({super.key, required this.sesion});

  void _abrir(BuildContext context, String accion) {
    final s = sesion;
    final Widget dialogo = switch (accion) {
      'detalle' => SesionDetalleDialog(sesion: s),
      'reprogramar' => ReprogramarSesionDialog(sesion: s),
      'aula' => ReasignarAulaDialog(
        sesionId: s.id,
        aulaActual: s.aulaTexto,
        espacioActualId: s.espacioId.isEmpty ? null : s.espacioId,
      ),
      'suplente' => DocenteReemplazoDialog(
        sesionId: s.id,
        docenteActual: s.docentesTexto,
      ),
      _ => CancelarSesionDialog(sesionId: s.id),
    };
    showDialog(context: context, builder: (_) => dialogo);
  }

  PopupMenuItem<String> _item(
    String valor,
    IconData icono,
    String texto, {
    Color? color,
  }) => PopupMenuItem(
    value: valor,
    child: Row(
      children: [
        Icon(icono, size: 18, color: color),
        const SizedBox(width: 8),
        Flexible(
          child: Text(texto, style: TextStyle(color: color)),
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    final cancelable = !sesion.esCancelada;
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert_rounded),
      tooltip: 'Acciones de sesión',
      onSelected: (v) => _abrir(context, v),
      itemBuilder: (_) => [
        _item('detalle', Icons.info_outline_rounded, 'Ver detalle'),
        if (cancelable)
          _item('reprogramar', Icons.event_repeat_rounded, 'Reprogramar'),
        _item('aula', Icons.meeting_room_outlined, 'Reasignar aula'),
        _item('suplente', Icons.person_add_alt_outlined, 'Asignar suplente'),
        if (cancelable)
          _item(
            'cancelar',
            Icons.cancel_outlined,
            'Cancelar sesión',
            color: AppColors.accentRose,
          ),
      ],
    );
  }
}
