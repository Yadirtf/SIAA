import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../data/models/academico_models.dart';
import '../bloc/academico_bloc.dart';
import '../bloc/academico_event.dart';

class AsignacionDialog extends StatefulWidget {
  final List<PeriodoModel> periodos;
  final List<GrupoModel> grupos;
  final List<AsignaturaModel> asignaturas;

  const AsignacionDialog({
    super.key,
    required this.periodos,
    required this.grupos,
    required this.asignaturas,
  });

  @override
  State<AsignacionDialog> createState() => _AsignacionDialogState();
}

class _AsignacionDialogState extends State<AsignacionDialog> {
  final _formKey = GlobalKey<FormState>();

  String? _selectedPeriodoId;
  String? _selectedGrupoId;
  String _modalidad = 'PRESENCIAL';
  int _diaSemana = 1; // 1 = Lunes

  final _docenteIdCtrl = TextEditingController();
  final _docenteNombreCtrl = TextEditingController();
  final _docenteCodocenteIdCtrl = TextEditingController();
  final _espacioIdCtrl = TextEditingController();
  final _espacioNombreCtrl = TextEditingController();
  final _horaInicioCtrl = TextEditingController(text: '08:00');
  final _horaFinCtrl = TextEditingController(text: '10:00');

  static const List<Map<String, dynamic>> _dias = [
    {'id': 1, 'nombre': 'Lunes'},
    {'id': 2, 'nombre': 'Martes'},
    {'id': 3, 'nombre': 'Miércoles'},
    {'id': 4, 'nombre': 'Jueves'},
    {'id': 5, 'nombre': 'Viernes'},
    {'id': 6, 'nombre': 'Sábado'},
  ];

  @override
  void initState() {
    super.initState();
    if (widget.periodos.isNotEmpty) {
      _selectedPeriodoId = widget.periodos.first.id;
    }
    if (widget.grupos.isNotEmpty) {
      _selectedGrupoId = widget.grupos.first.id;
    }
  }

