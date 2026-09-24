// app_routes.dart - Nombres y mapeo centralizado de rutas (SIAA Movil)
// Desacopla la declaracion de rutas de main.dart
import 'package:flutter/material.dart';
import '../../../features/auth/presentation/screens/login_screen.dart';
import '../../../features/splash/presentation/screens/splash_router.dart';
import '../presentation/screens/app_shell.dart';

class AppRoutes {
  AppRoutes._();

  static const splash = '/splash';
  static const login = '/login';
  static const shell = '/shell';

  // Sub-rutas del shell
  static const inicio = '/shell/inicio';
  static const horario = '/shell/horario';
  static const historial = '/shell/historial';
  static const justificaciones = '/shell/justificaciones';
  static const espacios = '/shell/espacios';
  static const editorGps = '/shell/editor-gps';
  static const marcajesAdmin = '/shell/marcajes-admin';
  static const reportes = '/shell/reportes';
  static const aprobarJustificaciones = '/shell/aprobar-justificaciones';
  static const solapamientos = '/shell/solapamientos';
  static const marcajeGrupal = '/shell/marcaje-grupal';
  static const perfil = '/shell/perfil';
  static const privacidad = '/shell/privacidad';

  /// Genera el mapa de rutas para MaterialApp.
  /// Todas las sub-rutas `/shell/*` son alojadas por [AppShell].
  static Map<String, WidgetBuilder> get routes => {
        splash: (_) => const SplashRouter(),
        login: (_) => const LoginScreen(),
        shell: (_) => const AppShell(),
        inicio: (_) => const AppShell(),
        horario: (_) => const AppShell(),
        historial: (_) => const AppShell(),
        justificaciones: (_) => const AppShell(),
        espacios: (_) => const AppShell(),
        editorGps: (_) => const AppShell(),
        marcajesAdmin: (_) => const AppShell(),
        reportes: (_) => const AppShell(),
        aprobarJustificaciones: (_) => const AppShell(),
        solapamientos: (_) => const AppShell(),
        marcajeGrupal: (_) => const AppShell(),
        perfil: (_) => const AppShell(),
        privacidad: (_) => const AppShell(),
      };
}
