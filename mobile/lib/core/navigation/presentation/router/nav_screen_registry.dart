// nav_screen_registry.dart - Registro desacoplado de rutas a pantallas (SIAA Movil)
// Principio Abierto/Cerrado: Para anadir una pantalla implementada,
// se edita unicamente este registro sin tocar el AppShell.
import 'package:flutter/material.dart';
import '../../../../features/home/presentation/screens/home_screen.dart';
import '../../../../features/justificaciones/presentation/screens/mis_justificaciones_screen.dart';
import '../../../../features/marcaje/presentation/screens/marcaje_grupal_screen.dart';
import '../../../../features/marcaje/presentation/screens/marcaje_historial_screen.dart';
import '../../../../features/marcaje/presentation/screens/marcaje_screen.dart';
import '../../../../features/horario/presentation/screens/mi_horario_screen.dart';
import '../../../../features/notificaciones/presentation/screens/bandeja_notificaciones_screen.dart';
import '../../../../features/privacidad/presentation/widgets/privacidad_view.dart';
import '../../../../shared/widgets/placeholder_screen.dart';

/// Registrador centralizado que mapea una ruta de navegacion a su Widget correspondiente.
class NavScreenRegistry {
  NavScreenRegistry._();

  /// [sesionIdObjetivo] llega de una notificación que apunta a una sesión concreta.
  static Widget buildScreenForRoute(String route, {String? sesionIdObjetivo}) {
    switch (route) {
      case '/shell/espacios':
      case '/shell/editor-gps':
        return const HomeScreen();

      case '/shell/inicio':
        return MarcajeScreen(sesionIdObjetivo: sesionIdObjetivo);

      case '/shell/horario':
        return const MiHorarioScreen();

      case '/shell/historial':
        return const MarcajeHistorialScreen();

      case '/shell/justificaciones':
        return const MisJustificacionesScreen();

      case '/shell/marcajes-admin':
        return const MarcajeHistorialScreen();

      case '/shell/reportes':
        return const PlaceholderScreen(
          titulo: 'Reportes',
          descripcion:
              'Indicadores de cumplimiento y asistencia. Disponible en F1-MVP.',
          icono: Icons.bar_chart_rounded,
        );

      case '/shell/aprobar-justificaciones':
        return const PlaceholderScreen(
          titulo: 'Revision de justificaciones',
          descripcion:
              'Aprueba o rechaza solicitudes de tu ambito. Disponible en F3.',
          icono: Icons.fact_check_rounded,
        );

      case '/shell/solapamientos':
        return const PlaceholderScreen(
          titulo: 'Solapamientos de espacios',
          descripcion:
              'Detecta poligonos que se superponen. Disponible en F1-MVP.',
          icono: Icons.layers_rounded,
        );

      case '/shell/marcaje-grupal':
        return const MarcajeGrupalScreen();

      case '/shell/perfil':
        return const PlaceholderScreen(
          titulo: 'Perfil',
          descripcion:
              'Datos de cuenta y dispositivo vinculado. Disponible en F1-MVP.',
          icono: Icons.person_rounded,
        );

      case '/shell/privacidad':
        return const PrivacidadView();

      case '/shell/notificaciones':
        return const BandejaNotificacionesScreen();

      default:
        return const PlaceholderScreen(
          titulo: 'Pantalla no encontrada',
          descripcion: 'Esta ruta no existe en la configuracion actual.',
          icono: Icons.search_off_rounded,
        );
    }
  }
}
