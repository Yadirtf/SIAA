// Pantalla de login para la consola web administrativa — T-AUT-01.8
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import '../bloc/auth_bloc.dart';
import '../widgets/web_login_brand_panel.dart';

class WebLoginScreen extends StatefulWidget {
  const WebLoginScreen({super.key});

  static const routeName = '/login';

  @override
  State<WebLoginScreen> createState() => _WebLoginScreenState();
}

class _WebLoginScreenState extends State<WebLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _correoController = TextEditingController(text: 'admin@siaa.edu.co');
  final _passwordController = TextEditingController(text: 'Admin12345678*');
  bool _obscurePassword = true;

  @override
  void dispose() {
    _correoController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onLogin() {
    if (!_formKey.currentState!.validate()) return;
    context.read<WebAuthBloc>().add(
      WebAuthLoginRequested(
        correo: _correoController.text.trim(),
        password: _passwordController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 768;

    return BlocConsumer<WebAuthBloc, WebAuthState>(
      listener: (context, state) {
        if (state is WebAuthAuthenticated) {
          Navigator.of(context).pushReplacementNamed('/dashboard');
        } else if (state is WebAuthUnauthenticated && state.mensajeError != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.mensajeError!),
              backgroundColor: SIAAColors.asistenciaAusente,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      builder: (context, state) {
        final loading = state is WebAuthLoading;

        return Scaffold(
          body: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (!isMobile)
                const Expanded(
                  child: WebLoginBrandPanel(),
                ),
              SizedBox(
                width: isMobile ? size.width : 480,
                child: ColoredBox(
                  color: theme.colorScheme.surface,
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(SIAASpacing.xxl),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 420),
                        child: _buildLoginForm(theme, loading),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLoginForm(ThemeData theme, bool loading) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Acceso administrativo',
          style: SIAATypography.headlineMedium.copyWith(
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: SIAASpacing.xs),
        Text(
          'Ingresa con tu correo institucional',
          style: SIAATypography.bodyMedium.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
        const SizedBox(height: SIAASpacing.xxl),

        Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _correoController,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Correo institucional',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'El correo es obligatorio';
                  if (!v.contains('@')) return 'Ingresa un correo válido';
                  return null;
                },
              ),
              const SizedBox(height: SIAASpacing.md),

              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _onLogin(),
                decoration: InputDecoration(
                  labelText: 'Contraseña',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'La contraseña es obligatoria';
                  return null;
                },
              ),
              const SizedBox(height: SIAASpacing.lg),

              SizedBox(
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: loading ? null : _onLogin,
                  icon: loading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation(Colors.white),
                          ),
                        )
                      : const Icon(Icons.login_rounded, size: 20),
                  label: Text(loading ? 'Ingresando...' : 'Ingresar'),
                ),
              ),

              const SizedBox(height: SIAASpacing.md),
              Align(
                alignment: Alignment.center,
                child: TextButton(
                  onPressed: () {},
                  child: const Text('¿Olvidaste tu contraseña?'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
