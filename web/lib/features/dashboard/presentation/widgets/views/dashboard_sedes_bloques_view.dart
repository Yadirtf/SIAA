import 'package:flutter/material.dart';
import 'package:siaa_web/core/theme/app_theme.dart';
import 'package:siaa_web/features/dashboard/presentation/bloc/dashboard_state.dart';
import 'package:siaa_web/features/dashboard/presentation/widgets/dialogs/admin_crear_bloque_dialog.dart';
import 'package:siaa_web/features/dashboard/presentation/widgets/dialogs/admin_crear_sede_dialog.dart';

class DashboardSedesBloquesView extends StatelessWidget {
  final DashboardState state;
  final void Function({
    required String codigo,
    required String nombre,
    String? direccion,
  }) onCrearSede;
  final void Function({
    required String sedeId,
    required String codigo,
    required String nombre,
    required List<int> pisos,
  }) onCrearBloque;

  const DashboardSedesBloquesView({
    super.key,
    required this.state,
    required this.onCrearSede,
    required this.onCrearBloque,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── Sedes Institucionales ─────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Sedes Institucionales',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: SIAAColors.primary500,
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Nueva Sede'),
                onPressed: () => AdminCrearSedeDialog.mostrar(
                  context,
                  onConfirmar: onCrearSede,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: state.sedes.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(child: Text('No hay sedes creadas.')),
                  )
                : DataTable(
                    columns: const [
                      DataColumn(label: Text('Código', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Nombre Sede', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Dirección', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Estado', style: TextStyle(fontWeight: FontWeight.bold))),
                    ],
                    rows: state.sedes.map((s) {
                      return DataRow(cells: [
                        DataCell(Text(s.codigo, style: const TextStyle(fontWeight: FontWeight.bold))),
                        DataCell(Text(s.nombre)),
                        DataCell(Text(s.direccion ?? 'N/A')),
                        DataCell(Text(s.activo ? 'Activa' : 'Inactiva')),
                      ]);
                    }).toList(),
                  ),
          ),
          const SizedBox(height: 32),

          // ─── Bloques de Edificios ──────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Bloques de Edificios',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: SIAAColors.primary500,
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Nuevo Bloque'),
                onPressed: () => AdminCrearBloqueDialog.mostrar(
                  context,
                  sedes: state.sedes,
                  onConfirmar: onCrearBloque,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: state.bloques.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(child: Text('No hay bloques creados.')),
                  )
                : DataTable(
                    columns: const [
                      DataColumn(label: Text('Código', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Nombre Bloque', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Sede ID', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Pisos', style: TextStyle(fontWeight: FontWeight.bold))),
                    ],
                    rows: state.bloques.map((b) {
                      return DataRow(cells: [
                        DataCell(Text(b.codigo, style: const TextStyle(fontWeight: FontWeight.bold))),
                        DataCell(Text(b.nombre)),
                        DataCell(Text(b.sedeId)),
                        DataCell(Text(b.pisos.join(', '))),
                      ]);
                    }).toList(),
                  ),
          ),
        ],
      ),
    );
  }
}
