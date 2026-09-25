import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_text_styles.dart';
import '../../data/models/academico_models.dart';
import '../bloc/academico_bloc.dart';
import '../bloc/academico_event.dart';

class ProgramaDialog extends StatefulWidget {
  final List<FacultadModel> facultades;

  const ProgramaDialog({super.key, required this.facultades});

  @override
  State<ProgramaDialog> createState() => _ProgramaDialogState();
}

class _ProgramaDialogState extends State<ProgramaDialog> {
  final _codigoCtrl = TextEditingController();
  final _nombreCtrl = TextEditingController();
  String? _selectedFacultadId;

  @override
  void initState() {
    super.initState();
    if (widget.facultades.isNotEmpty) {
      _selectedFacultadId = widget.facultades.first.id;
    }
  }

  String? _codigoError;
  String? _nombreError;
  String? _facultadError;

  @override
  void dispose() {
    _codigoCtrl.dispose();
    _nombreCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    final codigo = _codigoCtrl.text.trim();
    final nombre = _nombreCtrl.text.trim();
    final facId = _selectedFacultadId;

    setState(() {
      _codigoError = codigo.isEmpty ? 'El código es obligatorio' : null;
      _nombreError = nombre.isEmpty ? 'El nombre es obligatorio' : null;
      _facultadError = facId == null ? 'Seleccione una facultad' : null;
    });

    if (codigo.isNotEmpty && nombre.isNotEmpty && facId != null) {
      context.read<AcademicoBloc>().add(
            CreateProgramaEvent(
              codigo: codigo,
              nombre: nombre,
              facultadId: facId,
            ),
          );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.facultades.isEmpty) {
      return AlertDialog(
        title: Text('Nuevo Programa Académico', style: AppTextStyles.h3),
        content: const Text(
          'Debe existir al menos una Facultad registrada antes de crear un programa.',
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
      title: Text('Nuevo Programa Académico', style: AppTextStyles.h3),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _codigoCtrl,
              decoration: InputDecoration(
                labelText: 'Código (ej: PROG-SIS)',
                prefixIcon: const Icon(Icons.code_rounded),
                errorText: _codigoError,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _nombreCtrl,
              decoration: InputDecoration(
                labelText: 'Nombre del Programa',
                prefixIcon: const Icon(Icons.school_rounded),
                errorText: _nombreError,
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _selectedFacultadId,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: 'Facultad',
                prefixIcon: const Icon(Icons.account_balance_outlined),
                errorText: _facultadError,
              ),
              items: widget.facultades
                  .map(
                    (f) => DropdownMenuItem(
                      value: f.id,
                      child: Text('${f.codigo} - ${f.nombre}'),
                    ),
                  )
                  .toList(),
              onChanged: (val) {
                if (val != null) setState(() => _selectedFacultadId = val);
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _submit,
          child: const Text('Crear Programa'),
        ),
      ],
    );
  }
}
