import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_text_styles.dart';
import '../../data/models/academico_models.dart';
import '../bloc/academico_bloc.dart';
import '../bloc/academico_event.dart';

class GrupoDialog extends StatefulWidget {
  final List<AsignaturaModel> asignaturas;
  final List<PeriodoModel> periodos;

  const GrupoDialog({
    super.key,
    required this.asignaturas,
    required this.periodos,
  });

  @override
  State<GrupoDialog> createState() => _GrupoDialogState();
}

class _GrupoDialogState extends State<GrupoDialog> {
  final _numeroCtrl = TextEditingController();
  final _cupoCtrl = TextEditingController(text: '30');
  String? _selectedAsignaturaId;
  String? _selectedPeriodoId;

  @override
  void initState() {
    super.initState();
    if (widget.asignaturas.isNotEmpty) {
      _selectedAsignaturaId = widget.asignaturas.first.id;
    }
    if (widget.periodos.isNotEmpty) {
      _selectedPeriodoId = widget.periodos.first.id;
    }
  }

  @override
  void dispose() {
    _numeroCtrl.dispose();
    _cupoCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    final numero = _numeroCtrl.text.trim();
    final cupo = int.tryParse(_cupoCtrl.text.trim()) ?? 30;
    final asignaturaId = _selectedAsignaturaId;
    final periodoId = _selectedPeriodoId;

    if (numero.isEmpty || asignaturaId == null || periodoId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor complete todos los campos obligatorios'),
          backgroundColor: Colors.amber,
        ),
      );
      return;
    }

    context.read<AcademicoBloc>().add(
          CreateGrupoEvent(
            numero: numero,
            asignaturaId: asignaturaId,
            periodoId: periodoId,
            cupo: cupo,
          ),
        );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.asignaturas.isEmpty || widget.periodos.isEmpty) {
      return AlertDialog(
        title: Text('Nuevo Grupo', style: AppTextStyles.h3),
        content: const Text(
          'Debe existir al menos una Asignatura y un Periodo Académico registrado antes de crear un grupo.',
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
      title: Text('Nuevo Grupo', style: AppTextStyles.h3),
      content: SingleChildScrollView(
        child: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _numeroCtrl,
                decoration: const InputDecoration(
                  labelText: 'Código / Número de Grupo (ej: GRP-01)',
                  prefixIcon: Icon(Icons.group_work_rounded),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _cupoCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Cupo Máximo de Estudiantes',
                  prefixIcon: Icon(Icons.people_rounded),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _selectedAsignaturaId,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Asignatura',
                  prefixIcon: Icon(Icons.menu_book_rounded),
                ),
                items: widget.asignaturas
                    .map((a) => DropdownMenuItem(
                          value: a.id,
                          child: Text('${a.codigo} - ${a.nombre}'),
                        ))
                    .toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedAsignaturaId = val);
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _selectedPeriodoId,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Periodo Académico',
                  prefixIcon: Icon(Icons.calendar_today_rounded),
                ),
                items: widget.periodos
                    .map((p) => DropdownMenuItem(
                          value: p.id,
                          child: Text('${p.codigo} (${p.estado})'),
                        ))
                    .toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedPeriodoId = val);
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _submit,
          child: const Text('Crear Grupo'),
        ),
      ],
    );
  }
}
