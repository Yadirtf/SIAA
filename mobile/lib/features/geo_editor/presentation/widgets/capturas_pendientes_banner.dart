// capturas_pendientes_banner.dart — Aviso de capturas offline en el Editor GPS (US-GEO-10)
// Solo aparece si hay capturas en la cola local; abre la lista de pendientes.
import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/geo/offline_cartografia_service.dart';
import '../screens/capturas_pendientes_screen.dart';

class CapturasPendientesBanner extends StatefulWidget {
  final OfflineCartografiaService? cola;

  const CapturasPendientesBanner({super.key, this.cola});

  @override
  State<CapturasPendientesBanner> createState() =>
      _CapturasPendientesBannerState();
}

class _CapturasPendientesBannerState extends State<CapturasPendientesBanner> {
  late final OfflineCartografiaService _cola =
      widget.cola ?? OfflineCartografiaService.instancia;
  StreamSubscription<void>? _sub;
  List<CapturaOfflineEspacio> _capturas = const [];

  @override
  void initState() {
    super.initState();
    _sub = _cola.cambios.listen((_) => _cargar());
    _cargar();
  }

  Future<void> _cargar() async {
    final capturas = await _cola.obtenerTodas();
    if (mounted) setState(() => _capturas = capturas);
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  int _contar(EstadoSincronizacion e) =>
      _capturas.where((c) => c.estado == e).length;

  @override
  Widget build(BuildContext context) {
    if (_capturas.isEmpty) return const SizedBox.shrink();
    final pendientes = _contar(EstadoSincronizacion.pendienteSincronizacion);
    final atencion = _contar(EstadoSincronizacion.errorValidacion) +
        _contar(EstadoSincronizacion.conflicto);
    final partes = [
      if (pendientes > 0) '$pendientes pendiente(s) de sincronizar',
      if (atencion > 0) '$atencion requieren su revisión',
      if (pendientes == 0 && atencion == 0) 'todas sincronizadas',
    ];
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ListTile(
        leading: Icon(
          atencion > 0
              ? Icons.warning_amber_rounded
              : Icons.cloud_queue_rounded,
          color: atencion > 0 ? Colors.orange.shade800 : null,
        ),
        title: const Text('Capturas sin conexión'),
        subtitle: Text(partes.join(' · ')),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => CapturasPendientesScreen(cola: widget.cola),
        )),
      ),
    );
  }
}
