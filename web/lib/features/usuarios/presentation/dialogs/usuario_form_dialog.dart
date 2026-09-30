import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../data/models/ambito_model.dart';
import '../../data/models/usuario_model.dart';
import '../../data/models/usuario_requests.dart';
import '../bloc/usuarios_bloc.dart';
import '../bloc/usuarios_event.dart';
import '../widgets/accion_usuario_dialog.dart';
import '../widgets/ambitos_selector.dart';
import '../widgets/roles_selector.dart';

/// Alta de usuario (con roles, ámbitos y contraseña opcional) o edición de
/// sus datos básicos cuando se recibe [usuario].
class UsuarioFormDialog extends StatefulWidget {
  final UsuarioModel? usuario;

  const UsuarioFormDialog({super.key, this.usuario});

  static Future<void> show(BuildContext context, {UsuarioModel? usuario}) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => UsuarioFormDialog(usuario: usuario),
    );
  }

  @override
  State<UsuarioFormDialog> createState() => _UsuarioFormDialogState();
}

class _UsuarioFormDialogState extends State<UsuarioFormDialog> {
  static final _correoRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _correo;
  late final TextEditingController _nombre;
  late final TextEditingController _apellido;
  late final TextEditingController _documento;
  final _password = TextEditingController();
  Set<String> _roles = {'DOCENTE'};
  Set<AmbitoModel> _ambitos = {};
  bool _sinRoles = false;

  bool get _esEdicion => widget.usuario != null;

  @override
  void initState() {
    super.initState();
    final u = widget.usuario;
    _correo = TextEditingController(text: u?.correo ?? '');
    _nombre = TextEditingController(text: u?.nombre ?? '');
    _apellido = TextEditingController(text: u?.apellido ?? '');
    _documento = TextEditingController(text: u?.documento ?? '');
  }

  @override
  void dispose() {
    for (final c in [_correo, _nombre, _apellido, _documento, _password]) {
      c.dispose();
    }
    super.dispose();
  }

  bool _enviar() {
    final valido = _formKey.currentState?.validate() ?? false;
    setState(() => _sinRoles = !_esEdicion && _roles.isEmpty);
    if (!valido || _sinRoles) return false;
    final bloc = context.read<UsuariosBloc>();
    if (_esEdicion) {
      bloc.add(
        ActualizarUsuarioEvent(
          widget.usuario!.id,
          ActualizarUsuarioRequest(
            correo: _correo.text.trim(),
            nombre: _nombre.text.trim(),
            apellido: _apellido.text.trim(),
            documento: _documento.text.trim(),
          ),
        ),
      );
    } else {
      bloc.add(
        CrearUsuarioEvent(
          CrearUsuarioRequest(
            correo: _correo.text.trim(),
            nombre: _nombre.text.trim(),
            apellido: _apellido.text.trim(),
            documento: _documento.text.trim(),
            password: _password.text,
            roles: _roles.toList(),
            ambitos: _ambitos.toList(),
          ),
        ),
      );
    }
    return true;
  }

  String? _requerido(String? v) =>
      (v == null || v.trim().isEmpty) ? 'Campo obligatorio' : null;

  Widget _campo(
    TextEditingController c,
    String etiqueta, {
    String? Function(String?)? validator,
    String? ayuda,
    bool oculto = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: c,
        obscureText: oculto,
        validator: validator,
        decoration: InputDecoration(
          labelText: etiqueta,
          helperText: ayuda,
          helperMaxLines: 2,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AccionUsuarioDialog(
      icono: _esEdicion ? Icons.edit_rounded : Icons.person_add_alt_1_rounded,
      titulo: _esEdicion ? 'Editar datos del usuario' : 'Nuevo usuario',
      textoConfirmar: _esEdicion ? 'Guardar cambios' : 'Crear usuario',
      ancho: _esEdicion ? 480 : 640,
      onConfirmar: _enviar,
      contenido: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _campo(
              _correo,
              'Correo institucional *',
              validator: (v) =>
                  _requerido(v) ??
                  (_correoRegex.hasMatch(v!.trim()) ? null : 'Correo inválido'),
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _campo(_nombre, 'Nombre *', validator: _requerido),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _campo(_apellido, 'Apellido *', validator: _requerido),
                ),
              ],
            ),
            _campo(_documento, 'Documento de identidad'),
            if (!_esEdicion) ..._seccionesAlta(),
          ],
        ),
      ),
    );
  }

  List<Widget> _seccionesAlta() {
    return [
      _campo(
        _password,
        'Contraseña inicial (opcional)',
        oculto: true,
        ayuda:
            'Si la deja vacía, el sistema enviará un correo de invitación '
            'para que el usuario defina su contraseña.',
      ),
      const Divider(height: 24),
      Text('Roles *', style: AppTextStyles.label),
      const SizedBox(height: 8),
      RolesSelector(
        seleccionados: _roles,
        onChanged: (r) => setState(() => _roles = r),
      ),
      if (_sinRoles)
        Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(
            'Seleccione al menos un rol.',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.statusDangerText,
            ),
          ),
        ),
      const Divider(height: 24),
      Text('Ámbitos', style: AppTextStyles.label),
      AmbitosSelector(
        seleccionados: _ambitos,
        onChanged: (a) => setState(() => _ambitos = a),
      ),
    ];
  }
}
