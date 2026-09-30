import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_text_styles.dart';
import '../../data/models/academico_models.dart';
import '../bloc/academico_bloc.dart';
import '../bloc/academico_event.dart';

class AsignaturaDialog extends StatefulWidget {
  final List<ProgramaModel> programas;

  const AsignaturaDialog({super.key, required this.programas});

  @override
  State<AsignaturaDialog> createState() => _AsignaturaDialogState();
}

class _AsignaturaDialogState extends State<AsignaturaDialog> {
  final _codigoCtrl = TextEditingController();
  final _nombreCtrl = TextEditingController();
  final _creditosCtrl = TextEditingController(text: '3');
  String? _selectedProgramaId;

  @override
  void initState() {
    super.initState();
    if (widget.programas.isNotEmpty) {
      _selectedProgramaId = widget.programas.first.id;
    }
  }

  @override
  void dispose() {
    _codigoCtrl.dispose();
    _nombreCtrl.dispose();
    _creditosCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    final codigo = _codigoCtrl.text.trim();
    final nombre = _nombreCtrl.text.trim();
    final creditos = int.tryParse(_creditosCtrl.text.trim()) ?? 3;
    final programaId = _selectedProgramaId;

    if (codigo.isEmpty || nombre.isEmpty || programaId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor complete todos los campos obligatorios'),
          backgroundColor: Colors.amber,
        ),
      );
      return;
    }

    context.read<AcademicoBloc>().add(
          CreateAsignaturaEvent(
            codigo: codigo,
            nombre: nombre,
            programaId: programaId,
            creditos: creditos,
          ),
        );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.programas.isEmpty) {
      return AlertDialog(
        title: Text('Nueva Asignatura', style: AppTextStyles.h3),
        content: const Text(
          'Debe existir al menos un Programa Académico registrado antes de crear una asignatura.',
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
      title: Text('Nueva Asignatura', style: AppTextStyles.h3),
      content: SingleChildScrollView(
        child: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _codigoCtrl,
                decoration: const InputDecoration(
                  labelText: 'Código de la Asignatura (ej: ASIG-101)',
                  prefixIcon: Icon(Icons.code_rounded),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _nombreCtrl,
                decoration: const InputDecoration(
                  labelText: 'Nombre de la Asignatura',
                  prefixIcon: Icon(Icons.menu_book_rounded),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _creditosCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Créditos Académicos',
                  prefixIcon: Icon(Icons.numbers_rounded),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _selectedProgramaId,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Programa Académico',
                  prefixIcon: Icon(Icons.school_rounded),
                ),
                items: widget.programas
                    .map((p) => DropdownMenuItem(
                          value: p.id,
                          child: Text('${p.codigo} - ${p.nombre}'),
                        ))
                    .toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedProgramaId = val);
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
          child: const Text('Crear Asignatura'),
        ),
      ],
    );
  }
}
