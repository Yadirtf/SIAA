import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../academico/presentation/bloc/academico_bloc.dart';
import '../../../academico/presentation/bloc/academico_event.dart';
import '../../../academico/presentation/screens/asignaciones_screen.dart';
import '../../../academico/presentation/screens/estructura_screen.dart';
import '../../../academico/presentation/screens/excepciones_screen.dart';
import '../../../academico/presentation/screens/periodos_screen.dart';
import '../../../geo/presentation/bloc/geo_bloc.dart';
import '../../../geo/presentation/bloc/geo_event.dart';
import '../../../geo/presentation/screens/bloques_screen.dart';
import '../../../geo/presentation/screens/espacios_screen.dart';
import '../../../geo/presentation/screens/sedes_screen.dart';
import '../../../geo/presentation/screens/solapamientos_screen.dart';
import '../../../dispositivos/presentation/screens/dispositivos_screen.dart';
import '../models/nav_item.dart';
import '../widgets/sidebar.dart';
import '../widgets/topbar.dart';
import 'dashboard_home_screen.dart';

class DashboardShell extends StatefulWidget {
  const DashboardShell({super.key});

  @override
  State<DashboardShell> createState() => _DashboardShellState();
}

class _DashboardShellState extends State<DashboardShell> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  NavSection _currentSection = NavSection.inicio;

  @override
  void initState() {
    super.initState();
    // Pre-load data from real Go backend
    context.read<GeoBloc>().add(const LoadGeoDataEvent());
    context.read<AcademicoBloc>().add(const LoadAcademicoDataEvent());
  }

  void _onSectionSelected(NavSection section) {
    setState(() => _currentSection = section);
    if (_scaffoldKey.currentState?.isDrawerOpen ?? false) {
      Navigator.of(context).pop();
    }
  }

  Widget _buildBody() {
    switch (_currentSection) {
      case NavSection.inicio:
        return DashboardHomeScreen(onNavigate: _onSectionSelected);
      case NavSection.sedes:
        return const SedesScreen();
      case NavSection.bloques:
        return const BloquesScreen();
      case NavSection.espacios:
        return const EspaciosScreen();
      case NavSection.solapamientos:
        return const SolapamientosScreen();
      case NavSection.periodos:
        return const PeriodosScreen();
      case NavSection.estructura:
        return const EstructuraScreen();
      case NavSection.asignaciones:
        return const AsignacionesScreen();
      case NavSection.excepciones:
        return const ExcepcionesScreen();
      case NavSection.dispositivos:
        return const DispositivosScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 960;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.background,
      drawer: isWide
          ? null
          : Drawer(
              child: SafeArea(
                child: DashboardSidebar(
                  currentSection: _currentSection,
                  onSectionSelected: _onSectionSelected,
                ),
              ),
            ),
      body: SafeArea(
        child: Row(
          children: [
            if (isWide)
              DashboardSidebar(
                currentSection: _currentSection,
                onSectionSelected: _onSectionSelected,
              ),
            Expanded(
              child: Column(
                children: [
                  DashboardTopbar(
                    currentSection: _currentSection,
                    onMenuPressed: isWide
                        ? null
                        : () => _scaffoldKey.currentState?.openDrawer(),
                  ),
                  Expanded(child: _buildBody()),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
