import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../bloc/academico_bloc.dart';
import '../bloc/academico_event.dart';
import '../bloc/academico_state.dart';

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

  void _showCreateFacultad(BuildContext context) {
    final codigoCtrl = TextEditingController();
    final nombreCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Nueva Facultad', style: AppTextStyles.h3),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: codigoCtrl,
              decoration: const InputDecoration(
                labelText: 'Código (ej: FAC-ING)',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: nombreCtrl,
              decoration: const InputDecoration(
                labelText: 'Nombre de la Facultad',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              if (codigoCtrl.text.isNotEmpty && nombreCtrl.text.isNotEmpty) {
                context.read<AcademicoBloc>().add(
                  CreateFacultadEvent(
                    codigo: codigoCtrl.text.trim(),
                    nombre: nombreCtrl.text.trim(),
                  ),
                );
                Navigator.pop(ctx);
              }
            },
            child: const Text('Crear'),
          ),
        ],
      ),
    );
  }

  void _showCreatePrograma(BuildContext context, AcademicoLoaded state) {
    if (state.facultades.isEmpty) return;
    final codigoCtrl = TextEditingController();
    final nombreCtrl = TextEditingController();
    String selectedFacId = state.facultades.first.id;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (c, setMState) => AlertDialog(
          title: Text('Nuevo Programa Académico', style: AppTextStyles.h3),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: codigoCtrl,
                decoration: const InputDecoration(
                  labelText: 'Código (ej: PROG-SIS)',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: nombreCtrl,
                decoration: const InputDecoration(
                  labelText: 'Nombre del Programa',
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: selectedFacId,
                decoration: const InputDecoration(labelText: 'Facultad'),
                items: state.facultades
                    .map(
                      (f) =>
                          DropdownMenuItem(value: f.id, child: Text(f.nombre)),
                    )
                    .toList(),
                onChanged: (val) {
                  if (val != null) setMState(() => selectedFacId = val);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                if (codigoCtrl.text.isNotEmpty && nombreCtrl.text.isNotEmpty) {
                  context.read<AcademicoBloc>().add(
                    CreateProgramaEvent(
                      codigo: codigoCtrl.text.trim(),
                      nombre: nombreCtrl.text.trim(),
                      facultadId: selectedFacId,
                    ),
                  );
                  Navigator.pop(ctx);
                }
              },
              child: const Text('Crear'),
            ),
          ],
        ),
      ),
    );
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
                            'Jerarquía académica institucional: Facultades, Programas y Cursos',
                            style: AppTextStyles.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () {
                        if (_tabController.index == 0) {
                          _showCreateFacultad(context);
                        } else if (_tabController.index == 1) {
                          _showCreatePrograma(context, state);
                        }
                      },
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

  Widget _buildFacultadesList(AcademicoLoaded state) {
    if (state.facultades.isEmpty)
      return const Center(child: Text('No hay facultades registradas.'));
    return ListView.separated(
      itemCount: state.facultades.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, i) {
        final f = state.facultades[i];
        return Card(
          child: ListTile(
            leading: const Icon(
              Icons.account_balance_outlined,
              color: AppColors.primaryAccent,
            ),
            title: Text('${f.nombre} (${f.codigo})', style: AppTextStyles.h3),
            trailing: IconButton(
              icon: const Icon(
                Icons.delete_outline,
                color: AppColors.accentRose,
              ),
              onPressed: () =>
                  context.read<AcademicoBloc>().add(DeleteFacultadEvent(f.id)),
            ),
          ),
        );
      },
    );
  }

  Widget _buildProgramasList(AcademicoLoaded state) {
    if (state.programas.isEmpty)
      return const Center(child: Text('No hay programas registrados.'));
    return ListView.separated(
      itemCount: state.programas.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, i) {
        final p = state.programas[i];
        return Card(
          child: ListTile(
            leading: const Icon(
              Icons.school_outlined,
              color: AppColors.accentCyan,
            ),
            title: Text('${p.nombre} (${p.codigo})', style: AppTextStyles.h3),
            trailing: IconButton(
              icon: const Icon(
                Icons.delete_outline,
                color: AppColors.accentRose,
              ),
              onPressed: () =>
                  context.read<AcademicoBloc>().add(DeleteProgramaEvent(p.id)),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAsignaturasList(AcademicoLoaded state) {
    if (state.asignaturas.isEmpty)
      return const Center(child: Text('No hay asignaturas registradas.'));
    return ListView.separated(
      itemCount: state.asignaturas.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, i) {
        final a = state.asignaturas[i];
        return Card(
          child: ListTile(
            leading: const Icon(
              Icons.menu_book_rounded,
              color: AppColors.accentEmerald,
            ),
            title: Text('${a.nombre} (${a.codigo})', style: AppTextStyles.h3),
            subtitle: Text(
              'Créditos: ${a.creditos}',
              style: AppTextStyles.bodyMedium,
            ),
          ),
        );
      },
    );
  }

  Widget _buildGruposList(AcademicoLoaded state) {
    if (state.grupos.isEmpty)
      return const Center(child: Text('No hay grupos creados.'));
    return ListView.separated(
      itemCount: state.grupos.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, i) {
        final g = state.grupos[i];
        return Card(
          child: ListTile(
            leading: const Icon(
              Icons.groups_rounded,
              color: AppColors.accentAmber,
            ),
            title: Text('Grupo ${g.numero}', style: AppTextStyles.h3),
            subtitle: Text(
              'Cupo: ${g.cupo} estudiantes',
              style: AppTextStyles.bodyMedium,
            ),
          ),
        );
      },
    );
  }
}
