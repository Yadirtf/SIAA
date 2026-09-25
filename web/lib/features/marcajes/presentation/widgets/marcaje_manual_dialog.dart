// marcaje_manual_dialog.dart — Modal con selectores dinámicos para registro de marcaje manual administrativo (US-MAR-09 AC-04)
import 'package:flutter/material.dart';
import '../../data/datasources/marcajes_admin_remote_datasource.dart';
import '../../domain/models/sesion_summary_model.dart';
import '../../domain/models/usuario_summary_model.dart';
import 'buscador_entidad_field.dart';

class MarcajeManualDialog extends StatefulWidget {
  final void Function({
    required String sesionId,
    required String usuarioId,
    required String tipo,
    required String resultado,
    required String motivo,
  }) onConfirmar;

  const MarcajeManualDialog({super.key, required this.onConfirmar});

  static Future<void> show(
    BuildContext context, {
    required void Function({
      required String sesionId,
      required String usuarioId,
      required String tipo,
      required String resultado,
      required String motivo,
    }) onConfirmar,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => MarcajeManualDialog(onConfirmar: onConfirmar),
    );
  }

  @override
  State<MarcajeManualDialog> createState() => _MarcajeManualDialogState();
}

class _MarcajeManualDialogState extends State<MarcajeManualDialog> {
  final _datasource = MarcajesAdminRemoteDataSource();
  List<UsuarioSummaryModel> _usuarios = [];
  List<SesionSummaryModel> _sesiones = [];

  String? _sesionId;
  String? _usuarioId;
  final _motivoCtrl = TextEditingController();
  String _tipo = 'ENTRADA';
  String _resultado = 'ACEPTADO';

  @override
  void initState() {
    super.initState();
    _cargarOpciones();
  }

  Future<void> _cargarOpciones() async {
    final u = await _datasource.obtenerUsuarios();
    final s = await _datasource.obtenerSesiones();
    if (mounted) {
      setState(() {
        _usuarios = u;
        _sesiones = s;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final chars = _motivoCtrl.text.trim().length;
    final puedeGuardar = _sesionId != null &&
        _sesionId!.isNotEmpty &&
        _usuarioId != null &&
        _usuarioId!.isNotEmpty &&
        chars >= 20;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Row(
        children: [
          Icon(Icons.add_task_rounded, color: Colors.teal),
          SizedBox(width: 8),
          Text('Nuevo Marcaje Manual'),
        ],
      ),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Seleccione la sesión académica y el usuario al cual registrar la asistencia manual:',
                style: TextStyle(fontSize: 13, color: Colors.black87),
              ),
              const SizedBox(height: 14),
              BuscadorEntidadField<SesionSummaryModel>(
                label: 'Sesión Académica *',
                hint: 'Seleccione o busque por fecha/código...',
                icon: Icons.calendar_month_rounded,
                items: _sesiones,
                labelExtractor: (s) => s.etiquetaSelector,
                idExtractor: (s) => s.id,
                filter: (s, q) => s.etiquetaSelector.toLowerCase().contains(q.toLowerCase()),
                onSelected: (id) => setState(() => _sesionId = id),
                isRequired: true,
              ),
              const SizedBox(height: 14),
              BuscadorEntidadField<UsuarioSummaryModel>(
                label: 'Usuario (Docente o Estudiante) *',
                hint: 'Seleccione o busque por nombre, apellido o correo...',
                icon: Icons.person_search_rounded,
                items: _usuarios,
                labelExtractor: (u) => u.etiquetaSelector,
                idExtractor: (u) => u.id,
                filter: (u, q) =>
                    u.nombreCompleto.toLowerCase().contains(q.toLowerCase()) ||
                    u.correo.toLowerCase().contains(q.toLowerCase()),
                onSelected: (id) => setState(() => _usuarioId = id),
                isRequired: true,
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _tipo,
                      decoration: const InputDecoration(labelText: 'Tipo', border: OutlineInputBorder(), isDense: true),
                      items: const [
                        DropdownMenuItem(value: 'ENTRADA', child: Text('ENTRADA')),
                        DropdownMenuItem(value: 'SALIDA', child: Text('SALIDA')),
                      ],
                      onChanged: (val) => setState(() => _tipo = val!),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _resultado,
                      decoration: const InputDecoration(labelText: 'Resultado', border: OutlineInputBorder(), isDense: true),
                      items: const [
                        DropdownMenuItem(value: 'ACEPTADO', child: Text('ACEPTADO')),
                        DropdownMenuItem(value: 'RECHAZADO', child: Text('RECHAZADO')),
                      ],
                      onChanged: (val) => setState(() => _resultado = val!),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Motivo (Auditoría obligatoria):', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(
                    '$chars / 20 mín',
                    style: TextStyle(
                      color: chars >= 20 ? Colors.green : Colors.red,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _motivoCtrl,
                maxLines: 3,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  hintText: 'Justifique detalladamente el registro manual del docente o estudiante.',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        ElevatedButton(
          onPressed: puedeGuardar
              ? () {
                  Navigator.pop(context);
                  widget.onConfirmar(
                    sesionId: _sesionId!,
                    usuarioId: _usuarioId!,
                    tipo: _tipo,
                    resultado: _resultado,
                    motivo: _motivoCtrl.text.trim(),
                  );
                }
              : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.teal.shade700,
            foregroundColor: Colors.white,
          ),
          child: const Text('Crear Marcaje Manual'),
        ),
      ],
    );
  }
}
