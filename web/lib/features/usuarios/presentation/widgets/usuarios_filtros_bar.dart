import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../bloc/catalogo_usuarios_cubit.dart';
import '../bloc/usuarios_filtro.dart';

/// Búsqueda por texto y filtros por rol y estado del listado de usuarios.
class UsuariosFiltrosBar extends StatefulWidget {
  final UsuariosFiltro filtro;
  final ValueChanged<UsuariosFiltro> onFiltrar;
  final VoidCallback onRecargar;

  const UsuariosFiltrosBar({
    super.key,
    required this.filtro,
    required this.onFiltrar,
    required this.onRecargar,
  });

  @override
  State<UsuariosFiltrosBar> createState() => _UsuariosFiltrosBarState();
}

class _UsuariosFiltrosBarState extends State<UsuariosFiltrosBar> {
  late final _texto = TextEditingController(text: widget.filtro.texto);

  @override
  void dispose() {
    _texto.dispose();
    super.dispose();
  }

  void _aplicar(UsuariosFiltro f) => widget.onFiltrar(f.copyWith(pagina: 1));

  @override
  Widget build(BuildContext context) {
    final roles = context.select<CatalogoUsuariosCubit, List<String>>(
      (c) => c.state.catalogo.roles.map((r) => r.nombre).toList(),
    );
    final f = widget.filtro;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          SizedBox(
            width: 320,
            child: TextField(
              controller: _texto,
              textInputAction: TextInputAction.search,
              onSubmitted: (v) => _aplicar(f.copyWith(texto: v.trim())),
              decoration: InputDecoration(
                labelText: 'Buscar por nombre, correo o documento',
                prefixIcon: const Icon(Icons.search_rounded),
                border: const OutlineInputBorder(),
                isDense: true,
                suffixIcon: IconButton(
                  tooltip: 'Buscar',
                  icon: const Icon(Icons.arrow_forward_rounded),
                  onPressed: () =>
                      _aplicar(f.copyWith(texto: _texto.text.trim())),
                ),
              ),
            ),
          ),
          SizedBox(
            width: 220,
            child: DropdownButtonFormField<String?>(
              value: roles.contains(f.rol) ? f.rol : null,
              isDense: true,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Rol',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              items: [
                const DropdownMenuItem<String?>(child: Text('Todos')),
                ...roles.map(
                  (r) => DropdownMenuItem<String?>(value: r, child: Text(r)),
                ),
              ],
              onChanged: (v) => _aplicar(f.copyWith(rol: () => v)),
            ),
          ),
          SizedBox(
            width: 180,
            child: DropdownButtonFormField<bool?>(
              value: f.activo,
              isDense: true,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Estado',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              items: const [
                DropdownMenuItem<bool?>(child: Text('Todos')),
                DropdownMenuItem<bool?>(value: true, child: Text('Activos')),
                DropdownMenuItem<bool?>(value: false, child: Text('Inactivos')),
              ],
              onChanged: (v) => _aplicar(f.copyWith(activo: () => v)),
            ),
          ),
          IconButton(
            tooltip: 'Recargar',
            onPressed: widget.onRecargar,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
    );
  }
}
