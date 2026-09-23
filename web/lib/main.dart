// main.dart — Punto de entrada de la consola web administrativa SIAA
// T-AUT-01.8, T-PLT-03.8 (i18n), T-PLT-03.3 (Design System)
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/theme/app_theme.dart';
import 'features/auth/data/auth_repository.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/auth/presentation/screens/web_login_screen.dart';
import 'features/dashboard/presentation/screens/dashboard_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const SIAAWebAdminApp());
}

class SIAAWebAdminApp extends StatelessWidget {
  const SIAAWebAdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider(create: (_) => WebAuthRepository()),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (ctx) => WebAuthBloc(
              repository: ctx.read<WebAuthRepository>(),
            )..add(const WebAuthCheckSessionRequested()),
          ),
        ],
        child: MaterialApp(
          title: 'SIAA — Consola de Administración',
          debugShowCheckedModeBanner: false,

          // Sistema de diseño — T-PLT-03.3
          theme: SIAATheme.light,
          darkTheme: SIAATheme.dark,
          themeMode: ThemeMode.light,

          // Localización español Colombia
          locale: const Locale('es', 'CO'),
          supportedLocales: const [
            Locale('es', 'CO'),
            Locale('es', ''),
          ],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],

          routes: {
            '/login': (_) => const WebLoginScreen(),
            '/dashboard': (_) => const DashboardScreen(),
          },

          home: const _WebRootRouter(),
        ),
      ),
    );
  }
}

class _WebRootRouter extends StatefulWidget {
  const _WebRootRouter();

  @override
  State<_WebRootRouter> createState() => _WebRootRouterState();
}

class _WebRootRouterState extends State<_WebRootRouter> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _evaluarRuta(context.read<WebAuthBloc>().state);
    });
  }

  void _evaluarRuta(WebAuthState state) {
    if (!mounted) return;
    if (state is WebAuthAuthenticated) {
      Navigator.of(context).pushReplacementNamed('/dashboard');
    } else if (state is WebAuthUnauthenticated) {
      Navigator.of(context).pushReplacementNamed('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<WebAuthBloc, WebAuthState>(
      listener: (context, state) => _evaluarRuta(state),
      child: const Scaffold(
        backgroundColor: Color(0xFF0F172A),
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white70),
          ),
        ),
      ),
    );
  }
}
