import 'package:flutter/material.dart';

import '../../../../core/download/guardar_archivo.dart';
import '../../../../core/network/mensaje_error.dart';
import '../../data/cartografia_remote_datasource.dart';

/// Menú "Exportar" con GeoJSON y KML de la cartografía de la sede
/// (US-GEO-11 AC-03): geometría, código, nombre y metadatos.
class ExportarCartografiaBoton extends StatefulWidget {
  final String sedeId;
  final CartografiaRemoteDataSource? dataSource;
  final GuardarArchivo guardar;

  const ExportarCartografiaBoton({
    super.key,
    required this.sedeId,
    this.dataSource,
    this.guardar = guardarEnNavegador,
  });

  @override
  State<ExportarCartografiaBoton> createState() =>
      _ExportarCartografiaBotonState();
}

class _ExportarCartografiaBotonState extends State<ExportarCartografiaBoton> {
  late final _ds = widget.dataSource ?? CartografiaRemoteDataSource();
  bool _exportando = false;

  Future<void> _exportar(String formato) async {
    setState(() => _exportando = true);
    final mensajero = ScaffoldMessenger.of(context);
    try {
      final archivo = await _ds.exportar(
        sedeId: widget.sedeId,
        formato: formato,
      );
      widget.guardar(archivo, 'espacios_cartografia.$formato');
    } catch (e) {
      mensajero.showSnackBar(SnackBar(content: Text(mensajeDeError(e))));
    } finally {
      if (mounted) setState(() => _exportando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      tooltip: 'Exportar cartografía',
      enabled: !_exportando && widget.sedeId.isNotEmpty,
      onSelected: _exportar,
      itemBuilder: (_) => [
        for (final f in formatosCartografia)
          PopupMenuItem(value: f, child: Text('Exportar ${f.toUpperCase()}')),
      ],
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _exportando
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.download_rounded, size: 18),
            const SizedBox(width: 6),
            const Text('Exportar'),
          ],
        ),
      ),
    );
  }
}
