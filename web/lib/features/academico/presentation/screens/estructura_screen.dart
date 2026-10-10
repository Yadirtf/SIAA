import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../bloc/academico_bloc.dart';
import '../bloc/academico_event.dart';
import '../bloc/academico_state.dart';
import '../dialogs/asignatura_dialog.dart';
import '../dialogs/estudiantes_grupo_dialog.dart';
import '../dialogs/facultad_dialog.dart';
import '../dialogs/grupo_dialog.dart';
import '../dialogs/programa_dialog.dart';
import '../edicion/editores_academicos.dart';
import '../widgets/item_registro_tile.dart';
import '../../data/models/academico_models.dart';

class EstructuraScreen extends StatefulWidget {
  const EstructuraScreen({super.key});

  @override
  State<EstructuraScreen> createState() => _EstructuraScreenState();
}

class _EstructuraScreenState extends State<EstructuraScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _onRegistrarNuevo(BuildContext context, AcademicoLoaded state) {
    switch (_tabController.index) {
      case 0:
        showDialog(context: context, builder: (_) => const FacultadDialog());
        break;
      case 1:
        showDialog(
          context: context,
          builder: (_) => ProgramaDialog(facultades: state.facultades),
        );
        break;
      case 2:
        showDialog(
          context: context,
          builder: (_) => AsignaturaDialog(programas: state.programas),
        );
        break;
      case 3:
        showDialog(
          context: context,
          builder: (_) => GrupoDialog(
            asignaturas: state.asignaturas,
            periodos: state.periodos,
          ),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(28),
      child: BlocBuilder<AcademicoBloc, AcademicoState>(
        buildWhen: (prev, curr) =>
            curr is AcademicoLoaded ||
            curr is AcademicoLoading ||
            curr is AcademicoError,
        builder: (context, state) {
          if (state is AcademicoLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is AcademicoError) {
            return Center(
              child: Text(state.message, style: AppTextStyles.bodyMedium),
            );
          }
          if (state is AcademicoLoaded) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Estructura Curricular',
                            style: AppTextStyles.h2,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Jerarquía académica: Facultades → Programas → Asignaturas → Grupos (US-ACA-01)',
                            style: AppTextStyles.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => _onRegistrarNuevo(context, state),
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: const Text('Registrar Nuevo'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TabBar(
                  controller: _tabController,
                  labelColor: AppColors.primaryAccent,
                  unselectedLabelColor: AppColors.textMuted,
                  indicatorColor: AppColors.primaryAccent,
                  tabs: [
                    Tab(text: 'Facultades (${state.facultades.length})'),
                    Tab(text: 'Programas (${state.programas.length})'),
                    Tab(text: 'Asignaturas (${state.asignaturas.length})'),
                    Tab(text: 'Grupos (${state.grupos.length})'),
                  ],
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildFacultadesList(state),
                      _buildProgramasList(state),
                      _buildAsignaturasList(state),
                      _buildGruposList(state),
                    ],
                  ),
                ),
              ],
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _lista<T>(
    List<T> items,
    String vacio,
    Widget Function(BuildContext, T) item,
  ) {
    if (items.isEmpty) return Center(child: Text(vacio));
    return ListView.separated(
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, i) => item(context, items[i]),
    );
  }

  Widget _buildFacultadesList(AcademicoLoaded state) => _lista(
    state.facultades,
    'No hay facultades registradas.',
    (context, f) => ItemRegistroTile(
      icono: Icons.account_balance_outlined,
      color: AppColors.primaryAccent,
      titulo: '${f.nombre} (${f.codigo})',
      nombreTipo: 'facultad',
      onEditar: () => editarFacultad(context, f),
      onEliminar: () =>
          context.read<AcademicoBloc>().add(DeleteFacultadEvent(f.id)),
    ),
  );

  Widget _buildProgramasList(AcademicoLoaded state) => _lista(
    state.programas,
    'No hay programas registrados.',
    (context, p) => ItemRegistroTile(
      icono: Icons.school_outlined,
      color: AppColors.accentCyan,
      titulo: '${p.nombre} (${p.codigo})',
      nombreTipo: 'programa',
      onEditar: () => editarPrograma(context, p),
      onEliminar: () =>
          context.read<AcademicoBloc>().add(DeleteProgramaEvent(p.id)),
    ),
  );

  Widget _buildAsignaturasList(AcademicoLoaded state) => _lista(
    state.asignaturas,
    'No hay asignaturas registradas.',
    (context, a) => ItemRegistroTile(
      icono: Icons.menu_book_rounded,
      color: AppColors.accentEmerald,
      titulo: '${a.nombre} (${a.codigo})',
      subtitulo: 'Créditos: ${a.creditos}',
      nombreTipo: 'asignatura',
      onEditar: () => editarAsignatura(context, a),
      onEliminar: () =>
          context.read<AcademicoBloc>().add(DeleteAsignaturaEvent(a.id)),
    ),
  );

  Widget _buildGruposList(AcademicoLoaded state) => _lista(
    state.grupos,
    'No hay grupos creados.',
    (context, g) => ItemRegistroTile(
      icono: Icons.groups_rounded,
      color: AppColors.accentAmber,
      titulo: 'Grupo ${g.numero}',
      subtitulo: _detalleGrupo(state, g),
      nombreTipo: 'grupo',
      accionesExtra: [
        IconButton(
          icon: const Icon(Icons.people_alt_outlined),
          tooltip: 'Estudiantes del grupo',
          onPressed: () => EstudiantesGrupoDialog.mostrar(
            context,
            grupoId: g.id,
            titulo: _tituloGrupo(state, g),
            cupo: g.cupo,
          ),
        ),
      ],
      onEditar: () => editarGrupo(context, g),
      onEliminar: () =>
          context.read<AcademicoBloc>().add(DeleteGrupoEvent(g.id)),
    ),
  );

  String _tituloGrupo(AcademicoLoaded state, GrupoModel g) {
    final asig = state.asignaturas.where((a) => a.id == g.asignaturaId);
    return asig.isEmpty
        ? 'Grupo ${g.numero}'
        : '${asig.first.nombre} – Grupo ${g.numero}';
  }

  String _detalleGrupo(AcademicoLoaded state, GrupoModel g) {
    final asig = state.asignaturas.where((a) => a.id == g.asignaturaId);
    final per = state.periodos.where((p) => p.id == g.periodoId);
    return [
      if (asig.isNotEmpty) asig.first.nombre,
      if (per.isNotEmpty) 'Periodo ${per.first.codigo}',
      'Cupo: ${g.cupo} estudiantes',
    ].join(' · ');
  }
}
