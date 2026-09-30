import 'dart:async';

import 'package:flutter/material.dart';

import '../network/api_exception.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// Fuente de opciones: recibe el texto escrito y devuelve las coincidencias
/// (búsqueda remota en el API o filtro sobre una lista ya cargada).
typedef BuscarOpciones<T> = Future<List<T>> Function(String consulta);

/// Diálogo con un campo de búsqueda y la lista de resultados. Consulta la
/// fuente al abrirse (texto vacío) y tras cada pausa de [espera] al escribir.
/// Devuelve la opción elegida o null si se cierra sin elegir.
class DialogoBusqueda<T extends Object> extends StatefulWidget {
  final String titulo;
  final String ayuda;
  final BuscarOpciones<T> buscar;
  final String Function(T) textoDe;
  final String? Function(T)? detalleDe;
  final Duration espera;

  const DialogoBusqueda({
    super.key,
    required this.titulo,
    required this.buscar,
    required this.textoDe,
    this.detalleDe,
    this.ayuda = 'Escribe para buscar',
    this.espera = const Duration(milliseconds: 300),
  });

  static Future<T?> mostrar<T extends Object>(
    BuildContext context, {
    required String titulo,
    required BuscarOpciones<T> buscar,
    required String Function(T) textoDe,
    String? Function(T)? detalleDe,
    String ayuda = 'Escribe para buscar',
    Duration espera = const Duration(milliseconds: 300),
  }) {
    return showDialog<T>(
      context: context,
      builder: (_) => DialogoBusqueda<T>(
        titulo: titulo,
        buscar: buscar,
        textoDe: textoDe,
        detalleDe: detalleDe,
        ayuda: ayuda,
        espera: espera,
      ),
    );
  }

  @override
  State<DialogoBusqueda<T>> createState() => _DialogoBusquedaState<T>();
}

class _DialogoBusquedaState<T extends Object>
    extends State<DialogoBusqueda<T>> {
  final _consultaCtrl = TextEditingController();
  Timer? _temporizador;
  int _peticion = 0;
  bool _cargando = false;
  String? _error;
  List<T> _opciones = const [];

  @override
  void initState() {
    super.initState();
    _consultar('');
  }

  @override
  void dispose() {
    _temporizador?.cancel();
    _consultaCtrl.dispose();
    super.dispose();
  }

  void _alEscribir(String texto) {
    _temporizador?.cancel();
    _temporizador = Timer(widget.espera, () => _consultar(texto.trim()));
  }

  /// Solo aplica la respuesta más reciente: las lentas y viejas se descartan.
  Future<void> _consultar(String consulta) async {
    final id = ++_peticion;
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final opciones = await widget.buscar(consulta);
      if (!mounted || id != _peticion) return;
      setState(() {
        _opciones = opciones;
        _cargando = false;
      });
    } catch (e) {
      if (!mounted || id != _peticion) return;
      setState(() {
        _opciones = const [];
        _cargando = false;
        _error = e is ApiException ? e.message : 'No se pudo cargar: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.titulo, style: AppTextStyles.h3),
      content: SizedBox(
        width: 480,
        height: 420,
        child: Column(
          children: [
            TextField(
              controller: _consultaCtrl,
              autofocus: true,
              onChanged: _alEscribir,
              onSubmitted: (t) {
                _temporizador?.cancel();
                _consultar(t.trim());
              },
              decoration: InputDecoration(
                hintText: widget.ayuda,
                prefixIcon: const Icon(Icons.search_rounded),
                border: const OutlineInputBorder(),
                isDense: true,
              ),
            ),
            SizedBox(
              height: 4,
              child: _cargando ? const LinearProgressIndicator() : null,
            ),
            const SizedBox(height: 8),
            Expanded(child: _resultados()),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cerrar'),
        ),
      ],
    );
  }

  Widget _resultados() {
    if (_error != null) {
      return _Aviso(
        icono: Icons.error_outline,
        texto: _error!,
        color: AppColors.accentRose,
        onReintentar: () => _consultar(_consultaCtrl.text.trim()),
      );
    }
    if (_opciones.isEmpty) {
      return _cargando
          ? const SizedBox.shrink()
          : const _Aviso(
              icono: Icons.search_off_rounded,
              texto: 'Sin resultados',
            );
    }
    return ListView.separated(
      itemCount: _opciones.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, i) {
        final opcion = _opciones[i];
        final detalle = widget.detalleDe?.call(opcion);
        return ListTile(
          dense: true,
          title: Text(widget.textoDe(opcion)),
          subtitle: detalle == null || detalle.isEmpty ? null : Text(detalle),
          onTap: () => Navigator.pop(context, opcion),
        );
      },
    );
  }
}

class _Aviso extends StatelessWidget {
  final IconData icono;
  final String texto;
  final Color color;
  final VoidCallback? onReintentar;

  const _Aviso({
    required this.icono,
    required this.texto,
    this.color = AppColors.textMuted,
    this.onReintentar,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icono, color: color, size: 32),
          const SizedBox(height: 8),
          Text(texto, textAlign: TextAlign.center),
          if (onReintentar != null)
            TextButton(
              onPressed: onReintentar,
              child: const Text('Reintentar'),
            ),
        ],
      ),
    );
  }
}
