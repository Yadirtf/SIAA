import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/models/ambito_model.dart';
import '../../data/models/usuario_model.dart';
import '../bloc/usuarios_bloc.dart';
import '../bloc/usuarios_event.dart';
import '../widgets/accion_usuario_dialog.dart';
import '../widgets/ambitos_selector.dart';

/// Reemplaza los ámbitos de un usuario (PUT /usuarios/:id/ambitos).
class AmbitosUsuarioDialog extends StatefulWidget {
  final UsuarioModel usuario;

  const AmbitosUsuarioDialog({super.key, required this.usuario});

  static Future<void> show(BuildContext context, UsuarioModel usuario) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AmbitosUsuarioDialog(usuario: usuario),
    );
  }

  @override
  State<AmbitosUsuarioDialog> createState() => _AmbitosUsuarioDialogState();
}

class _AmbitosUsuarioDialogState extends State<AmbitosUsuarioDialog> {
  late Set<AmbitoModel> _ambitos = widget.usuario.ambitos.toSet();

  bool _enviar() {
    context.read<UsuariosBloc>().add(
      AsignarAmbitosUsuarioEvent(widget.usuario.id, _ambitos.toList()),
    );
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return AccionUsuarioDialog(
      icono: Icons.location_city_rounded,
      titulo: 'Ámbitos de ${widget.usuario.nombreCompleto}',
      textoConfirmar: 'Guardar ámbitos',
      ancho: 620,
      onConfirmar: _enviar,
      contenido: AmbitosSelector(
        seleccionados: _ambitos,
        onChanged: (a) => setState(() => _ambitos = a),
      ),
    );
  }
}
