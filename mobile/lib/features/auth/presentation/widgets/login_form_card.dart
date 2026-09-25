import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/loading_button.dart';
import '../bloc/auth_bloc.dart';

class LoginFormCard extends StatefulWidget {
  const LoginFormCard({super.key});

  @override
  State<LoginFormCard> createState() => _LoginFormCardState();
}

class _LoginFormCardState extends State<LoginFormCard> {
  final _formKey = GlobalKey<FormState>();
  final _correoController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _correoController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onLogin() {
    if (!_formKey.currentState!.validate()) return;
    context.read<AuthBloc>().add(AuthLoginRequested(
          correo: _correoController.text.trim(),
          password: _passwordController.text,
        ));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? SIAAColors.surfaceDark.withOpacity(0.8)
            : SIAAColors.surfaceLight,
        borderRadius: SIAASpacing.radiusLg,
        border: Border.all(
          color: isDark ? SIAAColors.neutral700 : SIAAColors.neutral200,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
            blurRadius: 32,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(SIAASpacing.xl),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Iniciar sesión',
              style: SIAATypography.headlineMedium.copyWith(
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: SIAASpacing.xs),
            Text(
              'Usa tu correo institucional',
              style: SIAATypography.bodyMedium.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: SIAASpacing.xl),

            // Campo correo
            TextFormField(
              controller: _correoController,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autocorrect: false,
              decoration: const InputDecoration(
                labelText: 'Correo institucional',
                hintText: 'usuario@universidad.edu.co',
                prefixIcon: Icon(Icons.email_outlined),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'El correo es obligatorio';
                if (!v.contains('@')) return 'Ingresa un correo válido';
                return null;
              },
            ),
            const SizedBox(height: SIAASpacing.md),

            // Campo contraseña
            TextFormField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _onLogin(),
              decoration: InputDecoration(
                labelText: 'Contraseña',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                  tooltip: _obscurePassword ? 'Mostrar' : 'Ocultar',
                ),
              ),
              validator: (v) {
                if (v == null || v.isEmpty)
                  return 'La contraseña es obligatoria';
                return null;
              },
            ),
            const SizedBox(height: SIAASpacing.xs),

            // Olvidé mi contraseña
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () =>
                    Navigator.of(context).pushNamed('/recuperar-password'),
                child: Text(
                  '¿Olvidaste tu contraseña?',
                  style: SIAATypography.labelLarge.copyWith(
                    color: SIAAColors.primary500,
                  ),
                ),
              ),
            ),
            const SizedBox(height: SIAASpacing.lg),

            // Botón de login
            BlocBuilder<AuthBloc, AuthState>(
              builder: (context, state) {
                return SIAALoadingButton(
                  label: 'Iniciar sesión',
                  isLoading: state is AuthLoading,
                  onPressed: _onLogin,
                  icon: Icons.login_rounded,
                );
              },
            ),

            const SizedBox(height: SIAASpacing.lg),

            // Aviso de privacidad
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.lock_outline,
                  size: 14,
                  color: theme.colorScheme.onSurface.withOpacity(0.4),
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    'Tu ubicación solo se captura al marcar asistencia',
                    style: SIAATypography.caption.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.45),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
