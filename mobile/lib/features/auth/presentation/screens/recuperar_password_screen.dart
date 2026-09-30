// Pantalla de recuperación de contraseña - US-AUT-04 (AC-01..AC-05)
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_theme.dart';
import '../../data/auth_repository.dart';
import '../cubit/recuperacion_cubit.dart';

class RecuperarPasswordScreen extends StatelessWidget {
  const RecuperarPasswordScreen({super.key});

  static const routeName = '/recuperar-password';

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (ctx) => RecuperacionCubit(ctx.read<AuthRepository>()),
      child: Scaffold(
        appBar: AppBar(title: const Text('Recuperar contraseña')),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(SIAASpacing.lg),
            child: BlocBuilder<RecuperacionCubit, RecuperacionState>(
              builder: (context, state) {
                if (state.paso == RecuperacionPaso.confirmada) {
                  return const _Confirmada();
                }
                return _Formulario(state: state);
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _Formulario extends StatefulWidget {
  final RecuperacionState state;

  const _Formulario({required this.state});

  @override
  State<_Formulario> createState() => _FormularioState();
}

class _FormularioState extends State<_Formulario> {
  final _formKey = GlobalKey<FormState>();
  final _correo = TextEditingController();
  final _codigo = TextEditingController();
  final _clave = TextEditingController();
  final _confirmacion = TextEditingController();
  RecuperacionPaso _pasoVisible = RecuperacionPaso.correo;

  @override
  void dispose() {
    _correo.dispose();
    _codigo.dispose();
    _clave.dispose();
    _confirmacion.dispose();
    super.dispose();
  }

  void _enviar() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final cubit = context.read<RecuperacionCubit>();
    if (_pasoVisible == RecuperacionPaso.codigo) {
      cubit.confirmar(_codigo.text, _clave.text);
    } else {
      cubit.solicitar(_correo.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final cargando = state.paso == RecuperacionPaso.enviando;
    if (!cargando) _pasoVisible = state.paso;
    final enCodigo = _pasoVisible == RecuperacionPaso.codigo;
    final estiloTexto = SIAATypography.bodyMedium.copyWith(
      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
    );
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            enCodigo
                ? 'Te enviamos un correo con un enlace. Ábrelo en el navegador o '
                    'pega aquí el enlace o el código para definir tu contraseña.'
                : 'Escribe tu correo institucional y te enviaremos un enlace para '
                    'definir una nueva contraseña.',
            style: estiloTexto,
          ),
          const SizedBox(height: SIAASpacing.lg),
          if (!enCodigo)
            TextFormField(
              controller: _correo,
              keyboardType: TextInputType.emailAddress,
              autocorrect: false,
              decoration: const InputDecoration(
                labelText: 'Correo institucional',
                prefixIcon: Icon(Icons.email_outlined),
              ),
              validator: (v) => (v == null || !v.contains('@'))
                  ? 'Ingresa un correo válido'
                  : null,
            )
          else ...[
            TextFormField(
              controller: _codigo,
              autocorrect: false,
              decoration: const InputDecoration(
                labelText: 'Enlace o código del correo',
                prefixIcon: Icon(Icons.key_outlined),
              ),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Pega el enlace o el código'
                  : null,
            ),
            const SizedBox(height: SIAASpacing.md),
            TextFormField(
              controller: _clave,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Nueva contraseña',
                prefixIcon: Icon(Icons.lock_outline),
              ),
              validator: validarNuevaClave,
            ),
            const SizedBox(height: SIAASpacing.md),
            TextFormField(
              controller: _confirmacion,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Confirmar contraseña',
                prefixIcon: Icon(Icons.lock_reset),
              ),
              validator: (v) =>
                  v != _clave.text ? 'Las contraseñas no coinciden' : null,
            ),
          ],
          if (state.error != null) ...[
            const SizedBox(height: SIAASpacing.md),
            Text(
              state.error!,
              style: SIAATypography.bodyMedium
                  .copyWith(color: SIAAColors.asistenciaAusente),
            ),
          ],
          const SizedBox(height: SIAASpacing.lg),
          FilledButton(
            onPressed: cargando ? null : _enviar,
            child: cargando
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(enCodigo ? 'Guardar contraseña' : 'Enviar enlace'),
          ),
          if (!enCodigo)
            TextButton(
              onPressed: context.read<RecuperacionCubit>().yaTengoCodigo,
              child: const Text('Ya tengo un código'),
            ),
        ],
      ),
    );
  }
}

class _Confirmada extends StatelessWidget {
  const _Confirmada();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: SIAASpacing.xl),
        const Icon(Icons.verified_user_outlined,
            size: 56, color: SIAAColors.asistenciaPresente),
        const SizedBox(height: SIAASpacing.md),
        Text('Contraseña actualizada', style: SIAATypography.titleLarge),
        const SizedBox(height: SIAASpacing.sm),
        const Text(
          'Ya puedes iniciar sesión. Las sesiones abiertas en otros equipos se cerraron.',
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: SIAASpacing.lg),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Volver a iniciar sesión'),
        ),
      ],
    );
  }
}
