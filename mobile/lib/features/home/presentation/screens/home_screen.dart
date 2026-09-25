import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../geo_editor/data/espacio_repository.dart';
import '../bloc/home_bloc.dart';
import '../bloc/home_event.dart';
import '../bloc/home_state.dart';
import '../navigation/geo_editor_navigator.dart';
import '../widgets/cards/user_profile_card.dart';
import '../widgets/dialogs/confirmar_logout_dialog.dart';
import '../widgets/dialogs/home_dialog_actions.dart';
import '../widgets/panels/jerarquia_selector_panel.dart';
import '../widgets/panels/modulos_secundarios_panel.dart';

/// Pantalla principal y vista pura de SIAA Móvil.
/// Desacoplada al 100% de llamadas HTTP y lógica de negocio mediante HomeBloc (US-GEO-01).
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static const routeName = '/home';

  @override
  Widget build(BuildContext context) {
    return BlocProvider<HomeBloc>(
      create: (_) => HomeBloc()..add(const CargarSedesRequested()),
      child: const _HomeScreenView(),
    );
  }
}

class _HomeScreenView extends StatelessWidget {
  const _HomeScreenView();

  void _abrirGeoEditor(BuildContext context, EspacioModel espacio) {
    GeoEditorNavigator.navegar(
      context: context,
      espacio: espacio,
      espacioRepo: EspacioRepository(),
      onRetorno: () {
        context.read<HomeBloc>().add(const RefrescarEspaciosRequested());
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return MultiBlocListener(
      listeners: [
        BlocListener<AuthBloc, AuthState>(
          listener: (context, state) {
            if (state is AuthUnauthenticated) {
              Navigator.of(context).pushReplacementNamed('/login');
            }
          },
        ),
        BlocListener<HomeBloc, HomeState>(
          listenWhen: (prev, curr) =>
              prev.errorMessage != curr.errorMessage ||
              prev.successMessage != curr.successMessage ||
              prev.ultimoEspacioCreado != curr.ultimoEspacioCreado,
          listener: (context, state) {
            if (state.errorMessage != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.errorMessage!),
                  backgroundColor: SIAAColors.asistenciaAusente,
                ),
              );
              context
                  .read<HomeBloc>()
                  .add(const LimpiarMensajesHomeRequested());
            } else if (state.successMessage != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.successMessage!),
                  backgroundColor: SIAAColors.asistenciaPresente,
                ),
              );
              if (state.ultimoEspacioCreado != null) {
                _abrirGeoEditor(context, state.ultimoEspacioCreado!);
              }
              context
                  .read<HomeBloc>()
                  .add(const LimpiarMensajesHomeRequested());
            }
          },
        ),
      ],
      child: Scaffold(
        appBar: AppBar(
          title: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: SIAAColors.primary500,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.school, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 10),
              const Text('SIAA Móvil',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout_rounded),
              tooltip: 'Cerrar sesión',
              onPressed: () => ConfirmarLogoutDialog.mostrar(context),
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(SIAASpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Tarjeta de Usuario / Perfil
              BlocBuilder<AuthBloc, AuthState>(
                builder: (context, authState) {
                  String nombre = 'Usuario Institucional';
                  List<String> roles = ['Docente'];
                  if (authState is AuthAuthenticated) {
                    nombre = authState.nombre;
                    roles = authState.roles.isNotEmpty
                        ? authState.roles
                        : ['Docente'];
                  }
                  return UserProfileCard(
                      nombre: nombre, roles: roles, isDark: isDark);
                },
              ),
              const SizedBox(height: SIAASpacing.lg),

              // 2. Panel Jerarquía Física y Cartografía
              BlocBuilder<HomeBloc, HomeState>(
                builder: (context, homeState) {
                  return JerarquiaSelectorPanel(
                    isDark: isDark,
                    sedes: homeState.sedes,
                    sedeSeleccionada: homeState.sedeSeleccionada,
                    cargandoSedes: homeState.cargandoSedes,
                    onSedeChanged: (nueva) {
                      if (nueva != null) {
                        context
                            .read<HomeBloc>()
                            .add(SeleccionarSedeRequested(nueva));
                      }
                    },
                    onNuevaSede: () => HomeDialogActions.crearSede(context),
                    bloques: homeState.bloques,
                    bloqueSeleccionado: homeState.bloqueSeleccionado,
                    cargandoBloques: homeState.cargandoBloques,
                    onBloqueChanged: (nuevo) {
                      if (nuevo != null) {
                        context
                            .read<HomeBloc>()
                            .add(SeleccionarBloqueRequested(nuevo));
                      }
                    },
                    onNuevoBloque: () => HomeDialogActions.crearBloque(
                      context,
                      homeState.sedeSeleccionada,
                    ),
                    espacios: homeState.espacios,
                    cargandoEspacios: homeState.cargandoEspacios,
                    onCrearAula: () => HomeDialogActions.crearAula(
                      context,
                      homeState.sedeSeleccionada,
                      homeState.bloqueSeleccionado,
                    ),
                    onEditarEspacio: (esp) => _abrirGeoEditor(context, esp),
                  );
                },
              ),
              const SizedBox(height: SIAASpacing.lg),

              // 3. Módulos Secundarios (Asistencia / Historial)
              ModulosSecundariosPanel(isDark: isDark),
            ],
          ),
        ),
      ),
    );
  }
}
