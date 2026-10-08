import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/models/opcion_catalogo.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../parametros/data/opciones_ambito_datasource.dart';

/// Datos de una excepción nueva (US-ACA-04 AC-01): tipo, rango y ámbito.
class NuevaExcepcion {
  final String nombre;
  final String tipo;
  final String ambito;
  final String? ambitoId;
  final String fechaInicio;
  final String fechaFin;

  const NuevaExcepcion({
    required this.nombre,
    required this.tipo,
    required this.ambito,
    this.ambitoId,
    required this.fechaInicio,
    required this.fechaFin,
  });
}

const _tipos = {
  'FESTIVO': 'Festivo oficial',
  'RECESO': 'Semana de receso',
  'JORNADA_INSTITUCIONAL': 'Jornada institucional',
  'PARO': 'Suspensión o paro',
};
const _ambitos = {
  'GLOBAL': 'Toda la institución',
  'SEDE': 'Una sede',
  'FACULTAD': 'Una facultad',
};

/// Formulario de excepción con ámbito global, de sede o de facultad (AC-05).
class ExcepcionDialog extends StatefulWidget {
  const ExcepcionDialog({super.key});

  static Future<NuevaExcepcion?> mostrar(BuildContext context) =>
      showDialog<NuevaExcepcion>(
        context: context,
        builder: (_) => const ExcepcionDialog(),
      );

  @override
  State<ExcepcionDialog> createState() => _ExcepcionDialogState();
}

class _ExcepcionDialogState extends State<ExcepcionDialog> {
  final _form = GlobalKey<FormState>();
  final _nombre = TextEditingController();
  late final _inicio = TextEditingController(text: _hoy());
  late final _fin = TextEditingController(text: _hoy());
  String _tipo = 'FESTIVO';
  String _ambito = 'GLOBAL';
  String? _ambitoId;
  List<OpcionCatalogo> _opciones = const [];

  static String _hoy() => DateTime.now().toIso8601String().substring(0, 10);

  @override
  void dispose() {
    _nombre.dispose();
    _inicio.dispose();
    _fin.dispose();
    super.dispose();
  }

  Future<void> _cambiarAmbito(String ambito) async {
    setState(() {
      _ambito = ambito;
      _ambitoId = null;
      _opciones = const [];
    });
    if (ambito == 'GLOBAL') return;
    try {
      final opciones = await context.read<FuenteOpcionesAmbito>().opciones(
        ambito,
      );
      if (mounted) setState(() => _opciones = opciones);
    } catch (_) {
      // Sin catálogo disponible el selector queda vacío y el formulario no valida.
    }
  }

  Future<void> _elegirFecha(TextEditingController ctrl) async {
    final actual = DateTime.tryParse(ctrl.text) ?? DateTime.now();
    final f = await showDatePicker(
      context: context,
      initialDate: actual,
      firstDate: DateTime(actual.year - 1),
      lastDate: DateTime(actual.year + 2),
    );
    if (f != null) ctrl.text = f.toIso8601String().substring(0, 10);
  }

  void _guardar() {
    if (!(_form.currentState?.validate() ?? false)) return;
    Navigator.pop(
      context,
      NuevaExcepcion(
        nombre: _nombre.text.trim(),
        tipo: _tipo,
        ambito: _ambito,
        ambitoId: _ambitoId,
        fechaInicio: _inicio.text.trim(),
        fechaFin: _fin.text.trim(),
      ),
    );
  }

  Widget _fecha(String etiqueta, TextEditingController ctrl) => Expanded(
    child: TextFormField(
      controller: ctrl,
      readOnly: true,
      decoration: InputDecoration(
        labelText: etiqueta,
        suffixIcon: const Icon(Icons.event),
      ),
      onTap: () => _elegirFecha(ctrl),
      validator: (v) =>
          DateTime.tryParse(v ?? '') == null ? 'Fecha inválida' : null,
    ),
  );

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Nueva excepción de calendario', style: AppTextStyles.h3),
      content: Form(
        key: _form,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nombre,
              decoration: const InputDecoration(
                labelText: 'Nombre (ej. Día festivo)',
              ),
              validator: (v) => (v ?? '').trim().isEmpty ? 'Requerido' : null,
            ),
            DropdownButtonFormField<String>(
              value: _tipo,
              decoration: const InputDecoration(labelText: 'Tipo'),
              items: [
                for (final e in _tipos.entries)
                  DropdownMenuItem(value: e.key, child: Text(e.value)),
              ],
              onChanged: (v) => setState(() => _tipo = v ?? _tipo),
            ),
            DropdownButtonFormField<String>(
              value: _ambito,
              decoration: const InputDecoration(labelText: 'Ámbito'),
              items: [
                for (final e in _ambitos.entries)
                  DropdownMenuItem(value: e.key, child: Text(e.value)),
              ],
              onChanged: (v) => _cambiarAmbito(v ?? 'GLOBAL'),
            ),
            if (_ambito != 'GLOBAL')
              DropdownButtonFormField<String>(
                value: _ambitoId,
                decoration: InputDecoration(
                  labelText: _ambito == 'SEDE' ? 'Sede' : 'Facultad',
                ),
                items: [
                  for (final o in _opciones)
                    DropdownMenuItem(value: o.id, child: Text(o.etiqueta)),
                ],
                onChanged: (v) => setState(() => _ambitoId = v),
                validator: (v) => v == null ? 'Elija a quién aplica' : null,
              ),
            const SizedBox(height: 8),
            Row(
              children: [
                _fecha('Desde', _inicio),
                const SizedBox(width: 12),
                _fecha('Hasta', _fin),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Las sesiones ya generadas en esas fechas se cancelarán con este motivo; '
              'los marcajes hechos se conservan.',
              style: AppTextStyles.bodySmall,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(onPressed: _guardar, child: const Text('Guardar')),
      ],
    );
  }
}
