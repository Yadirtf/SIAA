// marcaje_historial_screen.dart — Pantalla de historial cronológico de marcajes propios (US-MAR-08)
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/repositories/marcaje_repository.dart';
import '../../domain/models/marcaje_historial_model.dart';

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
      _mesSeleccionado = DateTime(_mesSeleccionado.year, _mesSeleccionado.month + offset, 1);
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
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
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
            Icon(Icons.history_toggle_off_rounded, size: 64, color: Colors.grey.shade400),
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
          return _buildItemCard(item);
        },
      ),
    );
  }

  Widget _buildItemCard(MarcajeHistorialItem item) {
    Color badgeBg;
    Color badgeFg;
    String badgeText;

    if (item.anulado) {
      badgeBg = Colors.grey.shade200;
      badgeFg = Colors.grey.shade800;
      badgeText = 'ANULADO';
    } else if (item.esAceptado) {
      badgeBg = Colors.green.shade50;
      badgeFg = Colors.green.shade800;
      badgeText = 'ACEPTADO';
    } else if (item.esAusencia) {
      badgeBg = Colors.orange.shade50;
      badgeFg = Colors.orange.shade800;
      badgeText = 'AUSENCIA';
    } else {
      badgeBg = Colors.red.shade50;
      badgeFg = Colors.red.shade800;
      badgeText = 'RECHAZADO';
    }

    final dateFormat = DateFormat('dd/MM/yyyy hh:mm a');

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        title: Text(
          item.asignatura,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
        subtitle: Text(
          '${item.tipo} • ${dateFormat.format(item.timestampServidor)}',
          style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: badgeBg,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            badgeText,
            style: TextStyle(color: badgeFg, fontWeight: FontWeight.bold, fontSize: 11),
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailRow('Aula / Espacio:', item.espacioCodigo),
                _buildDetailRow('Origen:', item.origen),
                if (item.motivoRechazo != null)
                  _buildDetailRow('Motivo:', item.motivoRechazo!, isAlert: true),
                if (item.precisionMetros > 0)
                  _buildDetailRow('Precisión GPS:', '±${item.precisionMetros.toStringAsFixed(1)}m'),
                if (item.distanciaMetros != null)
                  _buildDetailRow('Distancia al aula:', '${item.distanciaMetros!.toStringAsFixed(1)}m'),
                _buildDetailRow(
                  'Coordenadas:',
                  '[${item.longitud.toStringAsFixed(5)}, ${item.latitud.toStringAsFixed(5)}]',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isAlert = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isAlert ? Colors.red.shade700 : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
