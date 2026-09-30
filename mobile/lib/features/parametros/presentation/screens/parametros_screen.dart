import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/models/parametro_model.dart';
import '../bloc/parametros_bloc.dart';
import '../bloc/parametros_event.dart';
import '../bloc/parametros_state.dart';

/// Pantalla de visualización de parámetros efectivos en mobile.
/// US-PAR-03: muestra cada clave con su valor resuelto y el nivel de origen.
/// Solo lectura — la edición se realiza desde la consola web administrativa.
class ParametrosScreen extends StatefulWidget {
  const ParametrosScreen({super.key});

  @override
  State<ParametrosScreen> createState() => _ParametrosScreenState();
}

class _ParametrosScreenState extends State<ParametrosScreen> {
  @override
  void initState() {
    super.initState();
    context.read<ParametrosBloc>().add(const CargarParametrosGlobalesEvent());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SIAAColors.neutral50,
      appBar: AppBar(
        title: const Text('Parámetros del Sistema'),
        backgroundColor: SIAAColors.primary500,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Recargar parámetros',
            onPressed: () => context
                .read<ParametrosBloc>()
                .add(const CargarParametrosGlobalesEvent()),
          ),
        ],
      ),
      body: BlocBuilder<ParametrosBloc, ParametrosState>(
        builder: (context, state) {
          if (state is ParametrosLoading) {
            return const Center(
              child: CircularProgressIndicator(
                color: SIAAColors.primary500,
              ),
            );
          }
          if (state is ParametrosFailure) {
            return _ErrorView(error: state.error, onRetry: () {
              context
                  .read<ParametrosBloc>()
                  .add(const CargarParametrosGlobalesEvent());
            });
          }
          if (state is ParametrosLoaded) {
            return _ParametrosListView(state: state);
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}

// ─── Lista de parámetros ────────────────────────────────────────

class _ParametrosListView extends StatelessWidget {
  final ParametrosLoaded state;

  const _ParametrosListView({required this.state});

  @override
  Widget build(BuildContext context) {
    final parametros = state.snapshot.parametros;

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(child: _AmbitoHeader(label: state.ambitoLabel)),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (ctx, i) => _ParametroCard(parametro: parametros[i]),
              childCount: parametros.length,
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
      ],
    );
  }
}

class _AmbitoHeader extends StatelessWidget {
  final String label;

  const _AmbitoHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: SIAAColors.primary500,
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Solo lectura — editar desde la consola web',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _ParametroCard extends StatelessWidget {
  final ParametroEfectivo parametro;

  const _ParametroCard({required this.parametro});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: SIAAColors.neutral200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _claveLabel(parametro.clave),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: SIAAColors.primary800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    parametro.clave,
                    style: TextStyle(
                      fontSize: 11,
                      color: SIAAColors.neutral400,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  parametro.valorFormateado,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: SIAAColors.primary500,
                  ),
                ),
                const SizedBox(height: 2),
                _NivelBadge(nivel: parametro.nivelLabel, esGlobal: parametro.esGlobal),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _claveLabel(String clave) {
    const labels = {
      'holgura_entrada_antes_min': 'Holgura entrada (antes)',
      'holgura_entrada_despues_min': 'Holgura entrada (después)',
      'umbral_tardanza_min': 'Umbral tardanza',
      'holgura_salida_antes_min': 'Holgura salida (antes)',
      'holgura_salida_despues_min': 'Holgura salida (después)',
      'precision_gps_max_metros': 'Precisión GPS máxima',
      'buffer_perimetral_metros': 'Buffer perimetral',
      'promedio_lecturas_vertice': 'Lecturas por vértice',
      'salida_obligatoria': 'Marcaje de salida',
      'offline_permitido': 'Marcaje offline',
      'bloqueo_mock_location': 'Bloqueo ubicación simulada',
      'bloqueo_dispositivo_rooteado': 'Bloqueo dispositivo rooteado',
      'verificacion_complementaria': 'Verificación complementaria',
    };
    return labels[clave] ?? clave;
  }
}

class _NivelBadge extends StatelessWidget {
  final String nivel;
  final bool esGlobal;

  const _NivelBadge({required this.nivel, required this.esGlobal});

  @override
  Widget build(BuildContext context) {
    final color = esGlobal ? SIAAColors.neutral300 : SIAAColors.primary200;
    final textColor = esGlobal ? SIAAColors.neutral400 : SIAAColors.primary700;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        nivel,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }
}

// ─── Vista de error ─────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;

  const _ErrorView({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.tune_rounded,
              size: 48,
              color: SIAAColors.neutral300,
            ),
            const SizedBox(height: 16),
            const Text(
              'No se pudieron cargar los parámetros',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: SIAAColors.primary800,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: const TextStyle(fontSize: 12, color: SIAAColors.neutral400),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Reintentar'),
              style: FilledButton.styleFrom(
                backgroundColor: SIAAColors.primary500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
