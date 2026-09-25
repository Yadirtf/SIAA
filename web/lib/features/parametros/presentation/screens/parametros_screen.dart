import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../bloc/parametros_bloc.dart';
import '../bloc/parametros_event.dart';
import '../bloc/parametros_state.dart';
import '../widgets/ambito_selector.dart';
import '../widgets/parametro_card.dart';

/// Pantalla administrativa de parametrización jerárquica.
/// US-PAR-01: permite editar parámetros por nivel.
/// US-PAR-02: muestra la cascada resuelta para cualquier ámbito.
/// US-PAR-03: cada clave indica su nivel de origen.
class ParametrosScreen extends StatefulWidget {
  const ParametrosScreen({super.key});

  @override
  State<ParametrosScreen> createState() => _ParametrosScreenState();
}

class _ParametrosScreenState extends State<ParametrosScreen> {
  AmbitoSeleccion _seleccion = const AmbitoSeleccion(
    nivel: 'GLOBAL',
    nivelId: '',
  );

  @override
  void initState() {
    super.initState();
    _resolver(_seleccion);
  }

  void _resolver(AmbitoSeleccion sel) {
    setState(() => _seleccion = sel);
    context.read<ParametrosBloc>().add(
      CargarParametrosEfectivosEvent(
        sedeId: sel.sedeId,
        facultadId: sel.facultadId,
        bloqueId: sel.bloqueId,
        espacioId: sel.espacioId,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ─── Cabecera ─────────────────────────────────────────
        _Header(seleccion: _seleccion),

        // ─── Selector de ámbito ───────────────────────────────
        AmbitoSelector(
          seleccionActual: _seleccion,
          onChanged: _resolver,
        ),

        // ─── Mensajes de acción ───────────────────────────────
        BlocBuilder<ParametrosBloc, ParametrosState>(
          buildWhen: (p, c) =>
              (p is ParametrosLoaded && c is ParametrosLoaded) &&
              (p.successMessage != c.successMessage ||
                  p.errorMessage != c.errorMessage),
          builder: (context, state) {
            if (state is! ParametrosLoaded) return const SizedBox.shrink();
            if (state.successMessage != null) {
              return _ActionBanner(
                message: state.successMessage!,
                isError: false,
                onDismiss: () => context
                    .read<ParametrosBloc>()
                    .add(const LimpiarMensajeParametroEvent()),
              );
            }
            if (state.errorMessage != null) {
              return _ActionBanner(
                message: state.errorMessage!,
                isError: true,
                onDismiss: () => context
                    .read<ParametrosBloc>()
                    .add(const LimpiarMensajeParametroEvent()),
              );
            }
            return const SizedBox.shrink();
          },
        ),

        // ─── Contenido ────────────────────────────────────────
        Expanded(
          child: BlocBuilder<ParametrosBloc, ParametrosState>(
            builder: (context, state) {
              if (state is ParametrosLoading) {
                return const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.primaryAccent,
                  ),
                );
              }
              if (state is ParametrosFailure) {
                return _ErrorView(
                  error: state.error,
                  onRetry: () => _resolver(_seleccion),
                );
              }
              if (state is ParametrosLoaded) {
                return _ParametrosListView(
                  state: state,
                  seleccion: _seleccion,
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ),
      ],
    );
  }
}

// ─── Cabecera ────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final AmbitoSeleccion seleccion;

  const _Header({required this.seleccion});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(28, 24, 28, 20),
      color: AppColors.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primaryAccent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.tune_rounded,
                  color: AppColors.primaryAccent,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Parametrización Jerárquica',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    'EP-05 · US-PAR-01 / US-PAR-02 / US-PAR-03',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          _LeyendaCascada(),
        ],
      ),
    );
  }
}

