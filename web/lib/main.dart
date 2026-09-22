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

class _WebRootRouter extends StatelessWidget {
  const _WebRootRouter();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<WebAuthBloc, WebAuthState>(
      builder: (context, state) {
        if (state is WebAuthAuthenticated) {
          return const DashboardScreen();
        }
        return const WebLoginScreen();
      },
    );
  }
}
