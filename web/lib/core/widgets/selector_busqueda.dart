import 'package:flutter/material.dart';

import 'dialogo_busqueda.dart';

/// Campo de formulario que elige una entidad buscándola por texto legible
/// (nombre, código, correo...) en lugar de pedir su id interno. Al tocarlo
/// abre un [DialogoBusqueda]; con [idInicial] resuelve y muestra la etiqueta.
class SelectorBusqueda<T extends Object> extends StatefulWidget {
  final String etiqueta;
  final String ayuda;
  final IconData icono;
  final BuscarOpciones<T> buscar;
  final String Function(T) textoDe;
  final String? Function(T)? detalleDe;
  final String Function(T) idDe;

  /// Busca la opción de un id ya guardado (edición o filtro previo).
  final Future<T?> Function(String id)? resolver;
  final String? idInicial;
  final ValueChanged<T?> onCambio;
  final bool requerido;
  final String? Function(T? valor)? validador;
  final bool habilitado;
  final bool denso;
  final Duration espera;

  const SelectorBusqueda({
    super.key,
    required this.etiqueta,
    required this.buscar,
    required this.textoDe,
    required this.idDe,
    required this.onCambio,
    this.detalleDe,
    this.resolver,
    this.idInicial,
    this.ayuda = 'Escribe para buscar',
    this.icono = Icons.search_rounded,
    this.requerido = false,
    this.validador,
    this.habilitado = true,
    this.denso = false,
    this.espera = const Duration(milliseconds: 300),
  });

  @override
  State<SelectorBusqueda<T>> createState() => _SelectorBusquedaState<T>();
}

class _SelectorBusquedaState<T extends Object>
    extends State<SelectorBusqueda<T>> {
  final _campo = GlobalKey<FormFieldState<T>>();
  T? _seleccion;
  bool _resolviendo = false;
  bool _noEncontrado = false;

  @override
  void initState() {
    super.initState();
    _resolverInicial();
  }

  @override
  void didUpdateWidget(covariant SelectorBusqueda<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    final actual = _seleccion == null ? null : widget.idDe(_seleccion as T);
    if (widget.idInicial != oldWidget.idInicial && widget.idInicial != actual) {
      _resolverInicial();
    }
  }

  Future<void> _resolverInicial() async {
    final id = widget.idInicial;
    if (id == null || id.isEmpty) {
      _asignar(null, notificar: false);
      return;
    }
    if (widget.resolver == null) return;
    setState(() {
      _resolviendo = true;
      _noEncontrado = false;
    });
    T? encontrado;
    try {
      encontrado = await widget.resolver!(id);
    } catch (_) {
      encontrado = null;
    }
    if (!mounted || widget.idInicial != id) return;
    setState(() {
      _resolviendo = false;
      _noEncontrado = encontrado == null;
    });
    _asignar(encontrado, notificar: false);
  }

  void _asignar(T? valor, {bool notificar = true}) {
    setState(() {
      _seleccion = valor;
      if (valor != null) _noEncontrado = false;
    });
    if (!notificar) return;
    // Revalida solo si ya mostraba un error, para limpiarlo al elegir.
    if (_campo.currentState?.hasError ?? false) _campo.currentState!.validate();
    widget.onCambio(valor);
  }

  Future<void> _abrir() async {
    final elegido = await DialogoBusqueda.mostrar<T>(
      context,
      titulo: widget.etiqueta.replaceAll('*', '').trim(),
      buscar: widget.buscar,
      textoDe: widget.textoDe,
      detalleDe: widget.detalleDe,
      ayuda: widget.ayuda,
      espera: widget.espera,
    );
    if (elegido != null && mounted) _asignar(elegido);
  }

  String? _validar(T? valor) {
    if (widget.requerido && valor == null) return 'Requerido';
    return widget.validador?.call(valor);
  }

  @override
  Widget build(BuildContext context) {
    return FormField<T>(
      key: _campo,
      // El valor vive en este estado (no en el FormField) para no notificar
      // al Form durante el build cuando cambia [idInicial].
      validator: (_) => _validar(_seleccion),
      builder: (field) {
        final valor = _seleccion;
        final detalle = valor == null ? null : widget.detalleDe?.call(valor);
        return InkWell(
          onTap: widget.habilitado ? _abrir : null,
          child: InputDecorator(
            isEmpty: valor == null && !_resolviendo,
            decoration: InputDecoration(
              labelText: widget.etiqueta,
              hintText: _noEncontrado ? 'No disponible, elige otro' : null,
              helperText: detalle,
              errorText: field.errorText,
              enabled: widget.habilitado,
              isDense: widget.denso,
              border: widget.denso ? const OutlineInputBorder() : null,
              prefixIcon: Icon(widget.icono, size: widget.denso ? 18 : null),
              suffixIcon: _sufijo(valor),
            ),
            child: Text(
              _resolviendo
                  ? 'Cargando…'
                  : (valor == null ? '' : widget.textoDe(valor)),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        );
      },
    );
  }

  Widget? _sufijo(T? valor) {
    if (!widget.habilitado) return null;
    if (valor != null) {
      return IconButton(
        tooltip: 'Quitar selección',
        icon: const Icon(Icons.clear, size: 18),
        onPressed: () => _asignar(null),
      );
    }
    return const Icon(Icons.arrow_drop_down_rounded);
  }
}
