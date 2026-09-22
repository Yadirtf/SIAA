import 'package:flutter/material.dart';

/// Capas cartográficas disponibles para el visor y editor geográfico (RF-GEO-004).
enum CapaMapa {
  googleHibrido,
  esriSatelite,
  openStreetMap;

  /// Plantilla de URL para teselas (XYZ).
  String get urlTemplate {
    switch (this) {
      case CapaMapa.googleHibrido:
        return 'https://mt1.google.com/vt/lyrs=y&x={x}&y={y}&z={z}';
      case CapaMapa.esriSatelite:
        return 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}';
      case CapaMapa.openStreetMap:
        return 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
    }
  }

  /// Nivel máximo de zoom nativo antes de realizar escalado de teselas (overscaling).
  int get maxNativeZoom {
    switch (this) {
      case CapaMapa.googleHibrido:
        return 20; // Cobertura satelital nativa de Google hasta nivel 20
      case CapaMapa.esriSatelite:
        return 18; // Clampeado a 18 para evitar "Map data not yet available" de Esri en z=19+
      case CapaMapa.openStreetMap:
        return 19;
    }
  }

  /// Nombre legible para mensajes y accesibilidad.
  String get nombre {
    switch (this) {
      case CapaMapa.googleHibrido:
        return 'Google Satélite Híbrido (HD)';
      case CapaMapa.esriSatelite:
        return 'Esri Satélite (Puro)';
      case CapaMapa.openStreetMap:
        return 'OpenStreetMap (Callejero)';
    }
  }

  /// Atribución oficial requerida para cada proveedor de mapas.
  String get atribucion {
    switch (this) {
      case CapaMapa.googleHibrido:
        return 'Imágenes © Google';
      case CapaMapa.esriSatelite:
        return 'Tiles © Esri';
      case CapaMapa.openStreetMap:
        return '© OpenStreetMap contributors';
    }
  }

  /// Ícono representativo de la capa.
  IconData get icono {
    switch (this) {
      case CapaMapa.googleHibrido:
        return Icons.satellite_alt_rounded;
      case CapaMapa.esriSatelite:
        return Icons.public;
      case CapaMapa.openStreetMap:
        return Icons.map_outlined;
    }
  }

  /// Siguiente capa en el ciclo de rotación rápida.
  CapaMapa get siguiente {
    switch (this) {
      case CapaMapa.googleHibrido:
        return CapaMapa.esriSatelite;
      case CapaMapa.esriSatelite:
        return CapaMapa.openStreetMap;
      case CapaMapa.openStreetMap:
        return CapaMapa.googleHibrido;
    }
  }
}
