import 'package:flutter/material.dart';
import '../../data/academico_models.dart';
import '../../data/academico_repository.dart';
import '../widgets/dialogs/crear_excepcion_dialog.dart';

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
    await CrearExcepcionDialog.mostrar(
      context,
      onGuardar: ({
        required String nombre,
        required String tipo,
        required String ambito,
        String? ambitoId,
        required String fechaInicio,
        required String fechaFin,
      }) async {
        try {
          await widget.repository.crearExcepcion(
            nombre: nombre,
            tipo: tipo,
            ambito: ambito,
            ambitoId: ambitoId,
            fechaInicio: fechaInicio,
            fechaFin: fechaFin,
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
