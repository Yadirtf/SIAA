import 'package:flutter/material.dart';
import 'package:siaa_web/core/theme/app_theme.dart';
import 'package:siaa_web/features/dashboard/data/admin_geo_repository.dart';
import 'package:siaa_web/features/dashboard/presentation/bloc/dashboard_state.dart';
import 'package:siaa_web/features/dashboard/presentation/widgets/cards/dashboard_stat_card.dart';
import 'package:siaa_web/features/dashboard/presentation/widgets/dialogs/admin_crear_espacio_dialog.dart';
import 'package:siaa_web/features/dashboard/presentation/widgets/dialogs/admin_eliminar_espacio_dialog.dart';

class DashboardEspaciosView extends StatelessWidget {
  final DashboardState state;
  final void Function({
    required String sedeId,
    String? bloqueId,
    required int piso,
    required String codigo,
    required String nombre,
    required int capacidad,
    required String tipo,
  }) onCrearEspacio;
  final ValueChanged<String> onEliminarEspacio;

  const DashboardEspaciosView({
    super.key,
    required this.state,
    required this.onCrearEspacio,
    required this.onEliminarEspacio,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Métricas
          Row(
            children: [
              DashboardStatCard(
                title: 'Total Espacios',
                value: '${state.espacios.length}',
                icon: Icons.meeting_room,
                color: Colors.blue,
              ),
              const SizedBox(width: 20),
              DashboardStatCard(
                title: 'Geocercos Delimitados',
                value: '${state.delimitadosCount}',
                icon: Icons.check_circle,
                color: Colors.green,
              ),
              const SizedBox(width: 20),
              DashboardStatCard(
                title: 'Pendientes de Mapeo',
                value: '${state.pendientesCount}',
                icon: Icons.pending,
                color: Colors.orange,
              ),
              const SizedBox(width: 20),
              DashboardStatCard(
                title: 'Total Sedes',
                value: '${state.sedes.length}',
                icon: Icons.apartment,
                color: Colors.purple,
              ),
            ],
          ),
          const SizedBox(height: 28),

          // Encabezado de tabla y botón nuevo
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Listado de Aulas y Espacios Físicos',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: SIAAColors.primary500,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Nuevo Espacio'),
                onPressed: () => AdminCrearEspacioDialog.mostrar(
                  context,
                  sedes: state.sedes,
                  bloques: state.bloques,
                  onConfirmar: onCrearEspacio,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Tabla de Espacios
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: state.espacios.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(40),
                    child: Center(
                      child: Text('No hay espacios registrados. Crea uno con el botón superior.'),
                    ),
                  )
                : DataTable(
                    columns: const [
                      DataColumn(label: Text('Código', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Nombre', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Tipo', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Capacidad', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Validación', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Buffer (m)', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Geometría / Polígono', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Acciones', style: TextStyle(fontWeight: FontWeight.bold))),
                    ],
                    rows: state.espacios.map((esp) => _buildDataRow(context, esp)).toList(),
                  ),
          ),
        ],
      ),
    );
  }

  DataRow _buildDataRow(BuildContext context, AdminEspacio esp) {
    return DataRow(cells: [
      DataCell(Text(esp.codigo, style: const TextStyle(fontWeight: FontWeight.w600))),
      DataCell(Text(esp.nombre)),
      DataCell(Text(esp.tipo)),
      DataCell(Text('${esp.capacidad} pers.')),
      DataCell(Text(esp.nivelValidacion)),
      DataCell(Text('${esp.bufferMetros.toStringAsFixed(0)} m')),
      DataCell(
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: esp.tieneGeometria
                ? SIAAColors.asistenciaPresente.withValues(alpha: 0.12)
                : Colors.orange.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                esp.tieneGeometria ? Icons.check_circle : Icons.warning_amber,
                size: 14,
                color: esp.tieneGeometria ? SIAAColors.asistenciaPresente : Colors.orange[800],
              ),
              const SizedBox(width: 6),
              Text(
                esp.tieneGeometria
                    ? '${esp.areaMetrosCuadrados.toStringAsFixed(1)} m²'
                    : 'Sin Polígono',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: esp.tieneGeometria ? SIAAColors.asistenciaPresente : Colors.orange[800],
                ),
              ),
            ],
          ),
        ),
      ),
      DataCell(
        IconButton(
          icon: const Icon(Icons.delete_outline, size: 18, color: Colors.redAccent),
          tooltip: 'Eliminar espacio',
          onPressed: () => AdminEliminarEspacioDialog.mostrar(
            context,
            espacio: esp,
            onConfirmar: () => onEliminarEspacio(esp.id),
          ),
        ),
      ),
    ]);
  }
}