class _LeyendaCascada extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final niveles = [
      'Global',
      'Sede',
      'Facultad',
      'Bloque',
      'Aula',
      'Asignación',
    ];
    return Row(
      children: [
        const Text(
          'Cascada: ',
          style: TextStyle(fontSize: 12, color: AppColors.textMuted),
        ),
        ...niveles.asMap().entries.map((e) {
          final isLast = e.key == niveles.length - 1;
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: e.key == 0
                      ? AppColors.surfaceMuted
                      : AppColors.primaryAccent.withOpacity(0.08 + e.key * 0.04),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  e.value,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: e.key == 0 ? AppColors.textMuted : AppColors.primaryAccent,
                  ),
                ),
              ),
              if (!isLast)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4),
                  child: Icon(
                    Icons.arrow_forward_rounded,
                    size: 12,
                    color: AppColors.textMuted,
                  ),
                ),
            ],
          );
        }),
      ],
    );
  }
}

// ─── Lista de parámetros ─────────────────────────────────────────

class _ParametrosListView extends StatelessWidget {
  final ParametrosLoaded state;
  final AmbitoSeleccion seleccion;

  const _ParametrosListView({
    required this.state,
    required this.seleccion,
  });

  @override
  Widget build(BuildContext context) {
    final params = state.snapshot.parametros;

    // Agrupar en dos categorías: Tiempo/GPS y Comportamiento
    final tiempoGps = params
        .where((p) => _esTiempoOGps(p.clave))
        .toList();
    final comportamiento = params
        .where((p) => !_esTiempoOGps(p.clave))
        .toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      children: [
        if (tiempoGps.isNotEmpty) ...[
          _SectionHeader(
            title: 'Umbrales de tiempo y GPS',
            count: tiempoGps.length,
          ),
          const SizedBox(height: 8),
          ...tiempoGps.map(
            (p) => ParametroCard(
              parametro: p,
              ambitoDestino: seleccion.nivel,
              ambitoDestinoId: seleccion.nivelId,
              isSaving: state.isSaving,
            ),
          ),
          const SizedBox(height: 20),
        ],
        if (comportamiento.isNotEmpty) ...[
          _SectionHeader(
            title: 'Comportamiento del sistema',
            count: comportamiento.length,
          ),
          const SizedBox(height: 8),
          ...comportamiento.map(
            (p) => ParametroCard(
              parametro: p,
              ambitoDestino: seleccion.nivel,
              ambitoDestinoId: seleccion.nivelId,
              isSaving: state.isSaving,
            ),
          ),
        ],
      ],
    );
  }

  bool _esTiempoOGps(String clave) {
    return clave.contains('holgura') ||
        clave.contains('tardanza') ||
        clave.contains('gps') ||
        clave.contains('buffer') ||
        clave.contains('vertice') ||
        clave.contains('lecturas');
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final int count;

  const _SectionHeader({required this.title, required this.count});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.surfaceMuted,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '$count',
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textMuted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Banner de acción ────────────────────────────────────────────

class _ActionBanner extends StatelessWidget {
  final String message;
  final bool isError;
  final VoidCallback onDismiss;

  const _ActionBanner({
    required this.message,
    required this.isError,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      color: isError
          ? AppColors.accentRose.withOpacity(0.08)
          : AppColors.accentEmerald.withOpacity(0.08),
      child: Row(
        children: [
          Icon(
            isError ? Icons.error_outline_rounded : Icons.check_circle_outline_rounded,
            size: 16,
            color: isError ? AppColors.accentRose : AppColors.accentEmerald,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 13,
                color: isError ? AppColors.accentRose : AppColors.accentEmerald,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded, size: 16),
            color: AppColors.textMuted,
            onPressed: onDismiss,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
          ),
        ],
      ),
    );
  }
}

// ─── Vista de error ──────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;

  const _ErrorView({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.tune_rounded,
            size: 52,
            color: AppColors.border,
          ),
          const SizedBox(height: 16),
          const Text(
            'No se pudieron cargar los parámetros',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded, size: 16),
            label: const Text('Reintentar'),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primaryAccent,
            ),
          ),
        ],
      ),
    );
  }
}
