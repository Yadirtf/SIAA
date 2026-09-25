import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../data/models/sesion_model.dart';
import '../bloc/sesiones_bloc.dart';
import '../dialogs/sesion_ops_dialogs.dart';

class SesionesScreen extends StatefulWidget {
  const SesionesScreen({super.key});

  @override
  State<SesionesScreen> createState() => _SesionesScreenState();
}

class _SesionesScreenState extends State<SesionesScreen> {
  String? _selectedEstado;

  @override
  void initState() {
    super.initState();
    context.read<SesionesBloc>().add(const LoadSesionesEvent());
  }

  void _onFilterChanged(String? estado) {
    setState(() => _selectedEstado = estado);
    context.read<SesionesBloc>().add(
          LoadSesionesEvent(estado: estado),
        );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Sesiones de Clase Materializadas', style: AppTextStyles.h2),
                    const SizedBox(height: 4),
                    Text(
                      'Supervisión y control puntual de clases generadas (US-ACA-05, US-ACA-06, US-ACA-09)',
                      style: AppTextStyles.bodyMedium,
                    ),
                  ],
                ),
              ),
              DropdownButton<String>(
                value: _selectedEstado,
                hint: const Text('Todos los estados'),
                underline: const SizedBox.shrink(),
                items: const [
                  DropdownMenuItem(value: null, child: Text('Todos los estados')),
                  DropdownMenuItem(value: 'PROGRAMADA', child: Text('PROGRAMADA')),
                  DropdownMenuItem(value: 'EN_CURSO', child: Text('EN CURSO')),
                  DropdownMenuItem(value: 'REALIZADA', child: Text('REALIZADA')),
                  DropdownMenuItem(value: 'CANCELADA', child: Text('CANCELADA')),
                ],
                onChanged: _onFilterChanged,
              ),
              const SizedBox(width: 12),
              IconButton(
                icon: const Icon(Icons.refresh_rounded),
                tooltip: 'Refrescar sesiones',
                onPressed: () => context.read<SesionesBloc>().add(
                      LoadSesionesEvent(estado: _selectedEstado),
                    ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: BlocBuilder<SesionesBloc, SesionesState>(
              builder: (context, state) {
                if (state is SesionesLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (state is SesionesError) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline,
                            color: AppColors.accentRose, size: 36),
                        const SizedBox(height: 8),
                        Text(state.message, style: AppTextStyles.bodyMedium),
                      ],
                    ),
                  );
                }
                if (state is SesionesLoaded) {
                  if (state.sesiones.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.event_busy_rounded,
                              size: 48,
                              color: AppColors.textMuted.withOpacity(0.5)),
                          const SizedBox(height: 12),
                          Text('No se encontraron sesiones generadas',
                              style: AppTextStyles.h3),
                          const SizedBox(height: 4),
                          Text(
                            'Active un periodo y use "Generar Sesiones" para materializar el calendario.',
                            style: AppTextStyles.bodyMedium,
                          ),
                        ],
                      ),
                    );
                  }
                  return ListView.separated(
                    itemCount: state.sesiones.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, i) =>
                        _buildSesionCard(context, state.sesiones[i]),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSesionCard(BuildContext context, SesionModel s) {
    Color badgeBg = AppColors.statusInfoBg;
    Color badgeFg = AppColors.statusInfoText;
    if (s.estado == 'REALIZADA') {
      badgeBg = AppColors.statusSuccessBg;
      badgeFg = AppColors.statusSuccessText;
    } else if (s.estado == 'CANCELADA') {
      badgeBg = AppColors.accentRose.withOpacity(0.12);
      badgeFg = AppColors.accentRose;
    }

    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: badgeBg,
          child: Icon(Icons.event_available_rounded, color: badgeFg),
        ),
        title: Text(
          'Fecha: ${s.fecha} • Horario: ${s.horaInicio} - ${s.horaFin}',
          style: AppTextStyles.h3,
        ),
        subtitle: Text(
          'Aula: ${s.espacioId.isNotEmpty ? s.espacioId : "Virtual"} • Grupo: ${s.grupoId} • Docente(s): ${s.docenteIds.join(", ")}'
          '${s.motivoCancelacion.isNotEmpty ? "\nMotivo cancelación: ${s.motivoCancelacion}" : ""}',
          style: AppTextStyles.bodyMedium,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: badgeBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(s.estado,
                  style: TextStyle(
                      color: badgeFg,
                      fontWeight: FontWeight.bold,
                      fontSize: 12)),
            ),
            const SizedBox(width: 8),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert_rounded),
              tooltip: 'Acciones de sesión',
              onSelected: (val) {
                if (val == 'aula') {
                  showDialog(
                    context: context,
                    builder: (_) => ReasignarAulaDialog(
                      sesionId: s.id,
                      aulaActual: s.espacioId,
                    ),
                  );
                } else if (val == 'suplente') {
                  showDialog(
                    context: context,
                    builder: (_) => DocenteReemplazoDialog(
                      sesionId: s.id,
                      docenteActual: s.docenteIds.join(', '),
                    ),
                  );
                } else if (val == 'cancelar') {
                  showDialog(
                    context: context,
                    builder: (_) => CancelarSesionDialog(sesionId: s.id),
                  );
                }
              },
              itemBuilder: (ctx) => [
                const PopupMenuItem(
                  value: 'aula',
                  child: Row(
                    children: [
                      Icon(Icons.meeting_room_outlined, size: 18),
                      SizedBox(width: 8),
                      Text('Reasignar Aula (US-ACA-06)'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'suplente',
                  child: Row(
                    children: [
                      Icon(Icons.person_add_alt_outlined, size: 18),
                      SizedBox(width: 8),
                      Text('Asignar Suplente (US-ACA-09)'),
                    ],
                  ),
                ),
                if (s.estado != 'CANCELADA')
                  const PopupMenuItem(
                    value: 'cancelar',
                    child: Row(
                      children: [
                        Icon(Icons.cancel_outlined,
                            size: 18, color: AppColors.accentRose),
                        SizedBox(width: 8),
                        Text('Cancelar Sesión (US-ACA-06)',
                            style: TextStyle(color: AppColors.accentRose)),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
