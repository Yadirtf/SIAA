// main.dart — Punto de entrada de la app móvil SIAA
// T-PLT-03.1, T-PLT-03.8, T-PLT-03.9
// US-LEG-01: consentimiento antes de cualquier permiso de ubicación.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/theme/app_theme.dart';
import 'features/auth/data/auth_repository.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/auth/presentation/screens/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Orientación solo vertical en móvil
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Estilo de barra de sistema
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));

  runApp(const SIAAApp());
}

class SIAAApp extends StatelessWidget {
  const SIAAApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider(create: (_) => AuthRepository()),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (ctx) => AuthBloc(
              repository: ctx.read<AuthRepository>(),
            )..add(AuthSessionChecked()),
          ),
        ],
        child: MaterialApp(
          title: 'SIAA',
          debugShowCheckedModeBanner: false,

          // ─── Temas — T-PLT-03.3 ───────────────────────────
          theme: SIAATheme.light,
          darkTheme: SIAATheme.dark,
          themeMode: ThemeMode.system, // adopta el tema del sistema (RNF-USA-004)

          // ─── Internacionalización — T-PLT-03.8 ────────────
          locale: const Locale('es', 'CO'),
          supportedLocales: const [
            Locale('es', 'CO'),
          ],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],

          // ─── Navegación ───────────────────────────────────
          initialRoute: '/splash',
          routes: {
            '/splash': (_) => const _SplashRouter(),
            '/login': (_) => const LoginScreen(),
            // TODO: agregar rutas de home, marcaje, historial
            // '/home': (_) => const HomeScreen(),
            // '/recuperar-password': (_) => const RecoverPasswordScreen(),
          },

          // ─── Manejo global de errores ─────────────────────
          builder: (context, child) {
            // Sobreescribe el error banner rojo en debug
            ErrorWidget.builder = (errorDetails) => _ErrorFallback(
              message: errorDetails.exceptionAsString(),
            );
            return child ?? const SizedBox.shrink();
          },
        ),
      ),
    );
  }
}

/// Router de splash que decide adónde ir según el estado de autenticación.
class _SplashRouter extends StatelessWidget {
  const _SplashRouter();

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthAuthenticated) {
          Navigator.of(context).pushReplacementNamed('/home');
        } else if (state is AuthUnauthenticated) {
          Navigator.of(context).pushReplacementNamed('/login');
        }
      },
      child: const _SplashScreen(),
    );
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: SIAAColors.primary500,
                borderRadius: SIAASpacing.radiusLg,
                boxShadow: [
                  BoxShadow(
                    color: SIAAColors.primary500.withOpacity(0.25),
                    blurRadius: 32,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: const Icon(
                Icons.school_rounded,
                color: Colors.white,
                size: 48,
              ),
            ),
            const SizedBox(height: SIAASpacing.md),
            Text(
              'SIAA',
              style: SIAATypography.displayLarge.copyWith(
                color: SIAAColors.primary500,
                fontWeight: FontWeight.w700,
                letterSpacing: 3,
              ),
            ),
            const SizedBox(height: SIAASpacing.xl),
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor: AlwaysStoppedAnimation<Color>(SIAAColors.primary500),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Widget de fallback de error — no muestra detalles técnicos al usuario.
class _ErrorFallback extends StatelessWidget {
  final String message;
  const _ErrorFallback({required this.message});

  @override
  Widget build(BuildContext context) {
    return Material(
      child: Container(
        color: SIAAColors.backgroundLight,
        alignment: Alignment.center,
        padding: const EdgeInsets.all(SIAASpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.warning_amber_rounded,
              color: SIAAColors.asistenciaAusente,
              size: 48,
            ),
            const SizedBox(height: SIAASpacing.md),
            const Text(
              'Algo salió mal',
              style: SIAATypography.headlineMedium,
            ),
            const SizedBox(height: SIAASpacing.sm),
            const Text(
              'Reinicia la aplicación. Si el problema persiste, contacta soporte.',
              textAlign: TextAlign.center,
              style: SIAATypography.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
