// Dashboard administrativo para la consola web SIAA — T-PLT-01.8, US-GEO-01
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../data/admin_geo_repository.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  static const routeName = '/dashboard';

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final AdminGeoRepository _geoRepo = AdminGeoRepository();

  int _selectedNavIndex = 0; // 0: Espacios, 1: Sedes y Bloques

  bool _loading = true;
  String? _errorMessage;

  List<AdminSede> _sedes = [];
  List<AdminBloque> _bloques = [];
  List<AdminEspacio> _espacios = [];

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final results = await Future.wait([
        _geoRepo.listarSedes(),
        _geoRepo.listarBloques(),
        _geoRepo.listarEspacios(),
      ]);

      if (mounted) {
        setState(() {
          _sedes = results[0] as List<AdminSede>;
          _bloques = results[1] as List<AdminBloque>;
          _espacios = results[2] as List<AdminEspacio>;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocListener<WebAuthBloc, WebAuthState>(
      listener: (context, state) {
        if (state is WebAuthUnauthenticated) {
          Navigator.of(context).pushReplacementNamed('/login');
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: Row(
          children: [
            // ─── Barra Lateral (Sidebar) ───────────────────────────
            _buildSidebar(theme),

            // ─── Contenido Principal ───────────────────────────────
            Expanded(
              child: Column(
                children: [
                  _buildTopBar(theme),
                  Expanded(
                    child: _loading
                        ? const Center(child: CircularProgressIndicator())
                        : _errorMessage != null
                            ? _buildErrorView()
                            : _selectedNavIndex == 0
                                ? _buildEspaciosView(theme)
                                : _buildSedesBloquesView(theme),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSidebar(ThemeData theme) {
    return Container(
      width: 260,
      decoration: const BoxDecoration(
        color: Color(0xFF0F172A), // Slate 900
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(2, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          // Branding
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: SIAAColors.primary500,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.school, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'SIAA',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                    Text(
                      'Consola Admin',
                      style: TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(color: Colors.white12, height: 1),
          const SizedBox(height: 16),

          // Items de Navegación
          _buildSidebarItem(
            index: 0,
            icon: Icons.meeting_room_outlined,
            activeIcon: Icons.meeting_room,
            label: 'Aulas y Espacios',
          ),
          _buildSidebarItem(
            index: 1,
            icon: Icons.domain_outlined,
            activeIcon: Icons.domain,
            label: 'Sedes y Bloques',
          ),

          const Spacer(),

          // Indicador de Versión y API
          Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: const [
                  Icon(Icons.cloud_done, color: Colors.greenAccent, size: 18),
                  SizedBox(width: 8),
                  Text(
                    'Backend v0.1.0 (Activo)',
                    style: TextStyle(color: Colors.white70, fontSize: 11),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarItem({
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
  }) {
    final isSelected = _selectedNavIndex == index;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Material(
        color: isSelected ? SIAAColors.primary600 : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => setState(() => _selectedNavIndex = index),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Icon(
                  isSelected ? activeIcon : icon,
                  color: isSelected ? Colors.white : Colors.white70,
                  size: 20,
                ),
                const SizedBox(width: 14),
                Text(
                  label,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.white70,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(ThemeData theme) {
    return Container(
      height: 68,
      padding: const EdgeInsets.symmetric(horizontal: 28),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Text(
                _selectedNavIndex == 0 ? 'Gestión de Espacios y Cartografía' : 'Sedes y Bloques Físicos',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
              ),
              const SizedBox(width: 16),
              IconButton(
                icon: const Icon(Icons.refresh, size: 20),
                tooltip: 'Refrescar datos',
                onPressed: _cargarDatos,
              ),
            ],
          ),
          BlocBuilder<WebAuthBloc, WebAuthState>(
            builder: (context, state) {
              String nombre = 'Administrador';
              String correo = 'admin@siaa.edu.co';
              if (state is WebAuthAuthenticated) {
                nombre = '${state.usuario.nombre} ${state.usuario.apellido}';
                correo = state.usuario.correo;
              }

              return Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: SIAAColors.primary100,
                    child: Text(
                      nombre.isNotEmpty ? nombre[0].toUpperCase() : 'A',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: SIAAColors.primary700),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(nombre, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                      Text(correo, style: const TextStyle(fontSize: 11, color: Colors.black45)),
                    ],
                  ),
                  const SizedBox(width: 20),
                  IconButton(
                    icon: const Icon(Icons.logout, size: 20, color: Colors.black54),
                    tooltip: 'Cerrar sesión',
                    onPressed: () => context.read<WebAuthBloc>().add(const WebAuthLogoutRequested()),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: SIAAColors.asistenciaAusente),
          const SizedBox(height: 12),
          Text(_errorMessage ?? 'Ocurrió un error', style: const TextStyle(fontSize: 16)),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: _cargarDatos, child: const Text('Reintentar')),
        ],
      ),
    );
  }

  // ─── VISTA 1: ESPACIOS ──────────────────────────────────────────────────────

  Widget _buildEspaciosView(ThemeData theme) {
    final delimitados = _espacios.where((e) => e.tieneGeometria).length;
    final pendientes = _espacios.length - delimitados;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Métricas
          Row(
            children: [
              _buildStatCard('Total Espacios', '${_espacios.length}', Icons.meeting_room, Colors.blue),
              const SizedBox(width: 20),
              _buildStatCard('Geocercos Delimitados', '$delimitados', Icons.check_circle, Colors.green),
              const SizedBox(width: 20),
              _buildStatCard('Pendientes de Mapeo', '$pendientes', Icons.pending, Colors.orange),
              const SizedBox(width: 20),
              _buildStatCard('Total Sedes', '${_sedes.length}', Icons.apartment, Colors.purple),
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
                onPressed: _mostrarModalCrearEspacio,
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
            child: _espacios.isEmpty
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
                    rows: _espacios.map((esp) {
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
                                  ? SIAAColors.asistenciaPresente.withOpacity(0.12)
                                  : Colors.orange.withOpacity(0.12),
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
                            onPressed: () => _confirmarEliminarEspacio(esp),
                          ),
                        ),
                      ]);
                    }).toList(),
                  ),
          ),
        ],
      ),
    );
  }

  // ─── VISTA 2: SEDES Y BLOQUES ───────────────────────────────────────────────

  Widget _buildSedesBloquesView(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Sedes Institucionales', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: SIAAColors.primary500, foregroundColor: Colors.white),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Nueva Sede'),
                onPressed: _mostrarModalCrearSede,
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
            child: _sedes.isEmpty
                ? const Padding(padding: EdgeInsets.all(32), child: Center(child: Text('No hay sedes creadas.')))
                : DataTable(
                    columns: const [
                      DataColumn(label: Text('Código', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Nombre Sede', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Dirección', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Estado', style: TextStyle(fontWeight: FontWeight.bold))),
                    ],
                    rows: _sedes.map((s) {
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Bloques de Edificios', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: SIAAColors.primary500, foregroundColor: Colors.white),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Nuevo Bloque'),
                onPressed: _mostrarModalCrearBloque,
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
            child: _bloques.isEmpty
                ? const Padding(padding: EdgeInsets.all(32), child: Center(child: Text('No hay bloques creados.')))
                : DataTable(
                    columns: const [
                      DataColumn(label: Text('Código', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Nombre Bloque', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Sede ID', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Pisos', style: TextStyle(fontWeight: FontWeight.bold))),
                    ],
                    rows: _bloques.map((b) {
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

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 12, color: Colors.black54)),
                const SizedBox(height: 4),
                Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ─── MODALES DE CREACIÓN ───────────────────────────────────────────────────

  void _mostrarModalCrearSede() {
    final codigoCtrl = TextEditingController();
    final nombreCtrl = TextEditingController();
    final direccionCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (dlgContext) => AlertDialog(
        title: const Text('Registrar Nueva Sede'),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: codigoCtrl, decoration: const InputDecoration(labelText: 'Código Sede (ej: SED-01)')),
              const SizedBox(height: 12),
              TextField(controller: nombreCtrl, decoration: const InputDecoration(labelText: 'Nombre de la Sede')),
              const SizedBox(height: 12),
              TextField(controller: direccionCtrl, decoration: const InputDecoration(labelText: 'Dirección física')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(dlgContext).pop(), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              if (codigoCtrl.text.isEmpty || nombreCtrl.text.isEmpty) return;
              try {
                await _geoRepo.crearSede(
                  codigo: codigoCtrl.text.trim(),
                  nombre: nombreCtrl.text.trim(),
                  direccion: direccionCtrl.text.trim().isEmpty ? null : direccionCtrl.text.trim(),
                );
                Navigator.of(dlgContext).pop();
                _cargarDatos();
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
              }
            },
            child: const Text('Crear Sede'),
          ),
        ],
      ),
    );
  }

  void _mostrarModalCrearBloque() {
    if (_sedes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Crea primero una sede')));
      return;
    }

    String selectedSedeId = _sedes.first.id;
    final codigoCtrl = TextEditingController();
    final nombreCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (dlgContext) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          title: const Text('Registrar Nuevo Bloque'),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: selectedSedeId,
                  decoration: const InputDecoration(labelText: 'Sede'),
                  items: _sedes.map((s) => DropdownMenuItem(value: s.id, child: Text('${s.codigo} - ${s.nombre}'))).toList(),
                  onChanged: (v) => setModalState(() => selectedSedeId = v!),
                ),
                const SizedBox(height: 12),
                TextField(controller: codigoCtrl, decoration: const InputDecoration(labelText: 'Código Bloque (ej: BLOQ-A)')),
                const SizedBox(height: 12),
                TextField(controller: nombreCtrl, decoration: const InputDecoration(labelText: 'Nombre Bloque')),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(dlgContext).pop(), child: const Text('Cancelar')),
            ElevatedButton(
              onPressed: () async {
                if (codigoCtrl.text.isEmpty || nombreCtrl.text.isEmpty) return;
                try {
                  await _geoRepo.crearBloque(
                    sedeId: selectedSedeId,
                    codigo: codigoCtrl.text.trim(),
                    nombre: nombreCtrl.text.trim(),
                    pisos: [1, 2, 3],
                  );
                  Navigator.of(dlgContext).pop();
                  _cargarDatos();
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              },
              child: const Text('Crear Bloque'),
            ),
          ],
        ),
      ),
    );
  }

  void _mostrarModalCrearEspacio() {
    if (_sedes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Crea primero una sede para registrar espacios')));
      return;
    }

    String selectedSedeId = _sedes.first.id;
    String? selectedBloqueId = _bloques.isNotEmpty ? _bloques.first.id : null;
    String selectedTipo = 'AULA';
    final codigoCtrl = TextEditingController();
    final nombreCtrl = TextEditingController();
    final capacidadCtrl = TextEditingController(text: '30');

    showDialog(
      context: context,
      builder: (dlgContext) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          title: const Text('Registrar Nuevo Espacio / Aula'),
          content: SizedBox(
            width: 440,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    value: selectedSedeId,
                    decoration: const InputDecoration(labelText: 'Sede Institucional'),
                    items: _sedes.map((s) => DropdownMenuItem(value: s.id, child: Text(s.nombre))).toList(),
                    onChanged: (v) => setModalState(() => selectedSedeId = v!),
                  ),
                  const SizedBox(height: 12),
                  if (_bloques.isNotEmpty) ...[
                    DropdownButtonFormField<String>(
                      value: selectedBloqueId,
                      decoration: const InputDecoration(labelText: 'Bloque (Opcional)'),
                      items: _bloques.map((b) => DropdownMenuItem(value: b.id, child: Text(b.nombre))).toList(),
                      onChanged: (v) => setModalState(() => selectedBloqueId = v),
                    ),
                    const SizedBox(height: 12),
                  ],
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: codigoCtrl,
                          decoration: const InputDecoration(labelText: 'Código (ej: AULA-101)'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: capacidadCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Capacidad personas'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(controller: nombreCtrl, decoration: const InputDecoration(labelText: 'Nombre del Espacio')),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: selectedTipo,
                    decoration: const InputDecoration(labelText: 'Tipo de Espacio'),
                    items: const [
                      DropdownMenuItem(value: 'AULA', child: Text('Aula Magistral')),
                      DropdownMenuItem(value: 'LABORATORIO', child: Text('Laboratorio')),
                      DropdownMenuItem(value: 'AUDITORIO', child: Text('Auditorio')),
                      DropdownMenuItem(value: 'TALLER', child: Text('Taller')),
                    ],
                    onChanged: (v) => setModalState(() => selectedTipo = v!),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(dlgContext).pop(), child: const Text('Cancelar')),
            ElevatedButton(
              onPressed: () async {
                if (codigoCtrl.text.isEmpty || nombreCtrl.text.isEmpty) return;
                try {
                  await _geoRepo.crearEspacio(
                    sedeId: selectedSedeId,
                    bloqueId: selectedBloqueId,
                    piso: 1,
                    codigo: codigoCtrl.text.trim(),
                    nombre: nombreCtrl.text.trim(),
                    capacidad: int.tryParse(capacidadCtrl.text) ?? 30,
                    tipo: selectedTipo,
                  );
                  Navigator.of(dlgContext).pop();
                  _cargarDatos();
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              },
              child: const Text('Registrar Espacio'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmarEliminarEspacio(AdminEspacio esp) {
    showDialog(
      context: context,
      builder: (dlgContext) => AlertDialog(
        title: Text('¿Eliminar espacio ${esp.codigo}?'),
        content: const Text('El espacio se marcará como inactivo (borrado lógico auditado).'),
        actions: [
          TextButton(onPressed: () => Navigator.of(dlgContext).pop(), child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.of(dlgContext).pop();
              try {
                await _geoRepo.eliminarEspacio(esp.id);
                _cargarDatos();
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
              }
            },
            child: const Text('Eliminar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
