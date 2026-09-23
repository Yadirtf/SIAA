import 'package:flutter/material.dart';
import '../../data/academico_models.dart';
import '../../data/academico_repository.dart';

class EstructuraTab extends StatefulWidget {
  final AcademicoRepository repository;

  const EstructuraTab({super.key, required this.repository});

  @override
  State<EstructuraTab> createState() => _EstructuraTabState();
}

class _EstructuraTabState extends State<EstructuraTab> {
  int _activeLevel = 0; // 0: Facultades, 1: Programas, 2: Asignaturas, 3: Grupos

  bool _loading = true;
  String? _error;

  List<FacultadModel> _facultades = [];
  List<ProgramaModel> _programas = [];
  List<AsignaturaModel> _asignaturas = [];
  List<GrupoModel> _grupos = [];

  FacultadModel? _selectedFacultad;
  ProgramaModel? _selectedPrograma;
  AsignaturaModel? _selectedAsignatura;

  @override
  void initState() {
    super.initState();
    _cargarFacultades();
  }

  Future<void> _cargarFacultades() async {
    setState(() => _loading = true);
    try {
      final list = await widget.repository.listarFacultades();
      if (mounted) {
        setState(() {
          _facultades = list;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  Future<void> _cargarProgramas(String facultadId) async {
    setState(() => _loading = true);
    try {
      final list = await widget.repository.listarProgramas(facultadId: facultadId);
      if (mounted) {
        setState(() {
          _programas = list;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _cargarAsignaturas(String programaId) async {
    setState(() => _loading = true);
    try {
      final list = await widget.repository.listarAsignaturas(programaId: programaId);
      if (mounted) {
        setState(() {
          _asignaturas = list;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _cargarGrupos(String asignaturaId) async {
    setState(() => _loading = true);
    try {
      final list = await widget.repository.listarGrupos(asignaturaId: asignaturaId);
      if (mounted) {
        setState(() {
          _grupos = list;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _dialogoCrearElemento() async {
    final codigoCtrl = TextEditingController();
    final nombreCtrl = TextEditingController();

    String titulo = 'Nueva Facultad';
    if (_activeLevel == 1) titulo = 'Nuevo Programa para ${_selectedFacultad?.nombre}';
    if (_activeLevel == 2) titulo = 'Nueva Asignatura para ${_selectedPrograma?.nombre}';
    if (_activeLevel == 3) titulo = 'Nuevo Grupo para ${_selectedAsignatura?.nombre}';

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(titulo),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: codigoCtrl,
                decoration: InputDecoration(
                  labelText: _activeLevel == 3 ? 'Número de Grupo (ej. G01)*' : 'Código*',
                  border: const OutlineInputBorder(),
                ),
              ),
              if (_activeLevel != 3) ...[
                const SizedBox(height: 12),
                TextField(
                  controller: nombreCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Nombre*',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () async {
              if (codigoCtrl.text.trim().isEmpty) return;
              Navigator.of(ctx).pop();
              try {
                if (_activeLevel == 0) {
                  await widget.repository.crearFacultad(
                    codigo: codigoCtrl.text.trim(),
                    nombre: nombreCtrl.text.trim(),
                  );
                  _cargarFacultades();
                } else if (_activeLevel == 1 && _selectedFacultad != null) {
                  await widget.repository.crearPrograma(
                    codigo: codigoCtrl.text.trim(),
                    nombre: nombreCtrl.text.trim(),
                    facultadId: _selectedFacultad!.id,
                  );
                  _cargarProgramas(_selectedFacultad!.id);
                } else if (_activeLevel == 2 && _selectedPrograma != null) {
                  await widget.repository.crearAsignatura(
                    codigo: codigoCtrl.text.trim(),
                    nombre: nombreCtrl.text.trim(),
                    programaId: _selectedPrograma!.id,
                  );
                  _cargarAsignaturas(_selectedPrograma!.id);
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
                  );
                }
              }
            },
            child: const Text('Crear'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Estructura Académica (US-ACA-01 AC-04)',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Jerarquía institucional: Facultad → Programa → Asignatura → Grupos',
                    style: TextStyle(color: Colors.black54),
                  ),
                ],
              ),
              FilledButton.icon(
                onPressed: _dialogoCrearElemento,
                icon: const Icon(Icons.add),
                label: Text(_activeLevel == 0
                    ? 'Nueva Facultad'
                    : _activeLevel == 1
                        ? 'Nuevo Programa'
                        : _activeLevel == 2
                            ? 'Nueva Asignatura'
                            : 'Nuevo Grupo'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Breadcrumbs de navegación
          Wrap(
            spacing: 8,
            children: [
              ChoiceChip(
                label: const Text('1. Facultades'),
                selected: _activeLevel == 0,
                onSelected: (_) => setState(() {
                  _activeLevel = 0;
                  _selectedFacultad = null;
                  _selectedPrograma = null;
                  _selectedAsignatura = null;
                }),
              ),
              if (_selectedFacultad != null) ...[
                const Icon(Icons.chevron_right, size: 20, color: Colors.grey),
                ChoiceChip(
                  label: Text('2. ${_selectedFacultad!.nombre}'),
                  selected: _activeLevel == 1,
                  onSelected: (_) => setState(() {
                    _activeLevel = 1;
                    _selectedPrograma = null;
                    _selectedAsignatura = null;
                  }),
                ),
              ],
              if (_selectedPrograma != null) ...[
                const Icon(Icons.chevron_right, size: 20, color: Colors.grey),
                ChoiceChip(
                  label: Text('3. ${_selectedPrograma!.nombre}'),
                  selected: _activeLevel == 2,
                  onSelected: (_) => setState(() {
                    _activeLevel = 2;
                    _selectedAsignatura = null;
                  }),
                ),
              ],
              if (_selectedAsignatura != null) ...[
                const Icon(Icons.chevron_right, size: 20, color: Colors.grey),
                ChoiceChip(
                  label: Text('4. ${_selectedAsignatura!.nombre}'),
                  selected: _activeLevel == 3,
                  onSelected: (_) => setState(() => _activeLevel = 3),
                ),
              ],
            ],
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFFECACA)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: Color(0xFFDC2626)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _error!,
                      style: const TextStyle(color: Color(0xFFDC2626)),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 16, color: Color(0xFFDC2626)),
                    onPressed: () => setState(() => _error = null),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          Expanded(
            child: Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.grey.shade200),
              ),
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _activeLevel == 0
                      ? _buildFacultadesList()
                      : _activeLevel == 1
                          ? _buildProgramasList()
                          : _activeLevel == 2
                              ? _buildAsignaturasList()
                              : _buildGruposList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFacultadesList() {
    if (_facultades.isEmpty) {
      return const Center(child: Text('No hay facultades registradas.'));
    }
    return ListView.separated(
      itemCount: _facultades.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (ctx, i) {
        final f = _facultades[i];
        return ListTile(
          leading: const CircleAvatar(
            backgroundColor: Color(0xFFEFF6FF),
            child: Icon(Icons.account_balance, color: Color(0xFF2563EB)),
          ),
          title: Text('${f.codigo} — ${f.nombre}',
              style: const TextStyle(fontWeight: FontWeight.bold)),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            setState(() {
              _selectedFacultad = f;
              _activeLevel = 1;
            });
            _cargarProgramas(f.id);
          },
        );
      },
    );
  }

  Widget _buildProgramasList() {
    if (_programas.isEmpty) {
      return const Center(
          child: Text('No hay programas registrados para esta facultad.'));
    }
    return ListView.separated(
      itemCount: _programas.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (ctx, i) {
        final p = _programas[i];
        return ListTile(
          leading: const CircleAvatar(
            backgroundColor: Color(0xFFF5F3FF),
            child: Icon(Icons.school, color: Color(0xFF7C3AED)),
          ),
          title: Text('${p.codigo} — ${p.nombre}',
              style: const TextStyle(fontWeight: FontWeight.bold)),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            setState(() {
              _selectedPrograma = p;
              _activeLevel = 2;
            });
            _cargarAsignaturas(p.id);
          },
        );
      },
    );
  }

  Widget _buildAsignaturasList() {
    if (_asignaturas.isEmpty) {
      return const Center(
          child: Text('No hay asignaturas registradas para este programa.'));
    }
    return ListView.separated(
      itemCount: _asignaturas.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (ctx, i) {
        final a = _asignaturas[i];
        return ListTile(
          leading: const CircleAvatar(
            backgroundColor: Color(0xFFECFDF5),
            child: Icon(Icons.menu_book, color: Color(0xFF059669)),
          ),
          title: Text('${a.codigo} — ${a.nombre}',
              style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text('${a.creditos} Créditos académicos'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            setState(() {
              _selectedAsignatura = a;
              _activeLevel = 3;
            });
            _cargarGrupos(a.id);
          },
        );
      },
    );
  }

  Widget _buildGruposList() {
    if (_grupos.isEmpty) {
      return const Center(
          child: Text('No hay grupos registrados para esta asignatura.'));
    }
    return ListView.separated(
      itemCount: _grupos.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (ctx, i) {
        final g = _grupos[i];
        return ListTile(
          leading: const CircleAvatar(
            backgroundColor: Color(0xFFFFFBEB),
            child: Icon(Icons.groups, color: Color(0xFFD97706)),
          ),
          title: Text('Grupo ${g.numero}',
              style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text('Cupo: ${g.cupo} estudiantes'),
        );
      },
    );
  }
}
