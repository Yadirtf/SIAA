import 'package:flutter/material.dart';
import '../../data/academico_models.dart';
import '../../data/academico_repository.dart';

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

    final docIdCtrl = TextEditingController();
    final docNombreCtrl = TextEditingController();
    final grpIdCtrl = TextEditingController();
    final asigIdCtrl = TextEditingController();
    final facIdCtrl = TextEditingController();
    final espIdCtrl = TextEditingController();
    final espNombreCtrl = TextEditingController();
    final hIniCtrl = TextEditingController(text: '08:00');
    final hFinCtrl = TextEditingController(text: '10:00');
    int diaSemana = 1;
    String modalidad = 'PRESENCIAL';

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Nueva Asignación de Horario (US-ACA-03)'),
          content: SizedBox(
            width: 480,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: docNombreCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Nombre del Docente*',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: docIdCtrl,
                    decoration: const InputDecoration(
                      labelText: 'ID / Cédula Docente*',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: grpIdCtrl,
                          decoration: const InputDecoration(
                            labelText: 'ID Grupo*',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: asigIdCtrl,
                          decoration: const InputDecoration(
                            labelText: 'ID Asignatura*',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: facIdCtrl,
                    decoration: const InputDecoration(
                      labelText: 'ID Facultad*',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: modalidad,
                    decoration: const InputDecoration(
                      labelText: 'Modalidad (US-ACA-03 AC-06)',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(
                          value: 'PRESENCIAL', child: Text('Presencial')),
                      DropdownMenuItem(
                          value: 'VIRTUAL',
                          child: Text('Virtual (Exenta de Geocerca)')),
                      DropdownMenuItem(
                          value: 'HIBRIDA', child: Text('Híbrida')),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setDialogState(() => modalidad = val);
                      }
                    },
                  ),
                  if (modalidad != 'VIRTUAL') ...[
                    const SizedBox(height: 12),
                    TextField(
                      controller: espIdCtrl,
                      decoration: const InputDecoration(
                        labelText: 'ID Espacio / Aula*',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: espNombreCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Nombre de Espacio (ej. Aula 301)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  DropdownButtonFormField<int>(
                    initialValue: diaSemana,
                    decoration: const InputDecoration(
                      labelText: 'Día de la Semana (US-ACA-02)',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 1, child: Text('Lunes')),
                      DropdownMenuItem(value: 2, child: Text('Martes')),
                      DropdownMenuItem(value: 3, child: Text('Miércoles')),
                      DropdownMenuItem(value: 4, child: Text('Jueves')),
                      DropdownMenuItem(value: 5, child: Text('Viernes')),
                      DropdownMenuItem(value: 6, child: Text('Sábado')),
                      DropdownMenuItem(value: 7, child: Text('Domingo')),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setDialogState(() => diaSemana = val);
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: hIniCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Hora Inicio (HH:MM)*',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: hFinCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Hora Fin (HH:MM)*',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () async {
                if (docNombreCtrl.text.trim().isEmpty ||
                    docIdCtrl.text.trim().isEmpty ||
                    grpIdCtrl.text.trim().isEmpty) {
                  return;
                }
                Navigator.of(ctx).pop();
                try {
                  final asig = await widget.repository.crearAsignacion(
                    periodoId: _periodoSeleccionado!.id,
                    docenteIds: [docIdCtrl.text.trim()],
                    docenteNombre: docNombreCtrl.text.trim(),
                    grupoId: grpIdCtrl.text.trim(),
                    asignaturaId: asigIdCtrl.text.trim(),
                    facultadId: facIdCtrl.text.trim(),
                    espacioId: modalidad != 'VIRTUAL'
                        ? espIdCtrl.text.trim()
                        : null,
                    espacioNombre: modalidad != 'VIRTUAL'
                        ? espNombreCtrl.text.trim()
                        : 'Virtual',
                    franja: FranjaModel(
                      diaSemana: diaSemana,
                      horaInicio: hIniCtrl.text.trim(),
                      horaFin: hFinCtrl.text.trim(),
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
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
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
                  : _asignaciones.isEmpty
                      ? const Center(
                          child: Text(
                              'No hay asignaciones para este periodo académico.'),
                        )
                      : ListView.separated(
                          itemCount: _asignaciones.length,
                          separatorBuilder: (_, __) =>
                              const Divider(height: 1),
                          itemBuilder: (ctx, i) {
                            final a = _asignaciones[i];
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor: a.exentaGeoespacial
                                    ? Colors.purple.shade50
                                    : Colors.blue.shade50,
                                child: Icon(
                                  a.exentaGeoespacial
                                      ? Icons.computer
                                      : Icons.room,
                                  color: a.exentaGeoespacial
                                      ? Colors.purple
                                      : Colors.blue,
                                ),
                              ),
                              title: Text(
                                '${a.docenteNombre} — Grupo ${a.grupoId}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                              subtitle: Text(
                                '${a.franja.diaNombre} ${a.franja.horaInicio} - ${a.franja.horaFin} | Espacio: ${a.espacioNombre ?? a.espacioId ?? "Sin aula física"}',
                              ),
                              trailing: Chip(
                                label: Text(
                                  a.modalidad,
                                  style: const TextStyle(fontSize: 11),
                                ),
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
