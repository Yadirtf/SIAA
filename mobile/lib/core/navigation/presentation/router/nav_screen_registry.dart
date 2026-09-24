// nav_screen_registry.dart - Registro desacoplado de rutas a pantallas (SIAA Movil)
// Principio Abierto/Cerrado: Para anadir una pantalla implementada,
// se edita unicamente este registro sin tocar el AppShell.
import 'package:flutter/material.dart';
import '../../../../features/home/presentation/screens/home_screen.dart';
import '../../../../shared/widgets/placeholder_screen.dart';

/// Registrador centralizado que mapea una ruta de navegacion a su Widget correspondiente.
class NavScreenRegistry {
  NavScreenRegistry._();

  static Widget buildScreenForRoute(String route) {
    switch (route) {
      case '/shell/espacios':
      case '/shell/editor-gps':
        return const HomeScreen();

      case '/shell/inicio':
        return const PlaceholderScreen(
          titulo: 'Marcar asistencia',
          descripcion: 'El modulo de marcaje estara disponible en F1-MVP.',
          icono: Icons.touch_app_rounded,
        );

      case '/shell/horario':
        return const PlaceholderScreen(
          titulo: 'Mi horario',
          descripcion:
              'Consulta tus sesiones de la semana. Disponible en F1-MVP.',
          icono: Icons.calendar_today_rounded,
        );

      case '/shell/historial':
        return const PlaceholderScreen(
          titulo: 'Historial de marcajes',
          descripcion: 'Tu cronologia de asistencia. Disponible en F1-MVP.',
          icono: Icons.history_rounded,
        );

      case '/shell/justificaciones':
        return const PlaceholderScreen(
          titulo: 'Justificaciones',
          descripcion:
              'Radica y consulta tus justificaciones. Disponible en F3.',
          icono: Icons.edit_note_rounded,
        );

      case '/shell/marcajes-admin':
        return const PlaceholderScreen(
          titulo: 'Gestion de marcajes',
          descripcion: 'Ajuste y anulacion de marcajes. Disponible en F1-MVP.',
          icono: Icons.manage_search_rounded,
        );

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
        return const PlaceholderScreen(
          titulo: 'Marcaje grupal',
          descripcion:
              'Registra asistencia de un grupo de estudiantes. Disponible en F3.',
          icono: Icons.group_rounded,
        );

      case '/shell/perfil':
        return const PlaceholderScreen(
          titulo: 'Perfil',
          descripcion:
              'Datos de cuenta y dispositivo vinculado. Disponible en F1-MVP.',
          icono: Icons.person_rounded,
        );

      case '/shell/privacidad':
        return const PlaceholderScreen(
          titulo: 'Aviso de privacidad',
          descripcion:
              'Politica de tratamiento de datos personales (Ley 1581/2012).',
          icono: Icons.privacy_tip_rounded,
        );

      default:
        return const PlaceholderScreen(
          titulo: 'Pantalla no encontrada',
          descripcion: 'Esta ruta no existe en la configuracion actual.',
          icono: Icons.search_off_rounded,
        );
    }
  }
}
