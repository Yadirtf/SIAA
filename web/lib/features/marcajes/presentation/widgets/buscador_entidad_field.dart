// buscador_entidad_field.dart — Campo de búsqueda y selección reactiva de entidades (US-MAR-09)
import 'package:flutter/material.dart';

class BuscadorEntidadField<T extends Object> extends StatefulWidget {
  final String label;
  final String hint;
  final IconData icon;
  final List<T> items;
  final String Function(T) labelExtractor;
  final String Function(T) idExtractor;
  final bool Function(T item, String query) filter;
  final ValueChanged<String?> onSelected;
  final String? initialId;
  final bool isRequired;

  const BuscadorEntidadField({
    super.key,
    required this.label,
    required this.hint,
    required this.icon,
    required this.items,
    required this.labelExtractor,
    required this.idExtractor,
    required this.filter,
    required this.onSelected,
    this.initialId,
    this.isRequired = false,
  });

  @override
  State<BuscadorEntidadField<T>> createState() => _BuscadorEntidadFieldState<T>();
}

class _BuscadorEntidadFieldState<T extends Object> extends State<BuscadorEntidadField<T>> {
  @override
  Widget build(BuildContext context) {
    return Autocomplete<T>(
      displayStringForOption: widget.labelExtractor,
      optionsBuilder: (textEditingValue) {
        final query = textEditingValue.text.trim();
        if (query.isEmpty) {
          return widget.items.take(15);
        }
        return widget.items.where((item) => widget.filter(item, query)).take(15);
      },
      onSelected: (item) {
        widget.onSelected(widget.idExtractor(item));
      },
      fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
        return TextField(
          controller: controller,
          focusNode: focusNode,
          decoration: InputDecoration(
            labelText: widget.label,
            hintText: widget.hint,
            prefixIcon: Icon(widget.icon, size: 18),
            suffixIcon: controller.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, size: 16),
                    onPressed: () {
                      controller.clear();
                      widget.onSelected(null);
                    },
                  )
                : null,
            border: const OutlineInputBorder(),
            isDense: true,
          ),
        );
      },
    );
  }
}
