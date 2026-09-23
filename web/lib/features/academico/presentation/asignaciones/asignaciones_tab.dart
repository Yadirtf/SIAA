import 'package:flutter/material.dart';
import '../../data/academico_models.dart';
import '../../data/academico_repository.dart';
import '../widgets/dialogs/crear_asignacion_dialog.dart';
import '../widgets/views/asignaciones_list_view.dart';

class AsignacionesTab extends StatefulWidget {
  final AcademicoRepository repository;

  const AsignacionesTab({super.key, required this.repository});

  @override
  State<AsignacionesTab> createState() => _AsignacionesTabState();
}

class _AsignacionesTabState extends State<AsignacionesTab> {
  bool _loading = true;
  String? _error;

  List<PeriodoModel> _periodos = [];
  PeriodoModel? _periodoSeleccionado;
  List<AsignacionModel> _asignaciones = [];

  @override
  void initState() {
    super.initState();
    _cargarPeriodos();
  }

  Future<void> _cargarPeriodos() async {
    setState(() => _loading = true);
    try {
      final periodos = await widget.repository.listarPeriodos();
      if (periodos.isNotEmpty) {
        _periodoSeleccionado = periodos.firstWhere(
          (p) => p.estado == 'ACTIVO',
          orElse: () => periodos.first,
        );
      }
      if (mounted) {
        setState(() {
          _periodos = periodos;
        });
        if (_periodoSeleccionado != null) {
          _cargarAsignaciones(_periodoSeleccionado!.id);
        } else {
          setState(() => _loading = false);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  Future<void> _cargarAsignaciones(String periodoId) async {
    setState(() => _loading = true);
    try {
      final list = await widget.repository.listarAsignaciones(periodoId);
      if (mounted) {
        setState(() {
          _asignaciones = list;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  Future<void> _dialogoNuevaAsignacion() async {
    if (_periodoSeleccionado == null) return;

    await CrearAsignacionDialog.mostrar(
      context,
      onGuardar: ({
        required String docenteId,
        required String docenteNombre,
        required String grupoId,
        required String asignaturaId,
        required String facultadId,
        required String? espacioId,
        required String espacioNombre,
        required int diaSemana,
        required String horaInicio,
        required String horaFin,
        required String modalidad,
      }) async {
        try {
          final asig = await widget.repository.crearAsignacion(
            periodoId: _periodoSeleccionado!.id,
            docenteIds: [docenteId],
            docenteNombre: docenteNombre,
            grupoId: grupoId,
            asignaturaId: asignaturaId,
            facultadId: facultadId,
            espacioId: espacioId,
            espacioNombre: espacioNombre,
            franja: FranjaModel(
              diaSemana: diaSemana,
              horaInicio: horaInicio,
              horaFin: horaFin,
            ),
            modalidad: modalidad,
          );

          if (mounted && asig.advertencias.isNotEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(asig.advertencias.join('\n')),
                backgroundColor: Colors.amber.shade900,
                duration: const Duration(seconds: 6),
              ),
            );
          }

          _cargarAsignaciones(_periodoSeleccionado!.id);
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(e.toString()),
                backgroundColor: Colors.red.shade700,
                duration: const Duration(seconds: 5),
              ),
            );
          }
        }
      },
    );
  }


  @override
  Widget build(BuildContext context) {
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
                    'Asignaciones Docente–Grupo–Aula (US-ACA-03)',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Fuente de autoridad del sistema con validación pura de colisiones docentes y de aula.',
                    style: TextStyle(color: Colors.black54),
                  ),
                ],
              ),
              Row(
                children: [
                  if (_periodos.isNotEmpty)
                    DropdownButton<PeriodoModel>(
                      value: _periodoSeleccionado,
                      items: _periodos
                          .map((p) => DropdownMenuItem(
                                value: p,
                                child: Text('${p.codigo} (${p.estado})'),
                              ))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _periodoSeleccionado = val);
                          _cargarAsignaciones(val.id);
                        }
                      },
                    ),
                  const SizedBox(width: 16),
                  FilledButton.icon(
                    onPressed: _periodoSeleccionado == null ||
                            _periodoSeleccionado!.estado == 'CERRADO'
                        ? null
                        : _dialogoNuevaAsignacion,
                    icon: const Icon(Icons.add),
                    label: const Text('Nueva Asignación'),
                  ),
                ],
              ),
            ],
          ),
          if (_error != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFFECACA)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: Color(0xFFDC2626)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _error!,
                      style: const TextStyle(color: Color(0xFFDC2626)),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 16, color: Color(0xFFDC2626)),
                    onPressed: () => setState(() => _error = null),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 20),
          Expanded(
            child: Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.grey.shade200),
              ),
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : AsignacionesListView(asignaciones: _asignaciones),
            ),
          ),
        ],
      ),
    );
  }
}
