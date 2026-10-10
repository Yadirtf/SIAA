// nav_screen_registry.dart - Registro desacoplado de rutas a pantallas (SIAA Movil)
// Principio Abierto/Cerrado: Para anadir una pantalla implementada,
// se edita unicamente este registro sin tocar el AppShell.
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../features/espacios/presentation/screens/espacios_screen.dart';
import '../../../../features/espacios/presentation/screens/solapamientos_screen.dart';
import '../../../../features/home/presentation/screens/editor_gps_screen.dart';
import '../../../../features/horario/presentation/screens/mi_horario_screen.dart';
import '../../../../features/justificaciones/presentation/screens/mis_justificaciones_screen.dart';
import '../../../../features/justificaciones_revision/presentation/screens/revision_justificaciones_screen.dart';
import '../../../../features/marcaje/presentation/screens/marcaje_grupal_screen.dart';
import '../../../../features/marcaje/presentation/screens/marcaje_historial_screen.dart';
import '../../../../features/marcaje/presentation/screens/marcaje_screen.dart';
import '../../../../features/marcajes_admin/presentation/screens/marcajes_admin_screen.dart';
import '../../../../features/notificaciones/presentation/screens/bandeja_notificaciones_screen.dart';
import '../../../../features/parametros/data/parametros_data.dart';
import '../../../../features/parametros/presentation/bloc/parametros_bloc.dart';
import '../../../../features/parametros/presentation/screens/parametros_screen.dart';
import '../../../../features/perfil/presentation/screens/perfil_screen.dart';
import '../../../../features/privacidad/presentation/screens/derechos_screen.dart';
import '../../../../features/privacidad/presentation/widgets/privacidad_view.dart';
import '../../../../features/reportes/presentation/screens/reportes_screen.dart';
import '../../../../shared/widgets/placeholder_screen.dart';

/// Registrador centralizado que mapea una ruta de navegacion a su Widget correspondiente.
class NavScreenRegistry {
  NavScreenRegistry._();

  /// [sesionIdObjetivo] llega de una notificación que apunta a una sesión concreta.
  static Widget buildScreenForRoute(String route, {String? sesionIdObjetivo}) {
    switch (route) {
      case '/shell/espacios':
        return const EspaciosScreen();

      case '/shell/editor-gps':
        return const EditorGpsScreen();

      case '/shell/inicio':
        return MarcajeScreen(sesionIdObjetivo: sesionIdObjetivo);

      case '/shell/horario':
        return const MiHorarioScreen();

      case '/shell/historial':
        return const MarcajeHistorialScreen();

      case '/shell/justificaciones':
        return const MisJustificacionesScreen();

      case '/shell/marcajes-admin':
        return const MarcajesAdminScreen();

      case '/shell/reportes':
        return const ReportesScreen();

      case '/shell/aprobar-justificaciones':
        return const RevisionJustificacionesScreen();

      case '/shell/solapamientos':
        return const SolapamientosScreen();

      case '/shell/parametros':
        return BlocProvider(
          create: (_) => ParametrosBloc(repository: ParametrosRepositoryImpl()),
          child: const ParametrosScreen(),
        );

      case '/shell/marcaje-grupal':
        return const MarcajeGrupalScreen();

      case '/shell/perfil':
        return const PerfilScreen();

      case '/shell/privacidad':
        return const PrivacidadView();

      case '/shell/notificaciones':
        return const BandejaNotificacionesScreen();

      case '/shell/derechos':
        return const DerechosScreen();

      default:
        return const PlaceholderScreen(
          titulo: 'Pantalla no encontrada',
          descripcion: 'Esta ruta no existe en la configuracion actual.',
          icono: Icons.search_off_rounded,
        );
    }
  }
}
