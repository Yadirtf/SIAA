// Pantalla de login para la consola web administrativa — T-AUT-01.8
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import '../bloc/auth_bloc.dart';

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
            children: [
              // Panel izquierdo — branding (solo en pantallas >= 768px)
              if (!isMobile)
                Expanded(
                  child: _buildBrandPanel(theme),
                ),

              // Panel derecho — formulario
              Container(
                width: isMobile ? size.width : 480,
                height: size.height,
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
            ],
          ),
        );
      },
    );
  }

  Widget _buildBrandPanel(ThemeData theme) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1E3A8A),
            Color(0xFF2563EB),
            Color(0xFF7C3AED),
          ],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(SIAASpacing.xxl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Logo
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: SIAASpacing.radiusMd,
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                ),
              ),
              child: const Icon(
                Icons.school_rounded,
                color: Colors.white,
                size: 36,
              ),
            ),
            const SizedBox(height: SIAASpacing.xl),

            const Text(
              'SIAA',
              style: TextStyle(
                fontFamily: 'Inter',
                color: Colors.white,
                fontSize: 48,
                fontWeight: FontWeight.w700,
                letterSpacing: 3,
              ),
            ),
            const SizedBox(height: SIAASpacing.sm),
            Text(
              'Consola Administrativa',
              style: TextStyle(
                fontFamily: 'Inter',
                color: Colors.white.withOpacity(0.8),
                fontSize: 20,
                fontWeight: FontWeight.w400,
              ),
            ),
            const SizedBox(height: SIAASpacing.xxxl),

            // Features
            ..._buildFeatures(),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildFeatures() {
    final features = [
      (Icons.location_on_outlined, 'Validación por geolocalización GPS'),
      (Icons.map_outlined, 'Cartografía de espacios académicos'),
      (Icons.schedule_outlined, 'Gestión de horarios y sesiones'),
      (Icons.bar_chart_outlined, 'Reportes de cumplimiento docente'),
      (Icons.security_outlined, 'Auditoría completa e inmutable'),
    ];

    return features.map((f) => Padding(
      padding: const EdgeInsets.only(bottom: SIAASpacing.md),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: SIAASpacing.radiusSm,
            ),
            child: Icon(f.$1, color: Colors.white, size: 20),
          ),
          const SizedBox(width: SIAASpacing.md),
          Text(
            f.$2,
            style: TextStyle(
              fontFamily: 'Inter',
              color: Colors.white.withOpacity(0.85),
              fontSize: 15,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    )).toList();
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
            color: theme.colorScheme.onSurface.withOpacity(0.6),
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

              // Botón de acceso
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

  void _onLogin() {
    if (!_formKey.currentState!.validate()) return;
    context.read<WebAuthBloc>().add(
      WebAuthLoginRequested(
        correo: _correoController.text.trim(),
        password: _passwordController.text.trim(),
      ),
    );
  }
}
