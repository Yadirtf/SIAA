// marcajes_filter_bar.dart — Barra de filtros administrativos y búsqueda avanzada con selectores dinámicos (US-MAR-09)
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/datasources/marcajes_admin_remote_datasource.dart';
import '../../domain/models/marcaje_admin_model.dart';
import '../../domain/models/sesion_summary_model.dart';
import '../../domain/models/usuario_summary_model.dart';
import 'buscador_entidad_field.dart';

class MarcajesFilterBar extends StatefulWidget {
  final ValueChanged<FiltrosMarcajeAdmin> onFiltrar;
  final VoidCallback onNuevoManual;

  const MarcajesFilterBar({
    super.key,
    required this.onFiltrar,
    required this.onNuevoManual,
  });

  @override
  State<MarcajesFilterBar> createState() => _MarcajesFilterBarState();
}

class _MarcajesFilterBarState extends State<MarcajesFilterBar> {
  final _datasource = MarcajesAdminRemoteDataSource();
  List<UsuarioSummaryModel> _usuarios = [];
  List<SesionSummaryModel> _sesiones = [];

  String? _usuarioId;
  String? _sesionId;
  String? _resultado;
  String? _tipo;
  String? _origen;

  @override
  void initState() {
    super.initState();
    _cargarOpciones();
  }

  Future<void> _cargarOpciones() async {
    final resUsuarios = await _datasource.obtenerUsuarios();
    final resSesiones = await _datasource.obtenerSesiones();
    if (mounted) {
      setState(() {
        _usuarios = resUsuarios;
        _sesiones = resSesiones;
      });
    }
  }

  void _aplicarFiltros() {
    widget.onFiltrar(
      FiltrosMarcajeAdmin(
        usuarioId: _usuarioId,
        sesionId: _sesionId,
        resultado: _resultado,
        tipo: _tipo,
        origen: _origen,
      ),
    );
  }

  void _limpiarFiltros() {
    setState(() {
      _usuarioId = null;
      _sesionId = null;
      _resultado = null;
      _tipo = null;
      _origen = null;
    });
    _aplicarFiltros();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Wrap(
          spacing: 12,
          runSpacing: 12,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            SizedBox(
              width: 250,
              child: BuscadorEntidadField<UsuarioSummaryModel>(
                label: 'Usuario',
                hint: 'Buscar por nombre o correo...',
                icon: Icons.person_search_outlined,
                items: _usuarios,
                labelExtractor: (u) => u.etiquetaSelector,
                idExtractor: (u) => u.id,
                filter: (u, q) =>
                    u.nombreCompleto.toLowerCase().contains(q.toLowerCase()) ||
                    u.correo.toLowerCase().contains(q.toLowerCase()),
                onSelected: (id) => _usuarioId = id,
              ),
            ),
            SizedBox(
              width: 230,
              child: BuscadorEntidadField<SesionSummaryModel>(
                label: 'Sesión',
                hint: 'Buscar por fecha o estado...',
                icon: Icons.calendar_month_outlined,
                items: _sesiones,
                labelExtractor: (s) => s.etiquetaSelector,
                idExtractor: (s) => s.id,
                filter: (s, q) => s.etiquetaSelector.toLowerCase().contains(q.toLowerCase()),
                onSelected: (id) => _sesionId = id,
              ),
            ),
            SizedBox(
              width: 160,
              child: DropdownButtonFormField<String>(
                value: _resultado,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Resultado',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                items: const [
                  DropdownMenuItem(value: null, child: Text('Todos')),
                  DropdownMenuItem(value: 'ACEPTADO', child: Text('Aceptado')),
                  DropdownMenuItem(value: 'RECHAZADO', child: Text('Rechazado')),
                  DropdownMenuItem(value: 'AUSENCIA_AUTOMATICA', child: Text('Ausencia')),
                ],
                onChanged: (val) => setState(() => _resultado = val),
              ),
            ),
            SizedBox(
              width: 140,
              child: DropdownButtonFormField<String>(
                value: _tipo,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Tipo',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                items: const [
                  DropdownMenuItem(value: null, child: Text('Todos')),
                  DropdownMenuItem(value: 'ENTRADA', child: Text('Entrada')),
                  DropdownMenuItem(value: 'SALIDA', child: Text('Salida')),
                ],
                onChanged: (val) => setState(() => _tipo = val),
              ),
            ),
            SizedBox(
              width: 160,
              child: DropdownButtonFormField<String>(
                value: _origen,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Origen',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                items: const [
                  DropdownMenuItem(value: null, child: Text('Todos')),
                  DropdownMenuItem(value: 'MOVIL_ONLINE', child: Text('Móvil Online')),
                  DropdownMenuItem(value: 'MOVIL_OFFLINE', child: Text('Móvil Offline')),
                  DropdownMenuItem(value: 'MANUAL_DOCENTE', child: Text('Manual Docente')),
                  DropdownMenuItem(value: 'SISTEMA_AUTOMATICO', child: Text('Sistema')),
                ],
                onChanged: (val) => setState(() => _origen = val),
              ),
            ),
            ElevatedButton.icon(
              onPressed: _aplicarFiltros,
              icon: const Icon(Icons.search, size: 18),
              label: const Text('Filtrar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
            OutlinedButton.icon(
              onPressed: _limpiarFiltros,
              icon: const Icon(Icons.clear_all, size: 18),
              label: const Text('Limpiar'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              onPressed: widget.onNuevoManual,
              icon: const Icon(Icons.add_task_rounded, size: 18),
              label: const Text('Marcaje Manual'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal.shade700,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
