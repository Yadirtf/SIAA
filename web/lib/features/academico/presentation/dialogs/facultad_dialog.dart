import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_text_styles.dart';
import '../bloc/academico_bloc.dart';
import '../bloc/academico_event.dart';

class FacultadDialog extends StatefulWidget {
  const FacultadDialog({super.key});

  @override
  State<FacultadDialog> createState() => _FacultadDialogState();
}

class _FacultadDialogState extends State<FacultadDialog> {
  final _codigoCtrl = TextEditingController();
  final _nombreCtrl = TextEditingController();

  String? _codigoError;
  String? _nombreError;

  @override
  void dispose() {
    _codigoCtrl.dispose();
    _nombreCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    final codigo = _codigoCtrl.text.trim();
    final nombre = _nombreCtrl.text.trim();

    setState(() {
      _codigoError = codigo.isEmpty ? 'El código es obligatorio' : null;
      _nombreError = nombre.isEmpty ? 'El nombre es obligatorio' : null;
    });

    if (codigo.isNotEmpty && nombre.isNotEmpty) {
      context.read<AcademicoBloc>().add(
            CreateFacultadEvent(codigo: codigo, nombre: nombre),
          );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Nueva Facultad', style: AppTextStyles.h3),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _codigoCtrl,
              decoration: InputDecoration(
                labelText: 'Código (ej: FAC-ING)',
                prefixIcon: const Icon(Icons.code_rounded),
                errorText: _codigoError,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _nombreCtrl,
              decoration: InputDecoration(
                labelText: 'Nombre de la Facultad',
                prefixIcon: const Icon(Icons.account_balance_outlined),
                errorText: _nombreError,
              ),
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
          child: const Text('Crear Facultad'),
        ),
      ],
    );
  }
}
