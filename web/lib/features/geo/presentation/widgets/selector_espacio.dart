import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/busqueda_texto.dart';
import '../../../../core/widgets/selector_busqueda.dart';
import '../../data/buscador_espacios.dart';
import '../../data/models/espacio_opcion.dart';

/// Selector de aula/espacio por código, nombre o bloque (nunca por id).
/// Carga una vez los espacios visibles de [sedeId] y filtra localmente.
/// Sin [sedeId] pero con [sedeDelEspacioId], se limita a la sede de ese
/// espacio (p. ej. el aula actual de una sesión).
class SelectorEspacio extends StatefulWidget {
  final String etiqueta;
  final String? sedeId;
  final String? sedeDelEspacioId;
  final String? excluirId;
  final String? idInicial;
  final ValueChanged<EspacioOpcion?> onCambio;
  final bool requerido;
  final BuscadorEspacios? buscador;

  const SelectorEspacio({
    super.key,
    required this.etiqueta,
    required this.onCambio,
    this.sedeId,
    this.sedeDelEspacioId,
    this.excluirId,
    this.idInicial,
    this.requerido = false,
    this.buscador,
  });

  @override
  State<SelectorEspacio> createState() => _SelectorEspacioState();
}

class _SelectorEspacioState extends State<SelectorEspacio> {
  Future<List<EspacioOpcion>>? _carga;
  String? _sedeCargada;

  @override
  void didUpdateWidget(covariant SelectorEspacio oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.sedeId != oldWidget.sedeId) _carga = null;
  }

  BuscadorEspacios get _fuente =>
      widget.buscador ?? context.read<BuscadorEspacios>();

  Future<List<EspacioOpcion>> _espacios() {
    if (_carga == null || _sedeCargada != widget.sedeId) {
      _sedeCargada = widget.sedeId;
      _carga = _cargar().catchError((Object e) {
        _carga = null; // permite reintentar tras un error
        throw e;
      });
    }
    return _carga!;
  }

  Future<List<EspacioOpcion>> _cargar() async {
    final sede = widget.sedeId;
    var lista = await _fuente.listar(
      sedeId: sede == null || sede.isEmpty ? null : sede,
    );
    final referencia = widget.sedeDelEspacioId;
    if ((sede == null || sede.isEmpty) && referencia != null) {
      final actual = lista.where((e) => e.id == referencia);
      if (actual.isNotEmpty) {
        final sedeRef = actual.first.sedeId;
        lista = lista.where((e) => e.sedeId == sedeRef).toList();
      }
    }
    return lista.where((e) => e.id != widget.excluirId).toList();
  }

  @override
  Widget build(BuildContext context) {
    return SelectorBusqueda<EspacioOpcion>(
      etiqueta: widget.etiqueta,
      ayuda: 'Código, nombre o bloque del aula',
      icono: Icons.meeting_room_outlined,
      requerido: widget.requerido,
      idInicial: widget.idInicial,
      onCambio: widget.onCambio,
      espera: const Duration(milliseconds: 150),
      buscar: (q) async =>
          filtrarPorTexto(await _espacios(), (e) => e.etiqueta, q),
      resolver: (id) async {
        final lista = await _espacios();
        final hallado = lista.where((e) => e.id == id);
        return hallado.isEmpty ? null : hallado.first;
      },
      textoDe: (e) => e.etiqueta,
      detalleDe: (e) => e.detalle,
      idDe: (e) => e.id,
    );
  }
}
