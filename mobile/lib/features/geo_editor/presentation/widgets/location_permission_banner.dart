import 'package:flutter/material.dart';
import '../../domain/services/gps_location_service.dart';

/// Banner de advertencia que informa al usuario cuando el GPS está apagado
/// o los permisos de ubicación están denegados (RN-005).
class LocationPermissionBanner extends StatelessWidget {
  final EstadoPermisoUbicacion? estadoPermiso;
  final VoidCallback onAbrirAjustesUbicacion;
  final VoidCallback onAbrirAjustesAplicacion;
  final VoidCallback onSolicitarPermiso;

  const LocationPermissionBanner({
    super.key,
    required this.estadoPermiso,
    required this.onAbrirAjustesUbicacion,
    required this.onAbrirAjustesAplicacion,
    required this.onSolicitarPermiso,
  });

  @override
  Widget build(BuildContext context) {
    if (estadoPermiso == null || estadoPermiso == EstadoPermisoUbicacion.concedido) {
      return const SizedBox.shrink();
    }

    String titulo;
    String accionTexto;
    VoidCallback onAccion;
    IconData icono;

    switch (estadoPermiso!) {
      case EstadoPermisoUbicacion.servicioDesactivado:
        titulo = 'El GPS del dispositivo está desactivado. Actívelo para capturar vértices.';
        accionTexto = 'Activar GPS';
        onAccion = onAbrirAjustesUbicacion;
        icono = Icons.location_off;
        break;
      case EstadoPermisoUbicacion.denegadoPermanentemente:
        titulo = 'Permiso de ubicación denegado en ajustes del sistema. Habilítelo para usar el GPS.';
        accionTexto = 'Abrir Ajustes';
        onAccion = onAbrirAjustesAplicacion;
        icono = Icons.settings;
        break;
      case EstadoPermisoUbicacion.denegado:
      default:
        titulo = 'Se requiere permiso de ubicación para delimitar el espacio en sitio.';
        accionTexto = 'Conceder';
        onAccion = onSolicitarPermiso;
        icono = Icons.location_searching;
        break;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      color: const Color(0xFFDC2626), // Red 600
      child: Row(
        children: [
          Icon(icono, color: Colors.white, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              titulo,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFFDC2626),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              minimumSize: const Size(0, 30),
            ),
            onPressed: onAccion,
            child: Text(
              accionTexto,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
