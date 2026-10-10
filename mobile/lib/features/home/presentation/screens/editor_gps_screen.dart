// editor_gps_screen.dart — Entrada al Editor GPS (US-GEO-01, US-GEO-02): seleccionar
// Sede → Bloque → Aula (o crearlas) y abrir la captura del polígono. Se aloja en el
// shell de navegación, por eso no declara AppBar propia.
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../geo_editor/data/espacio_repository.dart';
import '../../../geo_editor/presentation/widgets/capturas_pendientes_banner.dart';
import '../bloc/home_bloc.dart';
import '../bloc/home_event.dart';
import '../bloc/home_state.dart';
import '../navigation/geo_editor_navigator.dart';
import '../widgets/dialogs/home_dialog_actions.dart';
import '../widgets/panels/jerarquia_selector_panel.dart';

class EditorGpsScreen extends StatelessWidget {
  final HomeBloc? bloc;

  const EditorGpsScreen({super.key, this.bloc});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<HomeBloc>(
      create: (_) => (bloc ?? HomeBloc())..add(const CargarSedesRequested()),
      child: const _EditorGpsView(),
    );
  }
}

class _EditorGpsView extends StatelessWidget {
  const _EditorGpsView();

  void _abrirGeoEditor(BuildContext context, EspacioModel espacio) {
    GeoEditorNavigator.navegar(
      context: context,
      espacio: espacio,
      espacioRepo: EspacioRepository(),
      onRetorno: () =>
          context.read<HomeBloc>().add(const RefrescarEspaciosRequested()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocListener<HomeBloc, HomeState>(
      listenWhen: (prev, curr) =>
          prev.errorMessage != curr.errorMessage ||
          prev.successMessage != curr.successMessage ||
          prev.ultimoEspacioCreado != curr.ultimoEspacioCreado,
      listener: (context, state) {
        if (state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(state.errorMessage!),
            backgroundColor: SIAAColors.asistenciaAusente,
          ));
          context.read<HomeBloc>().add(const LimpiarMensajesHomeRequested());
        } else if (state.successMessage != null) {
          final ultimo = state.ultimoEspacioCreado;
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(state.successMessage!),
            backgroundColor: SIAAColors.asistenciaPresente,
            action: ultimo != null
                ? SnackBarAction(
                    label: 'Trazar GPS',
                    textColor: Colors.white,
                    onPressed: () => _abrirGeoEditor(context, ultimo),
                  )
                : null,
          ));
          context.read<HomeBloc>().add(const LimpiarMensajesHomeRequested());
        }
      },
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(SIAASpacing.lg),
        child: Column(children: [
          const CapturasPendientesBanner(),
          BlocBuilder<HomeBloc, HomeState>(
            builder: (context, s) => JerarquiaSelectorPanel(
              isDark: isDark,
              sedes: s.sedes,
              sedeSeleccionada: s.sedeSeleccionada,
              cargandoSedes: s.cargandoSedes,
              onSedeChanged: (nueva) {
                if (nueva != null) {
                  context.read<HomeBloc>().add(SeleccionarSedeRequested(nueva));
                }
              },
              onNuevaSede: () => HomeDialogActions.crearSede(context),
              bloques: s.bloques,
              bloqueSeleccionado: s.bloqueSeleccionado,
              cargandoBloques: s.cargandoBloques,
              onBloqueChanged: (nuevo) {
                if (nuevo != null) {
                  context
                      .read<HomeBloc>()
                      .add(SeleccionarBloqueRequested(nuevo));
                }
              },
              onNuevoBloque: () =>
                  HomeDialogActions.crearBloque(context, s.sedeSeleccionada),
              espacios: s.espacios,
              cargandoEspacios: s.cargandoEspacios,
              onCrearAula: () => HomeDialogActions.crearAula(
                  context, s.sedeSeleccionada, s.bloqueSeleccionado),
              onEditarEspacio: (esp) => _abrirGeoEditor(context, esp),
            ),
          ),
        ]),
      ),
    );
  }
}
