// marcaje_historial_screen.dart — Historial propio: cronología por mes con estado por
// color (US-MAR-08, §9.1). Muestra asignatura, grupo y aula por nombre.
import 'package:flutter/material.dart';

import '../../../../core/network/api_error.dart';
import '../../../../core/utils/fechas_es.dart';
import '../../../../shared/widgets/estado_vista.dart';
import '../../../auth/presentation/permisos_sesion.dart';
import '../../../justificaciones/presentation/screens/justificacion_form_screen.dart';
import '../../data/repositories/marcaje_repository.dart';
import '../../domain/models/marcaje_historial_model.dart';
import '../widgets/historial_item_card.dart';

class MarcajeHistorialScreen extends StatefulWidget {
  final MarcajeRepository? repository;

  const MarcajeHistorialScreen({super.key, this.repository});

  @override
  State<MarcajeHistorialScreen> createState() => _MarcajeHistorialScreenState();
}

class _MarcajeHistorialScreenState extends State<MarcajeHistorialScreen> {
  late final MarcajeRepository _repository;
  bool _cargando = true;
  bool _cargandoMas = false;
  String? _error;
  List<MarcajeHistorialItem> _items = [];
  int _pagina = 1;
  bool _hayMas = false;
  DateTime _mes = DateTime(DateTime.now().year, DateTime.now().month);

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? MarcajeRepository();
    _cargar();
  }

  String get _mesIso => fechaIso(_mes).substring(0, 7);

  Future<void> _cargar() async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final res = await _repository.consultarHistorial(mes: _mesIso);
      if (!mounted) return;
      setState(() {
        _items = res.items;
        _pagina = res.pagina;
        _hayMas = res.hayMas;
        _cargando = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = mensajeDeError(e,
            porDefecto: 'No se pudo cargar el historial. Inténtalo de nuevo.');
        _cargando = false;
      });
    }
  }

  Future<void> _cargarMas() async {
    setState(() => _cargandoMas = true);
    try {
      final res = await _repository.consultarHistorial(
          mes: _mesIso, pagina: _pagina + 1);
      if (!mounted) return;
      setState(() {
        _items = [..._items, ...res.items];
        _pagina = res.pagina;
        _hayMas = res.hayMas;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(mensajeDeError(e))));
      }
    } finally {
      if (mounted) setState(() => _cargandoMas = false);
    }
  }

  void _cambiarMes(int offset) {
    setState(() => _mes = DateTime(_mes.year, _mes.month + offset));
    _cargar();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                tooltip: 'Mes anterior',
                onPressed: () => _cambiarMes(-1),
              ),
              Expanded(
                child: Text(
                  mesAnio(_mes),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                tooltip: 'Mes siguiente',
                onPressed: () => _cambiarMes(1),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(child: _cuerpo()),
      ],
    );
  }

  Widget _cuerpo() {
    if (_cargando) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return EstadoError(mensaje: _error!, onReintentar: _cargar);
    }
    if (_items.isEmpty) {
      return RefreshIndicator(
        onRefresh: _cargar,
        child: ListView(children: const [
          SizedBox(height: 80),
          EstadoVacio(
            icono: Icons.history_toggle_off_rounded,
            mensaje: 'No hay registros de marcaje en este mes',
          ),
        ]),
      );
    }
    return RefreshIndicator(
      onRefresh: _cargar,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _items.length + (_hayMas ? 1 : 0),
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          if (index == _items.length) {
            return Center(
              child: _cargandoMas
                  ? const CircularProgressIndicator()
                  : OutlinedButton(
                      onPressed: _cargarMas, child: const Text('Cargar más')),
            );
          }
          final item = _items[index];
          return HistorialItemCard(
            item: item,
            // Solo quien puede radicar (docente) ve la acción "Justificar".
            onJustificar: tienePermiso(context, 'justificacion:crear')
                ? () => _justificar(item)
                : null,
          );
        },
      ),
    );
  }

  Future<void> _justificar(MarcajeHistorialItem item) async {
    final radicada = await JustificacionFormScreen.abrir(
      context,
      sesionId: item.sesionId,
      nombreSesion: item.tituloSesion,
      fechaSesion: fechaCorta(item.timestampServidor.toLocal()),
    );
    if (radicada == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Justificación radicada correctamente')),
      );
    }
  }
}
