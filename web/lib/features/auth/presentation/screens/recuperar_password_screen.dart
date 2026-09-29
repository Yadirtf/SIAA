import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/auth_repository.dart';
import '../cubit/recuperacion_cubit.dart';
import '../widgets/recuperacion_campos.dart';

/// Recuperación de contraseña (US-AUT-04). Sin token pide el correo y envía el enlace;
/// con el token del enlace (…/?token=…) permite definir la nueva contraseña.
class RecuperarPasswordScreen extends StatelessWidget {
  final String? token;

  const RecuperarPasswordScreen({super.key, this.token});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (ctx) => RecuperacionCubit(ctx.read<AuthRepository>()),
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(color: AppColors.border),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 40,
                  ),
                  child: _Contenido(token: token),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Contenido extends StatefulWidget {
  final String? token;

  const _Contenido({this.token});

  @override
  State<_Contenido> createState() => _ContenidoState();
}

class _ContenidoState extends State<_Contenido> {
  final _formKey = GlobalKey<FormState>();
  final _correo = TextEditingController();
  final _clave = TextEditingController();
  final _confirmacion = TextEditingController();

  bool get _conToken => (widget.token ?? '').isNotEmpty;

  @override
  void dispose() {
    _correo.dispose();
    _clave.dispose();
    _confirmacion.dispose();
    super.dispose();
  }

  void _enviar() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final cubit = context.read<RecuperacionCubit>();
    if (_conToken) {
      cubit.confirmar(widget.token!, _clave.text);
    } else {
      cubit.solicitar(_correo.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RecuperacionCubit, RecuperacionState>(
      builder: (context, state) {
        if (state.paso == RecuperacionPaso.solicitudEnviada) {
          return _resultado(
            Icons.mark_email_read_outlined,
            'Revisa tu correo',
            'Si la cuenta existe, te enviamos un enlace para definir una '
                'nueva contraseña. El enlace vence en pocos minutos.',
          );
        }
        if (state.paso == RecuperacionPaso.confirmada) {
          return _resultado(
            Icons.verified_user_outlined,
            'Contraseña actualizada',
            'Ya puedes iniciar sesión con tu nueva contraseña. Las sesiones '
                'abiertas en otros equipos se cerraron.',
          );
        }
        final cargando = state.paso == RecuperacionPaso.enviando;
        return Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                _conToken ? 'Nueva contraseña' : 'Recuperar contraseña',
                style: AppTextStyles.h1,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                _conToken
                    ? 'Define la contraseña con la que ingresarás a SIAA.'
                    : 'Escribe tu correo institucional y te enviaremos un enlace.',
                style: AppTextStyles.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),
              ..._campos(),
              if (state.paso == RecuperacionPaso.error) ...[
                const SizedBox(height: 16),
                Text(
                  state.mensaje ?? '',
                  style: const TextStyle(color: AppColors.accentRose),
                ),
              ],
              const SizedBox(height: 24),
              BotonRecuperacion(
                texto: _conToken ? 'Guardar contraseña' : 'Enviar enlace',
                cargando: cargando,
                onPressed: _enviar,
              ),
              const SizedBox(height: 12),
              _volver(),
            ],
          ),
        );
      },
    );
  }

  List<Widget> _campos() {
    if (!_conToken) {
      return [
        CampoRecuperacion(
          etiqueta: 'Correo Institucional',
          hint: 'usuario@universidad.edu.co',
          icono: Icons.email_outlined,
          controller: _correo,
          teclado: TextInputType.emailAddress,
          validator: (v) => (v == null || !v.contains('@'))
              ? 'Ingresa un correo electrónico válido'
              : null,
        ),
      ];
    }
    return [
      CampoRecuperacion(
        etiqueta: 'Nueva contraseña',
        hint: '••••••••••••',
        icono: Icons.lock_outline_rounded,
        controller: _clave,
        oculto: true,
        validator: validarNuevaClave,
      ),
      const SizedBox(height: 20),
      CampoRecuperacion(
        etiqueta: 'Confirmar contraseña',
        hint: '••••••••••••',
        icono: Icons.lock_reset_rounded,
        controller: _confirmacion,
        oculto: true,
        validator: (v) =>
            v != _clave.text ? 'Las contraseñas no coinciden' : null,
      ),
    ];
  }

  Widget _resultado(IconData icono, String titulo, String texto) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icono, size: 48, color: AppColors.primaryAccent),
        const SizedBox(height: 16),
        Text(titulo, style: AppTextStyles.h1, textAlign: TextAlign.center),
        const SizedBox(height: 8),
        Text(
          texto,
          style: AppTextStyles.bodyMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        _volver(),
      ],
    );
  }

  Widget _volver() {
    return TextButton(
      onPressed: () {
        if (Navigator.of(context).canPop()) Navigator.of(context).pop();
      },
      child: const Text('Volver a iniciar sesión'),
    );
  }
}
