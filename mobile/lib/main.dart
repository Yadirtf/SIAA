// main.dart - Punto de entrada y bootstrap de la app movil SIAA
// T-PLT-03.1, T-PLT-03.8, T-PLT-03.9
// US-LEG-01: consentimiento antes de cualquier permiso de ubicacion.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/navigation/config/app_routes.dart';
import 'core/navigation/presentation/bloc/nav_bloc.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/data/auth_repository.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'shared/widgets/error_fallback.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Orientacion solo vertical en movil
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Estilo de barra de sistema
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));

  ErrorWidget.builder = (errorDetails) => ErrorFallback(
        message: errorDetails.exceptionAsString(),
      );

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
          // NavBloc: se inicializa via NavInicializado al autenticar.
          // Consume los permisos resueltos por el backend (RF-ROL-003).
          BlocProvider(create: (_) => NavBloc()),
        ],
        child: MaterialApp(
          title: 'SIAA',
          debugShowCheckedModeBanner: false,

          // Temas - T-PLT-03.3
          theme: SIAATheme.light,
          darkTheme: SIAATheme.dark,
          themeMode: ThemeMode.system, // RNF-USA-004

          // Internacionalizacion - T-PLT-03.8
          locale: const Locale('es', 'CO'),
          supportedLocales: const [Locale('es', 'CO')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],

          // Navegacion centralizada en AppRoutes
          initialRoute: AppRoutes.splash,
          routes: AppRoutes.routes,
        ),
      ),
    );
  }
}
