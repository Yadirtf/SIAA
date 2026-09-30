// marcaje_historial_screen.dart — Pantalla de historial cronológico de marcajes propios (US-MAR-08)
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/repositories/marcaje_repository.dart';
import '../../domain/models/marcaje_historial_model.dart';
import '../../../justificaciones/presentation/screens/justificacion_form_screen.dart';
import '../widgets/historial_item_card.dart';

class MarcajeHistorialScreen extends StatefulWidget {
  final MarcajeRepository? repository;

  const MarcajeHistorialScreen({super.key, this.repository});

  @override
  State<MarcajeHistorialScreen> createState() => _MarcajeHistorialScreenState();
}

class _MarcajeHistorialScreenState extends State<MarcajeHistorialScreen> {
  late final MarcajeRepository _repository;
  bool _isLoading = true;
  String? _error;
  List<MarcajeHistorialItem> _items = [];
  DateTime _mesSeleccionado = DateTime.now();

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? MarcajeRepository();
    _cargarHistorial();
  }

  Future<void> _cargarHistorial() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final mesStr = DateFormat('yyyy-MM').format(_mesSeleccionado);
    try {
      final res = await _repository.consultarHistorial(mes: mesStr);
      setState(() {
        _items = res.items;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Error al cargar historial: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  void _cambiarMes(int offset) {
    setState(() {
      _mesSeleccionado =
          DateTime(_mesSeleccionado.year, _mesSeleccionado.month + offset, 1);
    });
    _cargarHistorial();
  }

  @override
  Widget build(BuildContext context) {
    final mesFormat = DateFormat('MMMM yyyy');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Historial de Marcajes'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Selector de mes
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.grey.shade100,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: () => _cambiarMes(-1),
                ),
                Text(
                  mesFormat.format(_mesSeleccionado).toUpperCase(),
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: () => _cambiarMes(1),
                ),
              ],
            ),
          ),
          Expanded(
            child: _buildBody(),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 12),
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _cargarHistorial,
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    if (_items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history_toggle_off_rounded,
                size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text(
              'No hay registros de marcaje en este mes',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 15),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _cargarHistorial,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final item = _items[index];
          return HistorialItemCard(
            item: item,
            onJustificar: () => _justificar(item),
          );
        },
      ),
    );
  }

  Future<void> _justificar(MarcajeHistorialItem item) async {
    final radicada = await JustificacionFormScreen.abrir(
      context,
      sesionId: item.sesionId,
      nombreSesion: item.asignatura,
      fechaSesion: DateFormat('dd/MM/yyyy').format(item.timestampServidor),
    );
    if (radicada == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Justificación radicada correctamente')),
      );
    }
  }
}
