import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../geo_editor/data/espacio_repository.dart';
import '../../../geo_editor/presentation/bloc/geo_editor_bloc.dart';
import '../../../geo_editor/presentation/screens/geo_editor_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  static const routeName = '/home';

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final EspacioRepository _espacioRepo = EspacioRepository();

  List<SedeModel> _sedes = [];
  SedeModel? _sedeSeleccionada;
  bool _cargandoSedes = false;

  List<BloqueModel> _bloques = [];
  BloqueModel? _bloqueSeleccionado;
  bool _cargandoBloques = false;

  List<EspacioModel> _espacios = [];
  bool _cargandoEspacios = false;

  @override
  void initState() {
    super.initState();
    _cargarSedes();
  }

  Future<void> _cargarSedes() async {
    setState(() => _cargandoSedes = true);
    try {
      final list = await _espacioRepo.obtenerSedes();
      if (mounted) {
        setState(() {
          _sedes = list;
          _cargandoSedes = false;
          if (_sedes.isNotEmpty) {
            _sedeSeleccionada = _sedes.first;
            _cargarBloques(_sedeSeleccionada!.id);
          } else {
            _sedeSeleccionada = null;
            _bloques = [];
            _bloqueSeleccionado = null;
            _espacios = [];
          }
        });
      }
    } catch (_) {
      if (mounted) setState(() => _cargandoSedes = false);
    }
  }

  Future<void> _cargarBloques(String sedeId) async {
    setState(() => _cargandoBloques = true);
    try {
      final list = await _espacioRepo.obtenerBloques(sedeId: sedeId);
      if (mounted) {
        setState(() {
          _bloques = list;
          _cargandoBloques = false;
          if (_bloques.isNotEmpty) {
            _bloqueSeleccionado = _bloques.first;
            _cargarEspacios(sedeId, _bloqueSeleccionado!.id);
          } else {
            _bloqueSeleccionado = null;
            _espacios = [];
          }
        });
      }
    } catch (_) {
      if (mounted) setState(() => _cargandoBloques = false);
    }
  }

  Future<void> _cargarEspacios(String sedeId, String? bloqueId) async {
    setState(() => _cargandoEspacios = true);
    try {
      final list = await _espacioRepo.obtenerEspacios(sedeId: sedeId, bloqueId: bloqueId);
      if (mounted) {
        setState(() {
          _espacios = list;
          _cargandoEspacios = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _cargandoEspacios = false);
    }
  }

  void _abrirGeoEditorParaEspacio(EspacioModel espacio) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BlocProvider<GeoEditorBloc>(
          create: (_) => GeoEditorBloc(
            onSaveGeometry: ({
              required String espacioId,
              required List<List<double>> coordenadas,
              required String metodoCaptura,
              double? precisionPromedioMetros,
              bool confirmarSolapamiento = false,
              String? motivoSolapamiento,
            }) async {
              await _espacioRepo.guardarGeometria(
                espacioId: espacioId,
                coordenadas: coordenadas,
                metodoCaptura: metodoCaptura,
                precisionPromedioMetros: precisionPromedioMetros,
                confirmarSolapamiento: confirmarSolapamiento,
                motivoSolapamiento: motivoSolapamiento,
              );
            },
            onFetchHistorial: (id) => _espacioRepo.obtenerVersionesGeometria(id),
          ),
          child: GeoEditorScreen(
            espacioId: espacio.id,
            espacioCodigo: espacio.codigo,
            espacioNombre: espacio.nombre,
            coordenadasExistentes: espacio.coordenadas,
          ),
        ),
      ),
    ).then((_) {
      if (_sedeSeleccionada != null) {
        _cargarEspacios(_sedeSeleccionada!.id, _bloqueSeleccionado?.id);
      }
    });
  }

  Future<void> _dialogoCrearSede() async {
    final codCtrl = TextEditingController(text: 'SEDE-01');
    final nomCtrl = TextEditingController(text: 'Campus Principal');
    final dirCtrl = TextEditingController(text: 'Calle Universitaria #1');

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Registrar Nueva Sede'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: codCtrl, decoration: const InputDecoration(labelText: 'Código de Sede (ej: SEDE-01)')),
            const SizedBox(height: 8),
            TextField(controller: nomCtrl, decoration: const InputDecoration(labelText: 'Nombre de la Sede')),
            const SizedBox(height: 8),
            TextField(controller: dirCtrl, decoration: const InputDecoration(labelText: 'Dirección (opcional)')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () async {
              if (codCtrl.text.trim().isEmpty || nomCtrl.text.trim().isEmpty) return;
              Navigator.of(ctx).pop();
              try {
                final nueva = await _espacioRepo.crearSede(
                  codigo: codCtrl.text.trim(),
                  nombre: nomCtrl.text.trim(),
                  direccion: dirCtrl.text.trim(),
                );
                await _cargarSedes();
                setState(() => _sedeSeleccionada = nueva);
                await _cargarBloques(nueva.id);
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error al crear sede: $e'), backgroundColor: SIAAColors.asistenciaAusente),
                  );
                }
              }
            },
            child: const Text('Guardar Sede'),
          ),
        ],
      ),
    );
  }

  Future<void> _dialogoCrearBloque() async {
    if (_sedeSeleccionada == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Primero debe registrar o seleccionar una Sede.')),
      );
      return;
    }

    final codCtrl = TextEditingController(text: 'BLQ-A');
    final nomCtrl = TextEditingController(text: 'Bloque A — Ciencias e Ingenierías');

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Nuevo Bloque en ${_sedeSeleccionada!.nombre}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: codCtrl, decoration: const InputDecoration(labelText: 'Código de Bloque (ej: BLQ-A)')),
            const SizedBox(height: 8),
            TextField(controller: nomCtrl, decoration: const InputDecoration(labelText: 'Nombre del Bloque')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () async {
              if (codCtrl.text.trim().isEmpty || nomCtrl.text.trim().isEmpty) return;
              Navigator.of(ctx).pop();
              try {
                final nuevo = await _espacioRepo.crearBloque(
                  sedeId: _sedeSeleccionada!.id,
                  codigo: codCtrl.text.trim(),
                  nombre: nomCtrl.text.trim(),
                  pisos: [1, 2, 3, 4],
                );
                await _cargarBloques(_sedeSeleccionada!.id);
                setState(() => _bloqueSeleccionado = nuevo);
                await _cargarEspacios(_sedeSeleccionada!.id, nuevo.id);
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error al crear bloque: $e'), backgroundColor: SIAAColors.asistenciaAusente),
                  );
                }
              }
            },
            child: const Text('Guardar Bloque'),
          ),
        ],
      ),
    );
  }

  Future<void> _dialogoCrearAula() async {
    if (_sedeSeleccionada == null || _bloqueSeleccionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Seleccione una Sede y un Bloque antes de crear un aula.')),
      );
      return;
    }

    final codCtrl = TextEditingController(text: 'AULA-101');
    final nomCtrl = TextEditingController(text: 'Aula Magistral 101');
    final capCtrl = TextEditingController(text: '35');
    int pisoSeleccionado = 1;
    String tipoSeleccionado = 'AULA';

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) => AlertDialog(
          title: Text('Nueva Aula en ${_bloqueSeleccionado!.nombre}'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: codCtrl, decoration: const InputDecoration(labelText: 'Código Aula (ej: A-101)')),
                const SizedBox(height: 8),
                TextField(controller: nomCtrl, decoration: const InputDecoration(labelText: 'Nombre del Espacio')),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        value: pisoSeleccionado,
                        decoration: const InputDecoration(labelText: 'Piso'),
                        items: _bloqueSeleccionado!.pisos
                            .map((p) => DropdownMenuItem(value: p, child: Text('Piso $p')))
                            .toList(),
                        onChanged: (p) => setDlgState(() => pisoSeleccionado = p ?? 1),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: capCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Capacidad'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: tipoSeleccionado,
                  decoration: const InputDecoration(labelText: 'Tipo de Espacio'),
                  items: const [
                    DropdownMenuItem(value: 'AULA', child: Text('Aula Magistral')),
                    DropdownMenuItem(value: 'LABORATORIO', child: Text('Laboratorio')),
                    DropdownMenuItem(value: 'AUDITORIO', child: Text('Auditorio')),
                    DropdownMenuItem(value: 'TALLER', child: Text('Taller')),
                    DropdownMenuItem(value: 'OFICINA', child: Text('Oficina / Sala')),
                  ],
                  onChanged: (t) => setDlgState(() => tipoSeleccionado = t ?? 'AULA'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancelar')),
            FilledButton(
              onPressed: () async {
                if (codCtrl.text.trim().isEmpty || nomCtrl.text.trim().isEmpty) return;
                Navigator.of(ctx).pop();
                try {
                  final cap = int.tryParse(capCtrl.text.trim()) ?? 30;
                  final nuevoEspacio = await _espacioRepo.crearEspacio(
                    sedeId: _sedeSeleccionada!.id,
                    bloqueId: _bloqueSeleccionado!.id,
                    piso: pisoSeleccionado,
                    codigo: codCtrl.text.trim(),
                    nombre: nomCtrl.text.trim(),
                    capacidad: cap,
                    tipo: tipoSeleccionado,
                  );
                  await _cargarEspacios(_sedeSeleccionada!.id, _bloqueSeleccionado!.id);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Aula "${nuevoEspacio.nombre}" creada con éxito en la base de datos.'),
                        backgroundColor: SIAAColors.asistenciaPresente,
                      ),
                    );
                    _abrirGeoEditorParaEspacio(nuevoEspacio);
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error al crear aula: $e'), backgroundColor: SIAAColors.asistenciaAusente),
                    );
                  }
                }
              },
              child: const Text('Crear y Mapear'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthUnauthenticated) {
          Navigator.of(context).pushReplacementNamed('/login');
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: SIAAColors.primary500,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.school, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 10),
              const Text('SIAA Móvil', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout_rounded),
              tooltip: 'Cerrar sesión',
              onPressed: () => _confirmarCerrarSesion(context),
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(SIAASpacing.lg),
          child: BlocBuilder<AuthBloc, AuthState>(
            builder: (context, authState) {
              String nombreUsuario = 'Usuario Institucional';
              List<String> roles = ['Docente'];

              if (authState is AuthAuthenticated) {
                nombreUsuario = authState.nombre;
                roles = authState.roles.isNotEmpty ? authState.roles : ['Docente'];
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ─── Tarjeta de Bienvenida y Perfil ─────────────────
                  _buildUserCard(nombreUsuario, roles, isDark),
                  const SizedBox(height: SIAASpacing.lg),

                  // ─── Módulo Principal: Levantamiento Cartográfico ───
                  _buildCartografiaCard(context, isDark),
                  const SizedBox(height: SIAASpacing.lg),

                  // ─── Módulos Operativos Secundarios ─────────────────
                  _buildModulosSecundarios(isDark),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildUserCard(String nombre, List<String> roles, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(SIAASpacing.lg),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: SIAAColors.primary500.withOpacity(0.15),
            child: Text(
              nombre.isNotEmpty ? nombre[0].toUpperCase() : 'U',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: SIAAColors.primary600,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nombre,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 6,
                  children: roles.map((r) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: SIAAColors.primary50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        r,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: SIAAColors.primary700,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartografiaCard(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(SIAASpacing.lg),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: SIAAColors.primary200),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: SIAAColors.primary500,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.account_tree_rounded, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Jerarquía Física y Cartografía',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Sede → Bloque → Aula → Polígono GPS (RF-GEO-001)',
                      style: TextStyle(fontSize: 12, color: SIAAColors.neutral500),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ─── 1. Selector de Sede ──────────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: _cargandoSedes
                    ? const LinearProgressIndicator()
                    : DropdownButtonFormField<SedeModel>(
                        value: _sedeSeleccionada,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: '1. Sede Universitaria',
                          prefixIcon: Icon(Icons.apartment_rounded),
                          isDense: true,
                        ),
                        hint: const Text('Seleccionar o crear sede'),
                        items: _sedes.map((s) {
                          return DropdownMenuItem(value: s, child: Text('${s.codigo} — ${s.nombre}'));
                        }).toList(),
                        onChanged: (nueva) {
                          if (nueva != null) {
                            setState(() => _sedeSeleccionada = nueva);
                            _cargarBloques(nueva.id);
                          }
                        },
                      ),
              ),
              const SizedBox(width: 8),
              IconButton.filledTonal(
                icon: const Icon(Icons.add_business_rounded),
                tooltip: 'Nueva Sede',
                onPressed: _dialogoCrearSede,
              ),
            ],
          ),
          const SizedBox(height: 12),

          // ─── 2. Selector de Bloque ────────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: _cargandoBloques
                    ? const LinearProgressIndicator()
                    : DropdownButtonFormField<BloqueModel>(
                        value: _bloqueSeleccionado,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: '2. Bloque o Edificio',
                          prefixIcon: Icon(Icons.domain_rounded),
                          isDense: true,
                        ),
                        hint: Text(_sedeSeleccionada == null
                            ? 'Seleccione una sede primero'
                            : (_bloques.isEmpty ? 'Sin bloques en esta sede' : 'Seleccionar bloque')),
                        items: _bloques.map((b) {
                          return DropdownMenuItem(value: b, child: Text('${b.codigo} — ${b.nombre}'));
                        }).toList(),
                        onChanged: _sedeSeleccionada == null
                            ? null
                            : (nuevo) {
                                if (nuevo != null) {
                                  setState(() => _bloqueSeleccionado = nuevo);
                                  _cargarEspacios(_sedeSeleccionada!.id, nuevo.id);
                                }
                              },
                      ),
              ),
              const SizedBox(width: 8),
              IconButton.filledTonal(
                icon: const Icon(Icons.add_home_work_rounded),
                tooltip: 'Nuevo Bloque',
                onPressed: _sedeSeleccionada != null ? _dialogoCrearBloque : null,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ─── 3. Cabecera de Aulas en el Bloque ─────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '3. Aulas / Espacios (${_espacios.length})',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  backgroundColor: SIAAColors.primary600,
                ),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Crear Aula'),
                onPressed: _bloqueSeleccionado != null ? _dialogoCrearAula : null,
              ),
            ],
          ),
          const SizedBox(height: 8),

          // ─── 4. Lista de Aulas del Bloque ─────────────────────────────────
          if (_cargandoEspacios)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_bloqueSeleccionado == null)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Seleccione o cree una Sede y un Bloque para gestionar sus aulas y delimitar sus perímetros.',
                style: TextStyle(fontSize: 12, color: SIAAColors.neutral600),
              ),
            )
          else if (_espacios.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: SIAAColors.neutral200),
              ),
              child: Column(
                children: [
                  const Icon(Icons.meeting_room_outlined, size: 32, color: SIAAColors.neutral400),
                  const SizedBox(height: 6),
                  Text(
                    'No hay aulas en ${_bloqueSeleccionado!.nombre}',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Presiona "+ Crear Aula" para registrar un salón y delimitar su polígono GPS.',
                    style: TextStyle(fontSize: 11, color: SIAAColors.neutral500),
                  ),
                ],
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _espacios.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, idx) {
                final esp = _espacios[idx];
                final tieneGeo = esp.tieneGeometria;

                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: SIAAColors.neutral200),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: tieneGeo ? SIAAColors.primary50 : Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.meeting_room_rounded,
                          color: tieneGeo ? SIAAColors.primary600 : Colors.orange.shade800,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  esp.codigo,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: tieneGeo
                                        ? SIAAColors.asistenciaPresente.withOpacity(0.15)
                                        : Colors.orange.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    tieneGeo
                                        ? 'Delimitada (${esp.areaMetrosCuadrados.toStringAsFixed(1)} m²)'
                                        : 'Sin Polígono',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: tieneGeo ? SIAAColors.asistenciaPresente : Colors.orange.shade800,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              esp.nombre,
                              style: const TextStyle(fontSize: 12, color: SIAAColors.neutral700),
                            ),
                            Text(
                              'Piso ${esp.piso ?? 1} · Capacidad: ${esp.capacidad} est. · Tipo: ${esp.tipo}',
                              style: const TextStyle(fontSize: 10, color: SIAAColors.neutral500),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      FilledButton.tonal(
                        style: FilledButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                        ),
                        onPressed: () => _abrirGeoEditorParaEspacio(esp),
                        child: Text(
                          tieneGeo ? 'Editar Polígono' : 'Trazar GPS',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildModulosSecundarios(bool isDark) {
    return Column(
      children: [
        _buildFeatureTile(
          icon: Icons.qr_code_scanner_rounded,
          title: 'Marcaje de Asistencia',
          subtitle: 'Validación por geocerca y token de sesión (Próximamente)',
          enabled: false,
          isDark: isDark,
        ),
        const SizedBox(height: 10),
        _buildFeatureTile(
          icon: Icons.history_rounded,
          title: 'Historial de Asistencia',
          subtitle: 'Registros y justificaciones de clase',
          enabled: false,
          isDark: isDark,
        ),
      ],
    );
  }

  Widget _buildFeatureTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool enabled,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: SIAAColors.neutral200),
      ),
      child: Row(
        children: [
          Icon(icon, color: enabled ? SIAAColors.primary500 : SIAAColors.neutral400, size: 28),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: enabled ? null : SIAAColors.neutral500,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 11, color: SIAAColors.neutral400),
                ),
              ],
            ),
          ),
          if (!enabled)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: SIAAColors.neutral100,
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text('Pronto', style: TextStyle(fontSize: 10, color: SIAAColors.neutral600)),
            ),
        ],
      ),
    );
  }

  void _confirmarCerrarSesion(BuildContext context) {
    showDialog(
      context: context,
      builder: (dlgContext) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: const Text('¿Está seguro de que desea salir del sistema SIAA?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dlgContext).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: SIAAColors.asistenciaAusente),
            onPressed: () {
              Navigator.of(dlgContext).pop();
              context.read<AuthBloc>().add(AuthLogoutRequested());
            },
            child: const Text('Salir', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