  @override
  void dispose() {
    _docenteIdCtrl.dispose();
    _docenteNombreCtrl.dispose();
    _docenteCodocenteIdCtrl.dispose();
    _espacioIdCtrl.dispose();
    _espacioNombreCtrl.dispose();
    _horaInicioCtrl.dispose();
    _horaFinCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedPeriodoId == null || _selectedGrupoId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Seleccione periodo y grupo')),
      );
      return;
    }

    final selectedGrupo = widget.grupos.firstWhere(
      (g) => g.id == _selectedGrupoId,
      orElse: () => widget.grupos.first,
    );

    final docenteIds = <String>[_docenteIdCtrl.text.trim()];
    if (_docenteCodocenteIdCtrl.text.trim().isNotEmpty) {
      docenteIds.add(_docenteCodocenteIdCtrl.text.trim());
    }

    final payload = {
      'periodoId': _selectedPeriodoId,
      'grupoId': _selectedGrupoId,
      'asignaturaId': selectedGrupo.asignaturaId,
      'docenteIds': docenteIds,
      'docenteNombre': _docenteNombreCtrl.text.trim(),
      'espacioId': _modalidad == 'VIRTUAL' ? null : _espacioIdCtrl.text.trim(),
      'espacioNombre':
          _modalidad == 'VIRTUAL' ? 'Virtual' : _espacioNombreCtrl.text.trim(),
      'modalidad': _modalidad,
      'franja': {
        'diaSemana': _diaSemana,
        'horaInicio': _horaInicioCtrl.text.trim(),
        'horaFin': _horaFinCtrl.text.trim(),
        'zonaHoraria': 'America/Bogota',
      },
    };

    context.read<AcademicoBloc>().add(CreateAsignacionEvent(payload));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.periodos.isEmpty || widget.grupos.isEmpty) {
      return AlertDialog(
        title: Text('Nueva Asignación', style: AppTextStyles.h3),
        content: const Text(
          'Se requiere al menos un Periodo y un Grupo registrado para crear asignaciones.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Entendido'),
          ),
        ],
      );
    }

    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.add_chart_rounded, color: AppColors.primaryAccent),
          const SizedBox(width: 8),
          Text('Nueva Asignación Horaria (US-ACA-03)', style: AppTextStyles.h3),
        ],
      ),
      content: SingleChildScrollView(
        child: SizedBox(
          width: 520,
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DropdownButtonFormField<String>(
                  value: _selectedPeriodoId,
                  decoration: const InputDecoration(
                    labelText: 'Periodo Académico *',
                    prefixIcon: Icon(Icons.calendar_month_outlined),
                  ),
                  items: widget.periodos
                      .map((p) => DropdownMenuItem(
                            value: p.id,
                            child: Text('${p.codigo} - ${p.nombre}'),
                          ))
                      .toList(),
                  onChanged: (val) => setState(() => _selectedPeriodoId = val),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _selectedGrupoId,
                  decoration: const InputDecoration(
                    labelText: 'Grupo / Curso *',
                    prefixIcon: Icon(Icons.groups_outlined),
                  ),
                  items: widget.grupos.map((g) {
                    final asig = widget.asignaturas.firstWhere(
                      (a) => a.id == g.asignaturaId,
                      orElse: () => const AsignaturaModel(
                        id: '',
                        codigo: '',
                        nombre: 'Asignatura',
                        programaId: '',
                        creditos: 0,
                      ),
                    );
                    return DropdownMenuItem(
                      value: g.id,
                      child: Text('Grupo ${g.numero} (${asig.nombre})'),
                    );
                  }).toList(),
                  onChanged: (val) => setState(() => _selectedGrupoId = val),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _docenteIdCtrl,
                        decoration: const InputDecoration(
                          labelText: 'ID / Doc. Docente *',
                          prefixIcon: Icon(Icons.badge_outlined),
                        ),
                        validator: (v) =>
                            v == null || v.trim().isEmpty ? 'Requerido' : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _docenteNombreCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Nombre del Docente *',
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                        validator: (v) =>
                            v == null || v.trim().isEmpty ? 'Requerido' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _docenteCodocenteIdCtrl,
                  decoration: const InputDecoration(
                    labelText: 'ID Co-docente Adicional (Opcional, US-ACA-08)',
                    prefixIcon: Icon(Icons.group_add_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _modalidad,
                        decoration: const InputDecoration(
                          labelText: 'Modalidad *',
                          prefixIcon: Icon(Icons.settings_ethernet_rounded),
                        ),
                        items: const [
                          DropdownMenuItem(
                              value: 'PRESENCIAL', child: Text('Presencial')),
                          DropdownMenuItem(
                              value: 'VIRTUAL', child: Text('Virtual')),
                          DropdownMenuItem(
                              value: 'HIBRIDA', child: Text('Híbrida')),
                        ],
                        onChanged: (val) =>
                            setState(() => _modalidad = val ?? 'PRESENCIAL'),
                      ),
                    ),
                    if (_modalidad != 'VIRTUAL') ...[
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _espacioIdCtrl,
                          decoration: const InputDecoration(
                            labelText: 'ID / Código Aula *',
                            prefixIcon: Icon(Icons.meeting_room_outlined),
                          ),
                          validator: (v) => _modalidad == 'PRESENCIAL' &&
                                  (v == null || v.trim().isEmpty)
                              ? 'Requerido'
                              : null,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 16),
                Text('Franja Horaria Recurrente (US-ACA-02)',
                    style: AppTextStyles.bodyMedium
                        .copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: DropdownButtonFormField<int>(
                        value: _diaSemana,
                        decoration: const InputDecoration(
                          labelText: 'Día Semana *',
                          prefixIcon: Icon(Icons.view_week_outlined),
                        ),
                        items: _dias
                            .map((d) => DropdownMenuItem<int>(
                                  value: d['id'] as int,
                                  child: Text(d['nombre'] as String),
                                ))
                            .toList(),
                        onChanged: (val) =>
                            setState(() => _diaSemana = val ?? 1),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        controller: _horaInicioCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Inicio (HH:mm)',
                          hintText: '08:00',
                        ),
                        validator: (v) =>
                            v == null || v.trim().isEmpty ? 'Requerido' : null,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        controller: _horaFinCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Fin (HH:mm)',
                          hintText: '10:00',
                        ),
                        validator: (v) =>
                            v == null || v.trim().isEmpty ? 'Requerido' : null,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton.icon(
          onPressed: _submit,
          icon: const Icon(Icons.save_rounded, size: 18),
          label: const Text('Guardar Asignación'),
        ),
      ],
    );
  }
}
