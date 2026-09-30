import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/models/opcion_catalogo.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/busqueda_texto.dart';
import '../../../../core/widgets/selector_busqueda.dart';
import '../../data/opciones_ambito_datasource.dart';

/// Selector de nivel jerárquico para el visualizador de parámetros efectivos.
/// US-PAR-02: permite elegir el ámbito y ver qué valor prevalece para cada clave.
/// El elemento del nivel (sede, facultad, bloque o aula) se busca por nombre.
class AmbitoSelector extends StatefulWidget {
  final void Function(AmbitoSeleccion seleccion) onChanged;
  final AmbitoSeleccion seleccionActual;

  /// Catálogos por nivel; por defecto el registrado en el árbol.
  final FuenteOpcionesAmbito? fuente;

  const AmbitoSelector({
    super.key,
    required this.onChanged,
    required this.seleccionActual,
    this.fuente,
  });

  @override
  State<AmbitoSelector> createState() => _AmbitoSelectorState();
}

class _AmbitoSelectorState extends State<AmbitoSelector> {
  late String _nivel;
  String? _nivelId;
  final _cargas = <String, Future<List<OpcionCatalogo>>>{};

  final _niveles = const [
    ('GLOBAL', 'Global (sistema)'),
    ('SEDE', 'Sede'),
    ('FACULTAD', 'Facultad'),
    ('BLOQUE', 'Bloque'),
    ('AULA', 'Aula'),
  ];

  @override
  void initState() {
    super.initState();
    _nivel = widget.seleccionActual.nivel;
    final id = widget.seleccionActual.nivelId;
    _nivelId = id.isEmpty ? null : id;
  }

  bool get _needsId => _nivel != 'GLOBAL';

  /// Opciones del nivel, cargadas una vez (se reintenta si fallan).
  Future<List<OpcionCatalogo>> _opciones(String nivel) {
    return _cargas.putIfAbsent(nivel, () {
      final fuente = widget.fuente ?? context.read<FuenteOpcionesAmbito>();
      return fuente.opciones(nivel).catchError((Object e) {
        _cargas.remove(nivel);
        throw e;
      });
    });
  }

  void _emit() {
    if (_needsId && _nivelId == null) return;
    widget.onChanged(
      AmbitoSeleccion(nivel: _nivel, nivelId: _needsId ? _nivelId! : ''),
    );
  }

  @override
  Widget build(BuildContext context) {
    final nivelNombre = _niveles.firstWhere((n) => n.$1 == _nivel).$2;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          // Selector de nivel
          Expanded(
            flex: 2,
            child: DropdownButtonFormField<String>(
              value: _nivel,
              decoration: InputDecoration(
                labelText: 'Nivel jerárquico',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                isDense: true,
              ),
              items: _niveles
                  .map(
                    (n) => DropdownMenuItem(
                      value: n.$1,
                      child: Text(n.$2, style: const TextStyle(fontSize: 13)),
                    ),
                  )
                  .toList(),
              onChanged: (v) {
                setState(() {
                  _nivel = v ?? 'GLOBAL';
                  _nivelId = null;
                });
              },
            ),
          ),
          const SizedBox(width: 12),

          // Elemento concreto del nivel (cuando no es GLOBAL)
          Expanded(
            flex: 3,
            child: AnimatedOpacity(
              opacity: _needsId ? 1 : 0.35,
              duration: const Duration(milliseconds: 200),
              child: SelectorBusqueda<OpcionCatalogo>(
                key: ValueKey('ambito-$_nivel'),
                etiqueta: _needsId ? nivelNombre : 'No aplica (Global)',
                ayuda: 'Código o nombre',
                icono: Icons.account_tree_outlined,
                denso: true,
                habilitado: _needsId,
                idInicial: _nivelId,
                espera: const Duration(milliseconds: 150),
                buscar: (q) async => filtrarPorTexto(
                  await _opciones(_nivel),
                  (o) => o.textoBusqueda,
                  q,
                ),
                resolver: (id) async {
                  final lista = await _opciones(_nivel);
                  final hallado = lista.where((o) => o.id == id);
                  return hallado.isEmpty ? null : hallado.first;
                },
                textoDe: (o) => o.etiqueta,
                detalleDe: (o) => o.detalle,
                idDe: (o) => o.id,
                onCambio: (o) {
                  setState(() => _nivelId = o?.id);
                  if (o != null) _emit();
                },
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Botón resolver
          FilledButton.icon(
            onPressed: _needsId && _nivelId == null ? null : _emit,
            icon: const Icon(Icons.auto_fix_high_rounded, size: 16),
            label: const Text('Resolver'),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primaryAccent,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              textStyle: const TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

/// Modelo simple para la selección de ámbito en el editor web.
class AmbitoSeleccion {
  final String nivel;
  final String nivelId;

  const AmbitoSeleccion({required this.nivel, required this.nivelId});

  String? get sedeId => nivel == 'SEDE' ? nivelId : null;
  String? get facultadId => nivel == 'FACULTAD' ? nivelId : null;
  String? get bloqueId => nivel == 'BLOQUE' ? nivelId : null;
  String? get espacioId => nivel == 'AULA' ? nivelId : null;

  bool get esGlobal => nivel == 'GLOBAL';
}
