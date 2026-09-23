import 'package:flutter/material.dart';
import '../../data/academico_models.dart';
import '../../data/academico_repository.dart';
import '../widgets/dialogs/crear_elemento_estructura_dialog.dart';
import '../widgets/views/estructura_breadcrumbs.dart';
import '../widgets/views/estructura_header.dart';
import '../widgets/views/estructura_hierarchy_lists.dart';

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
    String? parentName;
    if (_activeLevel == 1) parentName = _selectedFacultad?.nombre;
    if (_activeLevel == 2) parentName = _selectedPrograma?.nombre;
    if (_activeLevel == 3) parentName = _selectedAsignatura?.nombre;

    await CrearElementoEstructuraDialog.mostrar(
      context,
      activeLevel: _activeLevel,
      parentName: parentName,
      onGuardar: ({required String codigo, required String nombre}) async {
        try {
          if (_activeLevel == 0) {
            await widget.repository.crearFacultad(codigo: codigo, nombre: nombre);
            _cargarFacultades();
          } else if (_activeLevel == 1 && _selectedFacultad != null) {
            await widget.repository.crearPrograma(
              codigo: codigo,
              nombre: nombre,
              facultadId: _selectedFacultad!.id,
            );
            _cargarProgramas(_selectedFacultad!.id);
          } else if (_activeLevel == 2 && _selectedPrograma != null) {
            await widget.repository.crearAsignatura(
              codigo: codigo,
              nombre: nombre,
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          EstructuraHeader(
            activeLevel: _activeLevel,
            onCrearElemento: _dialogoCrearElemento,
          ),
          const SizedBox(height: 16),
          EstructuraBreadcrumbs(
            activeLevel: _activeLevel,
            selectedFacultad: _selectedFacultad,
            selectedPrograma: _selectedPrograma,
            selectedAsignatura: _selectedAsignatura,
            onSelectLevel: (lvl) {
              setState(() {
                _activeLevel = lvl;
                if (lvl <= 2) _selectedAsignatura = null;
                if (lvl <= 1) _selectedPrograma = null;
                if (lvl == 0) _selectedFacultad = null;
              });
            },
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
                      ? EstructuraFacultadesList(
                          facultades: _facultades,
                          onSelect: (f) {
                            setState(() {
                              _selectedFacultad = f;
                              _activeLevel = 1;
                            });
                            _cargarProgramas(f.id);
                          },
                        )
                      : _activeLevel == 1
                          ? EstructuraProgramasList(
                              programas: _programas,
                              onSelect: (p) {
                                setState(() {
                                  _selectedPrograma = p;
                                  _activeLevel = 2;
                                });
                                _cargarAsignaturas(p.id);
                              },
                            )
                          : _activeLevel == 2
                              ? EstructuraAsignaturasList(
                                  asignaturas: _asignaturas,
                                  onSelect: (a) {
                                    setState(() {
                                      _selectedAsignatura = a;
                                      _activeLevel = 3;
                                    });
                                    _cargarGrupos(a.id);
                                  },
                                )
                              : EstructuraGruposList(grupos: _grupos),
            ),
          ),
        ],
      ),
    );
  }
}
