// marcajes_admin_screen.dart — Pantalla principal de administración y ajuste de marcajes (US-MAR-09, US-MAR-10)
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/models/marcaje_admin_model.dart';
import '../bloc/marcajes_admin_bloc.dart';
import '../bloc/marcajes_admin_event.dart';
import '../bloc/marcajes_admin_state.dart';
import '../widgets/ajuste_marcaje_dialog.dart';
import '../widgets/marcaje_manual_dialog.dart';
import '../widgets/marcajes_data_table.dart';
import '../widgets/marcajes_filter_bar.dart';

class MarcajesAdminScreen extends StatefulWidget {
  const MarcajesAdminScreen({super.key});

  @override
  State<MarcajesAdminScreen> createState() => _MarcajesAdminScreenState();
}

class _MarcajesAdminScreenState extends State<MarcajesAdminScreen> {
  int _paginaActual = 1;
  FiltrosMarcajeAdmin _filtros = const FiltrosMarcajeAdmin();

  @override
  void initState() {
    super.initState();
    context.read<MarcajesAdminBloc>().add(const CargarMarcajesAdminEvent());
  }

  void _onFiltrar(FiltrosMarcajeAdmin nuevosFiltros) {
    setState(() {
      _filtros = nuevosFiltros;
      _paginaActual = 1;
    });
    context.read<MarcajesAdminBloc>().add(
          CargarMarcajesAdminEvent(filtros: _filtros, pagina: 1),
        );
  }

  void _abrirAjuste(MarcajeAdminModel marcaje) {
    AjusteMarcajeDialog.show(
      context,
      marcaje: marcaje,
      onConfirmar: ({
        required String accion,
        String? nuevoResultado,
        required bool anulado,
        required String motivo,
      }) {
        context.read<MarcajesAdminBloc>().add(
              AjustarMarcajeEvent(
                marcajeId: marcaje.id,
                accion: accion,
                nuevoResultado: nuevoResultado,
                anulado: anulado,
                motivo: motivo,
              ),
            );
      },
    );
  }

  void _abrirManual() {
    MarcajeManualDialog.show(
      context,
      onConfirmar: ({
        required String sesionId,
        required String usuarioId,
        required String tipo,
        required String resultado,
        required String motivo,
      }) {
        context.read<MarcajesAdminBloc>().add(
              CrearMarcajeManualEvent(
                sesionId: sesionId,
                usuarioId: usuarioId,
                tipo: tipo,
                resultado: resultado,
                motivo: motivo,
              ),
            );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<MarcajesAdminBloc, MarcajesAdminState>(
      listener: (context, state) {
        if (state is MarcajesAdminActionSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.mensaje),
              backgroundColor: Colors.green,
            ),
          );
        } else if (state is MarcajesAdminFailure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.error),
              backgroundColor: Colors.red.shade800,
            ),
          );
        }
      },
      builder: (context, state) {
        List<MarcajeAdminModel> marcajes = [];
        int total = 0;
        bool isLoading = state is MarcajesAdminLoading;

        if (state is MarcajesAdminLoaded) {
          marcajes = state.page.items;
          total = state.page.total;
        }

        return Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Gestión y Ajustes de Marcaje',
                          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Consulta registros, audita anomalías de GPS y realiza correcciones con trazabilidad obligatoria.',
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh_rounded),
                      tooltip: 'Actualizar lista',
                      onPressed: () {
                        context.read<MarcajesAdminBloc>().add(
                              CargarMarcajesAdminEvent(filtros: _filtros, pagina: _paginaActual),
                            );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                MarcajesFilterBar(
                  onFiltrar: _onFiltrar,
                  onNuevoManual: _abrirManual,
                ),
                const SizedBox(height: 16),
                if (isLoading)
                  const Expanded(child: Center(child: CircularProgressIndicator()))
                else
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          MarcajesDataTable(
                            marcajes: marcajes,
                            onSeleccionar: _abrirAjuste,
                          ),
                          const SizedBox(height: 16),
                          _buildPagination(total),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPagination(int total) {
    final totalPaginas = (total / 20).ceil();
    if (totalPaginas <= 1) return const SizedBox.shrink();

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: _paginaActual > 1
              ? () {
                  setState(() => _paginaActual--);
                  context.read<MarcajesAdminBloc>().add(
                        CargarMarcajesAdminEvent(filtros: _filtros, pagina: _paginaActual),
                      );
                }
              : null,
        ),
        Text('Página $_paginaActual de $totalPaginas ($total registros)'),
        IconButton(
          icon: const Icon(Icons.chevron_right),
          onPressed: _paginaActual < totalPaginas
              ? () {
                  setState(() => _paginaActual++);
                  context.read<MarcajesAdminBloc>().add(
                        CargarMarcajesAdminEvent(filtros: _filtros, pagina: _paginaActual),
                      );
                }
              : null,
        ),
      ],
    );
  }
}
