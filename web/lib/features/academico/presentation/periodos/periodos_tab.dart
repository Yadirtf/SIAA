import 'package:flutter/material.dart';
import '../../data/academico_models.dart';
import '../../data/academico_repository.dart';
import '../widgets/dialogs/crear_periodo_dialog.dart';

class PeriodosTab extends StatefulWidget {
  final AcademicoRepository repository;

  const PeriodosTab({super.key, required this.repository});

  @override
  State<PeriodosTab> createState() => _PeriodosTabState();
}

class _PeriodosTabState extends State<PeriodosTab> {
  bool _loading = true;
  String? _error;
  List<PeriodoModel> _periodos = [];

  @override
  void initState() {
    super.initState();
    _cargarPeriodos();
  }

  Future<void> _cargarPeriodos() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await widget.repository.listarPeriodos();
      if (mounted) {
        setState(() {
          _periodos = list;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceFirst('Exception: ', '');
          _loading = false;
        });
      }
    }
  }

  Future<void> _mostrarDialogoNuevoPeriodo([PeriodoModel? existente]) async {
    await CrearPeriodoDialog.mostrar(
      context,
      existente: existente,
      onGuardar: ({
        required String codigo,
        required String nombre,
        required String fechaInicio,
        required String fechaFin,
        required String estado,
      }) async {
        try {
          PeriodoModel resultado;
          if (existente == null) {
            resultado = await widget.repository.crearPeriodo(
              codigo: codigo,
              nombre: nombre,
              fechaInicio: fechaInicio,
              fechaFin: fechaFin,
              estado: estado,
            );
          } else {
            resultado = await widget.repository.actualizarPeriodo(
              id: existente.id,
              codigo: codigo,
              nombre: nombre,
              fechaInicio: fechaInicio,
              fechaFin: fechaFin,
              estado: estado,
            );
          }

          if (mounted && resultado.advertencias.isNotEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(resultado.advertencias.join('\n')),
                backgroundColor: Colors.amber.shade900,
                duration: const Duration(seconds: 5),
              ),
            );
          }

          _cargarPeriodos();
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(e.toString()),
                backgroundColor: Colors.red.shade700,
              ),
            );
          }
        }
      },
    );
  }


  Color _colorPorEstado(String estado) {
    switch (estado) {
      case 'ACTIVO':
        return const Color(0xFF10B981);
      case 'PLANEACION':
        return Colors.amber.shade700;
      case 'CERRADO':
        return Colors.blueGrey;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Error: $_error', style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _cargarPeriodos,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Periodos Académicos (US-ACA-01)',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Marco organizativo institucional contra el cual se expanden horarios y asignaciones.',
                    style: TextStyle(color: Colors.black54),
                  ),
                ],
              ),
              FilledButton.icon(
                onPressed: () => _mostrarDialogoNuevoPeriodo(),
                icon: const Icon(Icons.add),
                label: const Text('Nuevo Periodo'),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.grey.shade200),
              ),
              child: _periodos.isEmpty
                  ? const Center(
                      child: Text('No hay periodos académicos registrados.'),
                    )
                  : ListView.separated(
                      itemCount: _periodos.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (ctx, index) {
                        final p = _periodos[index];
                        final estadoColor = _colorPorEstado(p.estado);
                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 8),
                          leading: CircleAvatar(
                            backgroundColor: estadoColor.withValues(alpha: 0.15),
                            child: Icon(Icons.calendar_month, color: estadoColor),
                          ),
                          title: Text(
                            '${p.codigo} — ${p.nombre}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            'Vigencia: ${p.fechaInicio} al ${p.fechaFin}',
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Chip(
                                label: Text(
                                  p.estado,
                                  style: TextStyle(
                                    color: estadoColor,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                backgroundColor: estadoColor.withValues(alpha: 0.1),
                                side: BorderSide.none,
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(Icons.edit_outlined),
                                tooltip: p.estado == 'CERRADO'
                                    ? 'Periodo cerrado (Inmutable)'
                                    : 'Editar',
                                onPressed: p.estado == 'CERRADO'
                                    ? null
                                    : () => _mostrarDialogoNuevoPeriodo(p),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
