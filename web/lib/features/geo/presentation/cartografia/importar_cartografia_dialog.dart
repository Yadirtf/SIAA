import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/upload/selector_archivos.dart';
import '../../data/models/geo_models.dart';
import 'importar_cartografia_cubit.dart';
import 'lista_preview_cartografia.dart';

/// Firma inyectable del selector de archivos (en pruebas no hay diálogo).
typedef SeleccionarArchivoCartografia = Future<ArchivoSeleccionado?> Function({
  String accept,
});

/// Abre el asistente de importación de cartografía para [sedeId]. Devuelve
/// `true` si se creó al menos un espacio, para recargar la lista.
Future<bool> mostrarImportarCartografia(
  BuildContext context, {
  required String sedeId,
  required List<BloqueModel> bloques,
}) async {
  final r = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (_) => BlocProvider(
      create: (_) => ImportarCartografiaCubit(),
      child: ImportarCartografiaDialog(sedeId: sedeId, bloques: bloques),
    ),
  );
  return r ?? false;
}

/// Importación GeoJSON o KML (US-GEO-11): archivo → informe por elemento →
/// confirmación. Requiere un [ImportarCartografiaCubit] en el contexto.
class ImportarCartografiaDialog extends StatefulWidget {
  final String sedeId;
  final List<BloqueModel> bloques;
  final SeleccionarArchivoCartografia seleccionar;

  const ImportarCartografiaDialog({
    super.key,
    required this.sedeId,
    this.bloques = const [],
    this.seleccionar = seleccionarArchivo,
  });

  @override
  State<ImportarCartografiaDialog> createState() =>
      _ImportarCartografiaDialogState();
}

class _ImportarCartografiaDialogState extends State<ImportarCartografiaDialog> {
  String? _bloqueId;
  final _piso = TextEditingController();

  @override
  void dispose() {
    _piso.dispose();
    super.dispose();
  }

  Future<void> _elegir() async {
    final archivo = await widget.seleccionar(
      accept:
          '.geojson,.json,.kml,application/geo+json,'
          'application/vnd.google-earth.kml+xml',
    );
    if (archivo == null || !mounted) return;
    await context.read<ImportarCartografiaCubit>().previsualizar(
      archivo.bytes,
      archivo.nombre,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ImportarCartografiaCubit, ImportarCartografiaState>(
      builder: (context, s) {
        final cubit = context.read<ImportarCartografiaCubit>();
        final ocupado =
            s.paso == PasoImportacionCartografia.analizando ||
            s.paso == PasoImportacionCartografia.confirmando;
        final terminado = s.paso == PasoImportacionCartografia.completada;
        return AlertDialog(
          title: Text('Importar cartografía', style: AppTextStyles.h3),
          content: SizedBox(
            width: 640,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Suba un archivo GeoJSON (.geojson) o KML (.kml) con '
                    'polígonos de aulas. Cada espacio se valida igual que al '
                    'dibujarlo y nada se guarda hasta confirmar. En KML, el '
                    'código y el nombre se toman de ExtendedData (codigo, '
                    'nombre) o de <name>/<description>.',
                    style: AppTextStyles.bodyMedium,
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.upload_file_rounded),
                    label: Text(s.archivo ?? 'Elegir archivo GeoJSON o KML'),
                    onPressed: ocupado || terminado ? null : _elegir,
                  ),
                  if (ocupado) ...[
                    const SizedBox(height: 12),
                    const LinearProgressIndicator(),
                  ],
                  if (s.error != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      s.error!,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.accentRose,
                      ),
                    ),
                  ],
                  if (s.previa != null && !terminado) ...[
                    const SizedBox(height: 12),
                    _ubicacion(),
                    const SizedBox(height: 12),
                    ListaPreviewCartografia(previa: s.previa!),
                  ],
                  if (s.resultado != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      '${s.resultado!.totalImportados} espacios importados.',
                      style: AppTextStyles.h3,
                    ),
                    for (final o in s.resultado!.omitidos)
                      Text('Omitido $o', style: AppTextStyles.bodyMedium),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: ocupado
                  ? null
                  : () => Navigator.pop(
                      context,
                      (s.resultado?.totalImportados ?? 0) > 0,
                    ),
              child: Text(terminado ? 'Cerrar' : 'Cancelar'),
            ),
            if (!terminado)
              ElevatedButton(
                onPressed: s.puedeConfirmar
                    ? () => cubit.confirmar(
                        sedeId: widget.sedeId,
                        bloqueId: _bloqueId,
                        piso: int.tryParse(_piso.text.trim()),
                      )
                    : null,
                child: Text(
                  'Importar ${s.previa?.validos ?? 0} espacios válidos',
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _ubicacion() => Row(
    children: [
      Expanded(
        child: DropdownButtonFormField<String?>(
          value: _bloqueId,
          decoration: const InputDecoration(labelText: 'Bloque (opcional)'),
          items: [
            const DropdownMenuItem(value: null, child: Text('Sin bloque')),
            for (final b in widget.bloques)
              DropdownMenuItem(value: b.id, child: Text(b.nombre)),
          ],
          onChanged: (v) => setState(() => _bloqueId = v),
        ),
      ),
      const SizedBox(width: 12),
      SizedBox(
        width: 120,
        child: TextField(
          controller: _piso,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Piso'),
        ),
      ),
    ],
  );
}
