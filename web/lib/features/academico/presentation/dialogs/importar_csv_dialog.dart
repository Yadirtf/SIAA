import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/upload/selector_archivos.dart';
import '../bloc/academico_bloc.dart';
import '../bloc/academico_event.dart';
import '../bloc/importacion_bloc.dart';
import '../widgets/informe_importacion.dart';

/// Firma inyectable del selector de archivos (en pruebas no hay diálogo nativo).
typedef SeleccionarArchivo = Future<ArchivoSeleccionado?> Function({
  String accept,
});

/// Asistente de carga masiva (T-ACA-07.7): plantilla, archivo, informe por fila,
/// diagnóstico descargable y aplicación como un lote.
class ImportarCsvDialog extends StatelessWidget {
  final SeleccionarArchivo seleccionar;

  const ImportarCsvDialog({super.key, this.seleccionar = seleccionarArchivo});

  Future<void> _elegir(BuildContext context) async {
    final archivo = await seleccionar(accept: '.csv,.xlsx,text/csv');
    if (archivo == null || !context.mounted) return;
    context.read<ImportacionBloc>().add(
      PreviewImportarCsvEvent(bytes: archivo.bytes, filename: archivo.nombre),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ImportacionBloc, ImportacionState>(
      listener: (context, state) {
        if (state is ImportacionSuccess) {
          context.read<AcademicoBloc>().add(const LoadAcademicoDataEvent());
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.statusSuccessBg,
            ),
          );
          Navigator.pop(context);
        }
      },
      builder: (context, state) {
        final bloc = context.read<ImportacionBloc>();
        final previa = state is ImportacionPreviewLoaded ? state : null;
        return AlertDialog(
          title: Text('Carga masiva de horarios', style: AppTextStyles.h3),
          content: SizedBox(
            width: 640,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Suba un archivo CSV o XLSX con la plantilla publicada. '
                    'Los códigos se verifican contra periodos, asignaturas, '
                    'docentes (documento o correo) y aulas existentes; nada se '
                    'guarda hasta que aplique la carga.',
                    style: AppTextStyles.bodyMedium,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      for (final f in const ['csv', 'xlsx'])
                        TextButton.icon(
                          icon: const Icon(Icons.download_rounded, size: 16),
                          label: Text('Plantilla ${f.toUpperCase()}'),
                          onPressed: () => bloc.add(DescargarPlantillaEvent(f)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.upload_file_rounded),
                    label: Text(
                      previa == null
                          ? 'Elegir archivo'
                          : '${previa.nombreArchivo} · elegir otro',
                    ),
                    onPressed: state is ImportacionLoading
                        ? null
                        : () => _elegir(context),
                  ),
                  const SizedBox(height: 12),
                  if (state is ImportacionLoading)
                    Row(
                      children: [
                        const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        const SizedBox(width: 8),
                        Text(state.message, style: AppTextStyles.bodySmall),
                      ],
                    ),
                  if (state is ImportacionError)
                    Text(
                      state.message,
                      style: const TextStyle(color: AppColors.accentRose),
                    ),
                  if (previa?.aviso != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        previa!.aviso!,
                        style: const TextStyle(color: AppColors.accentRose),
                      ),
                    ),
                  if (previa != null)
                    InformeImportacion(preview: previa.preview),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                bloc.add(const ClearImportacionEvent());
                Navigator.pop(context);
              },
              child: const Text('Cerrar'),
            ),
            if (previa != null && previa.preview.filasConError > 0)
              TextButton.icon(
                icon: const Icon(Icons.fact_check_outlined, size: 18),
                label: const Text('Descargar diagnóstico'),
                onPressed: () => bloc.add(const DescargarDiagnosticoEvent()),
              ),
            if (previa != null)
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.statusSuccessText,
                ),
                onPressed:
                    previa.preview.superaUmbral ||
                        previa.preview.filasValidas == 0
                    ? null
                    : () => bloc.add(const ConfirmarImportarCsvEvent()),
                icon: const Icon(Icons.done_all_rounded, size: 18),
                label: Text(
                  'Aplicar carga (${previa.preview.filasValidas} filas)',
                ),
              ),
          ],
        );
      },
    );
  }
}
