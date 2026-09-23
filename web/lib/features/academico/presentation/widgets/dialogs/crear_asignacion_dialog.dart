import 'package:flutter/material.dart';

class CrearAsignacionDialog extends StatefulWidget {
  final Future<void> Function({
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
  }) onGuardar;

  const CrearAsignacionDialog({super.key, required this.onGuardar});

  static Future<void> mostrar(
    BuildContext context, {
    required Future<void> Function({
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
    }) onGuardar,
  }) {
    return showDialog(
      context: context,
      builder: (_) => CrearAsignacionDialog(onGuardar: onGuardar),
    );
  }

  @override
  State<CrearAsignacionDialog> createState() => _CrearAsignacionDialogState();
}

class _CrearAsignacionDialogState extends State<CrearAsignacionDialog> {
  final _docIdCtrl = TextEditingController();
  final _docNombreCtrl = TextEditingController();
  final _grpIdCtrl = TextEditingController();
  final _asigIdCtrl = TextEditingController();
  final _facIdCtrl = TextEditingController();
  final _espIdCtrl = TextEditingController();
  final _espNombreCtrl = TextEditingController();
  final _hIniCtrl = TextEditingController(text: '08:00');
  final _hFinCtrl = TextEditingController(text: '10:00');
  int _diaSemana = 1;
  String _modalidad = 'PRESENCIAL';

  @override
  void dispose() {
    _docIdCtrl.dispose();
    _docNombreCtrl.dispose();
    _grpIdCtrl.dispose();
    _asigIdCtrl.dispose();
    _facIdCtrl.dispose();
    _espIdCtrl.dispose();
    _espNombreCtrl.dispose();
    _hIniCtrl.dispose();
    _hFinCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Nueva Asignación de Horario (US-ACA-03)'),
      content: SizedBox(
        width: 480,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _docNombreCtrl,
                decoration: const InputDecoration(
                  labelText: 'Nombre del Docente*',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _docIdCtrl,
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
                      controller: _grpIdCtrl,
                      decoration: const InputDecoration(
                        labelText: 'ID Grupo*',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _asigIdCtrl,
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
                controller: _facIdCtrl,
                decoration: const InputDecoration(
                  labelText: 'ID Facultad*',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _modalidad,
                decoration: const InputDecoration(
                  labelText: 'Modalidad (US-ACA-03 AC-06)',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'PRESENCIAL', child: Text('Presencial')),
                  DropdownMenuItem(
                    value: 'VIRTUAL',
                    child: Text('Virtual (Exenta de Geocerca)'),
                  ),
                  DropdownMenuItem(value: 'HIBRIDA', child: Text('Híbrida')),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => _modalidad = val);
                },
              ),
              if (_modalidad != 'VIRTUAL') ...[
                const SizedBox(height: 12),
                TextField(
                  controller: _espIdCtrl,
                  decoration: const InputDecoration(
                    labelText: 'ID Espacio / Aula*',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _espNombreCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Nombre de Espacio (ej. Aula 301)',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                initialValue: _diaSemana,
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
                  if (val != null) setState(() => _diaSemana = val);
                },
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _hIniCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Hora Inicio (HH:MM)*',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _hFinCtrl,
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
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () async {
            if (_docNombreCtrl.text.trim().isEmpty ||
                _docIdCtrl.text.trim().isEmpty ||
                _grpIdCtrl.text.trim().isEmpty) {
              return;
            }
            Navigator.of(context).pop();
            await widget.onGuardar(
              docenteId: _docIdCtrl.text.trim(),
              docenteNombre: _docNombreCtrl.text.trim(),
              grupoId: _grpIdCtrl.text.trim(),
              asignaturaId: _asigIdCtrl.text.trim(),
              facultadId: _facIdCtrl.text.trim(),
              espacioId: _modalidad != 'VIRTUAL' ? _espIdCtrl.text.trim() : null,
              espacioNombre: _modalidad != 'VIRTUAL'
                  ? _espNombreCtrl.text.trim()
                  : 'Virtual',
              diaSemana: _diaSemana,
              horaInicio: _hIniCtrl.text.trim(),
              horaFin: _hFinCtrl.text.trim(),
              modalidad: _modalidad,
            );
          },
          child: const Text('Guardar Asignación'),
        ),
      ],
    );
  }
}
