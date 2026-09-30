import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../domain/models/dispositivo_model.dart';
import '../bloc/dispositivos_bloc.dart';
import '../bloc/dispositivos_event.dart';
import '../bloc/dispositivos_state.dart';
import '../widgets/dispositivo_busqueda_bar.dart';
import '../widgets/dispositivo_card.dart';
import '../widgets/dispositivo_metricas_header.dart';

class DispositivosScreen extends StatefulWidget {
  const DispositivosScreen({super.key});

  @override
  State<DispositivosScreen> createState() => _DispositivosScreenState();
}

class _DispositivosScreenState extends State<DispositivosScreen> {
  String _usuarioIdActual = '';
  DispositivoFiltro _filtro = DispositivoFiltro.todos;

  @override
  void initState() {
    super.initState();
    final authState = context.read<AuthBloc>().state;
    if (authState is Authenticated) {
      _usuarioIdActual = authState.user.id;
      context.read<DispositivosBloc>().add(
        CargarDispositivosEvent(_usuarioIdActual),
      );
    }
  }

  void _consultarUsuario(String usuarioId) {
    setState(() => _usuarioIdActual = usuarioId);
    context.read<DispositivosBloc>().add(CargarDispositivosEvent(usuarioId));
  }

  void _usarMiUsuario() {
    final authState = context.read<AuthBloc>().state;
    if (authState is Authenticated) {
      _consultarUsuario(authState.user.id);
    }
  }

  List<DispositivoModel> _filtrar(List<DispositivoModel> lista) {
    switch (_filtro) {
      case DispositivoFiltro.todos:
        return lista;
      case DispositivoFiltro.pendientes:
        return lista.where((d) => d.esPendiente).toList();
      case DispositivoFiltro.aprobados:
        return lista.where((d) => d.esAprobado).toList();
      case DispositivoFiltro.revocados:
        return lista.where((d) => d.esRevocado).toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<DispositivosBloc, DispositivosState>(
      listener: (context, state) {
        if (state is DispositivosLoaded && state.actionSuccessMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.actionSuccessMessage!),
              backgroundColor: AppColors.statusSuccessText,
              duration: const Duration(seconds: 3),
            ),
          );
        }
        if (state is DispositivosLoaded && state.actionErrorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.actionErrorMessage!),
              backgroundColor: AppColors.statusDangerText,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      },
      builder: (context, state) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 20),
              if (state is DispositivosLoaded) ...[
                DispositivoMetricasHeader(
                  total: state.total,
                  aprobados: state.aprobados,
                  pendientes: state.pendientes,
                  revocados: state.revocados,
                ),
                const SizedBox(height: 20),
              ],
              DispositivoBusquedaBar(
                usuarioIdInicial: _usuarioIdActual,
                onBuscarUsuario: _consultarUsuario,
                onRecargar: () => _consultarUsuario(_usuarioIdActual),
                onCambiarFiltro: (f) => setState(() => _filtro = f),
                filtroActual: _filtro,
                onUsarMiUsuario: _usarMiUsuario,
              ),
              const SizedBox(height: 20),
              _buildContent(state),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.primaryAccent.withOpacity(0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(
            Icons.phonelink_lock_rounded,
            color: AppColors.primaryAccent,
            size: 26,
          ),
        ),
        const SizedBox(width: 14),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Dispositivos Confiables', style: AppTextStyles.h1),
            Text(
              'Gestión de hardware móvil autorizado para registro de asistencia (US-AUT-03)',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildContent(DispositivosState state) {
    if (state is DispositivosLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(48),
          child: CircularProgressIndicator(color: AppColors.primaryAccent),
        ),
      );
    }

    if (state is DispositivosFailure) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                color: AppColors.accentRose,
                size: 48,
              ),
              const SizedBox(height: 12),
              Text('Error al consultar dispositivos', style: AppTextStyles.h3),
              const SizedBox(height: 6),
              Text(
                state.error,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => _consultarUsuario(_usuarioIdActual),
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    if (state is DispositivosLoaded) {
      final filtrados = _filtrar(state.dispositivos);

      if (filtrados.isEmpty) {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(48),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: [
              const Icon(
                Icons.phonelink_erase_rounded,
                color: AppColors.textMuted,
                size: 54,
              ),
              const SizedBox(height: 14),
              Text(
                _filtro == DispositivoFiltro.todos
                    ? 'No hay dispositivos vinculados a este usuario'
                    : 'No hay dispositivos con el filtro seleccionado',
                style: AppTextStyles.h3.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Cuando el usuario inicie sesión desde la app móvil SIAA, aparecerá en esta lista.',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        );
      }

      return Column(
        children: filtrados.map((disp) {
          return DispositivoCard(
            dispositivo: disp,
            onAprobar: () {
              context.read<DispositivosBloc>().add(
                AprobarDispositivoEvent(
                  dispositivoId: disp.id,
                  usuarioId: _usuarioIdActual,
                ),
              );
            },
            onRevocar: (motivo) {
              context.read<DispositivosBloc>().add(
                RevocarDispositivoEvent(
                  dispositivoId: disp.id,
                  usuarioId: _usuarioIdActual,
                  motivo: motivo,
                ),
              );
            },
          );
        }).toList(),
      );
    }

    return const SizedBox.shrink();
  }
}
