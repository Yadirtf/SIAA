// Dashboard administrativo para la consola web SIAA — T-PLT-01.8, US-GEO-01
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../academico/data/academico_repository.dart';
import '../../../academico/presentation/asignaciones/asignaciones_tab.dart';
import '../../../academico/presentation/estructura/estructura_tab.dart';
import '../../../academico/presentation/excepciones/excepciones_tab.dart';
import '../../../academico/presentation/periodos/periodos_tab.dart';
import '../bloc/dashboard_bloc.dart';
import '../bloc/dashboard_event.dart';
import '../bloc/dashboard_state.dart';
import '../widgets/sidebar/dashboard_sidebar.dart';
import '../widgets/topbar/dashboard_topbar.dart';
import '../widgets/views/dashboard_espacios_view.dart';
import '../widgets/views/dashboard_sedes_bloques_view.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  static const routeName = '/dashboard';

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => DashboardBloc()..add(const DashboardCargarDatosRequested()),
      child: const _DashboardView(),
    );
  }
}

class _DashboardView extends StatefulWidget {
  const _DashboardView();

  @override
  State<_DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<_DashboardView> {
  final AcademicoRepository _academicoRepo = AcademicoRepository();

  @override
  Widget build(BuildContext context) {
    return BlocListener<DashboardBloc, DashboardState>(
      listener: (context, state) {
        if (state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage!),
              backgroundColor: SIAAColors.asistenciaAusente,
            ),
          );
          context.read<DashboardBloc>().add(const DashboardLimpiarMensajesRequested());
        }
        if (state.successMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.successMessage!),
              backgroundColor: SIAAColors.asistenciaPresente,
            ),
          );
          context.read<DashboardBloc>().add(const DashboardLimpiarMensajesRequested());
        }
      },
      child: BlocBuilder<DashboardBloc, DashboardState>(
        builder: (context, state) {
          final bloc = context.read<DashboardBloc>();

          return Scaffold(
            backgroundColor: const Color(0xFFF8FAFC),
            body: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ─── Barra Lateral (Sidebar) ───────────────────────────
                SizedBox(
                  width: 260,
                  height: double.infinity,
                  child: DashboardSidebar(
                    selectedNavIndex: state.selectedNavIndex,
                    onNavItemSelected: (index) =>
                        bloc.add(DashboardCambiarNavIndexRequested(index)),
                  ),
                ),

                // ─── Contenido Principal ───────────────────────────────
                Expanded(
                  child: Column(
                    children: [
                      DashboardTopbar(
                        title: _obtenerTituloSeccion(state.selectedNavIndex),
                        onRefresh: () => bloc.add(const DashboardCargarDatosRequested()),
                      ),
                      Expanded(
                        child: _construirContenidoCentral(context, state, bloc),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  String _obtenerTituloSeccion(int index) {
    switch (index) {
      case 0:
        return 'Gestión de Espacios y Cartografía';
      case 1:
        return 'Sedes y Bloques Físicos';
      case 2:
        return 'Gestión de Periodos Académicos';
      case 3:
        return 'Estructura Curricular y Docente';
      case 4:
        return 'Asignaciones de Espacios y Horarios';
      case 5:
        return 'Calendario de Excepciones y Feriados';
      default:
        return 'Consola de Administración';
    }
  }

  Widget _construirContenidoCentral(
    BuildContext context,
    DashboardState state,
    DashboardBloc bloc,
  ) {
    switch (state.selectedNavIndex) {
      case 0:
        if (state.status == DashboardStatus.loading && state.sedes.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state.status == DashboardStatus.failure && state.sedes.isEmpty) {
          return _construirErrorGeo(state, bloc);
        }
        return DashboardEspaciosView(
          key: const ValueKey('tab_espacios'),
          state: state,
          onCrearEspacio: ({
            required String sedeId,
            String? bloqueId,
            required int piso,
            required String codigo,
            required String nombre,
            required int capacidad,
            required String tipo,
          }) {
            bloc.add(DashboardCrearEspacioRequested(
              sedeId: sedeId,
              bloqueId: bloqueId,
              piso: piso,
              codigo: codigo,
              nombre: nombre,
              capacidad: capacidad,
              tipo: tipo,
            ));
          },
          onEliminarEspacio: (id) => bloc.add(DashboardEliminarEspacioRequested(id)),
        );
      case 1:
        if (state.status == DashboardStatus.loading && state.sedes.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state.status == DashboardStatus.failure && state.sedes.isEmpty) {
          return _construirErrorGeo(state, bloc);
        }
        return DashboardSedesBloquesView(
          key: const ValueKey('tab_sedes_bloques'),
          state: state,
          onCrearSede: ({
            required String codigo,
            required String nombre,
            String? direccion,
          }) {
            bloc.add(DashboardCrearSedeRequested(
              codigo: codigo,
              nombre: nombre,
              direccion: direccion,
            ));
          },
          onCrearBloque: ({
            required String sedeId,
            required String codigo,
            required String nombre,
            required List<int> pisos,
          }) {
            bloc.add(DashboardCrearBloqueRequested(
              sedeId: sedeId,
              codigo: codigo,
              nombre: nombre,
              pisos: pisos,
            ));
          },
        );
      case 2:
        return PeriodosTab(
          key: const ValueKey('tab_periodos'),
          repository: _academicoRepo,
        );
      case 3:
        return EstructuraTab(
          key: const ValueKey('tab_estructura'),
          repository: _academicoRepo,
        );
      case 4:
        return AsignacionesTab(
          key: const ValueKey('tab_asignaciones'),
          repository: _academicoRepo,
        );
      case 5:
        return ExcepcionesTab(
          key: const ValueKey('tab_excepciones'),
          repository: _academicoRepo,
        );
      default:
        return const Center(child: Text('Sección no encontrada'));
    }
  }

  Widget _construirErrorGeo(DashboardState state, DashboardBloc bloc) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: SIAAColors.asistenciaAusente),
          const SizedBox(height: 12),
          Text(
            state.errorMessage ?? 'Ocurrió un error al cargar la información.',
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => bloc.add(const DashboardCargarDatosRequested()),
            child: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }
}
