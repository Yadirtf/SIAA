import 'package:flutter/material.dart';

/// Interpreta "latitud, longitud" tal como lo copia Google Maps
/// (p. ej. `1.14771, -76.65112`). Devuelve `null` si no es válido.
({double latitud, double longitud})? parsearLatLon(String texto) {
  final partes = texto.split(RegExp(r'[,;\s]+')).where((p) => p.isNotEmpty);
  if (partes.length != 2) return null;
  final lat = double.tryParse(partes.first);
  final lon = double.tryParse(partes.last);
  if (lat == null || lon == null) return null;
  if (lat < -90 || lat > 90 || lon < -180 || lon > 180) return null;
  return (latitud: lat, longitud: lon);
}

/// Campo para centrar el mapa en unas coordenadas pegadas desde Google Maps.
class IrACoordenadas extends StatefulWidget {
  final void Function(double latitud, double longitud) onIr;

  const IrACoordenadas({super.key, required this.onIr});

  @override
  State<IrACoordenadas> createState() => _IrACoordenadasState();
}

class _IrACoordenadasState extends State<IrACoordenadas> {
  final _ctrl = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _ir() {
    final punto = parsearLatLon(_ctrl.text);
    setState(() => _error = punto == null ? 'Use "latitud, longitud"' : null);
    if (punto != null) widget.onIr(punto.latitud, punto.longitud);
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 300,
      child: TextField(
        controller: _ctrl,
        onSubmitted: (_) => _ir(),
        decoration: InputDecoration(
          isDense: true,
          labelText: 'Ir a latitud, longitud',
          hintText: '1.14771, -76.65112',
          errorText: _error,
          suffixIcon: IconButton(
            icon: const Icon(Icons.travel_explore_rounded),
            tooltip: 'Centrar el mapa',
            onPressed: _ir,
          ),
        ),
      ),
    );
  }
}
