import 'package:flutter/material.dart';
import '../../data/academico_models.dart';
import '../../data/academico_repository.dart';

class ExcepcionesTab extends StatefulWidget {
  final AcademicoRepository repository;

  const ExcepcionesTab({super.key, required this.repository});

  @override
  State<ExcepcionesTab> createState() => _ExcepcionesTabState();
}

class _ExcepcionesTabState extends State<ExcepcionesTab> {
  bool _loading = true;
  String? _error;
  List<ExcepcionModel> _excepciones = [];

  @override
  void initState() {
    super.initState();
    _cargarExcepciones();
  }

  Future<void> _cargarExcepciones() async {
    setState(() => _loading = true);
    try {
      final list = await widget.repository.listarExcepciones();
      if (mounted) {
        setState(() {
          _excepciones = list;
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

  Future<void> _dialogoNuevaExcepcion() async {
    final nombreCtrl = TextEditingController();
    final fIniCtrl = TextEditingController();
    final fFinCtrl = TextEditingController();
    final ambitoIdCtrl = TextEditingController();
    String tipo = 'FESTIVO';
    String ambito = 'GLOBAL';

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Nueva Excepción de Calendario (US-ACA-04)'),
          content: SizedBox(
            width: 440,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nombreCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Nombre / Motivo (ej. Día de la Raza)*',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: tipo,
                    decoration: const InputDecoration(
                      labelText: 'Tipo de Excepción',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'FESTIVO', child: Text('Festivo')),
                      DropdownMenuItem(value: 'RECESO', child: Text('Receso Académico')),
                      DropdownMenuItem(
                          value: 'JORNADA_INSTITUCIONAL',
                          child: Text('Jornada Institucional')),
                      DropdownMenuItem(value: 'PARO', child: Text('Paro / Cese de Actividades')),
                    ],
                    onChanged: (val) {
                      if (val != null) setDialogState(() => tipo = val);
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: ambito,
                    decoration: const InputDecoration(
                      labelText: 'Ámbito de Aplicación (AC-01, AC-05)',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'GLOBAL', child: Text('Global (Todo el Campus)')),
                      DropdownMenuItem(value: 'SEDE', child: Text('Por Sede')),
                      DropdownMenuItem(value: 'FACULTAD', child: Text('Por Facultad')),
                    ],
                    onChanged: (val) {
                      if (val != null) setDialogState(() => ambito = val);
                    },
                  ),
                  if (ambito != 'GLOBAL') ...[
                    const SizedBox(height: 12),
                    TextField(
                      controller: ambitoIdCtrl,
                      decoration: InputDecoration(
                        labelText: 'ID de la $ambito*',
                        border: const OutlineInputBorder(),
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: fIniCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Fecha Inicio (YYYY-MM-DD)*',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: fFinCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Fecha Fin (YYYY-MM-DD)*',
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
                if (nombreCtrl.text.trim().isEmpty ||
                    fIniCtrl.text.trim().isEmpty ||
                    fFinCtrl.text.trim().isEmpty) {
                  return;
                }
                Navigator.of(ctx).pop();
                try {
                  await widget.repository.crearExcepcion(
                    nombre: nombreCtrl.text.trim(),
                    tipo: tipo,
                    ambito: ambito,
                    ambitoId:
                        ambito != 'GLOBAL' ? ambitoIdCtrl.text.trim() : null,
                    fechaInicio: fIniCtrl.text.trim(),
                    fechaFin: fFinCtrl.text.trim(),
                  );
                  _cargarExcepciones();
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
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
                    'Calendario de Excepciones (US-ACA-04)',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Fechas no lectivas (festivos, recesos, paros) que no generan sesión de clase.',
                    style: TextStyle(color: Colors.black54),
                  ),
                ],
              ),
              FilledButton.icon(
                onPressed: _dialogoNuevaExcepcion,
                icon: const Icon(Icons.add),
                label: const Text('Nueva Excepción'),
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
                  : _excepciones.isEmpty
                      ? const Center(
                          child: Text('No hay excepciones registradas.'),
                        )
                      : ListView.separated(
                          itemCount: _excepciones.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (ctx, i) {
                            final exc = _excepciones[i];
                            return ListTile(
                              leading: const CircleAvatar(
                                backgroundColor: Color(0xFFFEF2F2),
                                child: Icon(Icons.event_busy, color: Color(0xFFDC2626)),
                              ),
                              title: Text(
                                exc.nombre,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Text(
                                'Rango: ${exc.fechaInicio} al ${exc.fechaFin}',
                              ),
                              trailing: Wrap(
                                spacing: 8,
                                children: [
                                  Chip(
                                    label: Text(
                                      exc.tipo,
                                      style: const TextStyle(fontSize: 11),
                                    ),
                                    backgroundColor: Colors.red.shade50,
                                  ),
                                  Chip(
                                    label: Text(
                                      exc.ambito,
                                      style: const TextStyle(fontSize: 11),
                                    ),
                                    backgroundColor: Colors.blue.shade50,
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
