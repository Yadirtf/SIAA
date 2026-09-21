// main.dart — Punto de entrada de la consola web administrativa SIAA
// T-AUT-01.8, T-PLT-03.8 (i18n), T-PLT-03.3 (Design System)
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/theme/app_theme.dart';
import 'features/auth/presentation/screens/web_login_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const SIAAWebAdminApp());
}

class SIAAWebAdminApp extends StatelessWidget {
  const SIAAWebAdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
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

      home: const WebLoginScreen(),
    );
  }
}
