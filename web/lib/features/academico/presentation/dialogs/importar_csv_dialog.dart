import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../bloc/academico_bloc.dart';
import '../bloc/academico_event.dart';
import '../bloc/importacion_bloc.dart';

class ImportarCsvDialog extends StatefulWidget {
  const ImportarCsvDialog({super.key});

  @override
  State<ImportarCsvDialog> createState() => _ImportarCsvDialogState();
}

class _ImportarCsvDialogState extends State<ImportarCsvDialog> {
  final _csvTextCtrl = TextEditingController();

  static const String _plantillaCsv =
      'periodoCodigo,facultadCodigo,programaCodigo,asignaturaCodigo,asignaturaNombre,grupoCodigo,docenteDocumento,aulaCodigo,diaSemana,horaInicio,horaFin,modalidad\n'
      '2026-1,FAC-ING,PROG-SIS,ASIG-101,Programacion I,GRP-1,DOC-12345,AULA-101,1,08:00,10:00,PRESENCIAL';

  @override
  void dispose() {
    _csvTextCtrl.dispose();
    super.dispose();
  }

  void _onPreview() {
    final text = _csvTextCtrl.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingrese el contenido del archivo CSV')),
      );
      return;
    }
    final bytes = utf8.encode(text);
    context.read<ImportacionBloc>().add(
          PreviewImportarCsvEvent(bytes: bytes, filename: 'importacion.csv'),
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
        return AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.file_upload_outlined, color: AppColors.primaryAccent),
              const SizedBox(width: 8),
              Text('Carga Masiva de Horarios (US-ACA-07)', style: AppTextStyles.h3),
            ],
          ),
          content: SizedBox(
            width: 620,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pegue o cargue el contenido CSV con las columnas de estructura y asignaciones académicas:',
                    style: AppTextStyles.bodyMedium,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      TextButton.icon(
                        icon: const Icon(Icons.content_copy_rounded, size: 16),
                        label: const Text('Cargar plantilla de ejemplo'),
                        onPressed: () {
                          _csvTextCtrl.text = _plantillaCsv;
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _csvTextCtrl,
                    maxLines: 7,
                    style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                    decoration: const InputDecoration(
                      labelText: 'Contenido CSV *',
                      hintText: 'periodoCodigo,facultadCodigo,programaCodigo...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (state is ImportacionLoading)
                    Center(
                      child: Column(
                        children: [
                          const CircularProgressIndicator(),
                          const SizedBox(height: 8),
                          Text(state.message, style: AppTextStyles.bodySmall),
                        ],
                      ),
                    ),
                  if (state is ImportacionError)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.accentRose.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Error: ${state.message}',
                        style: const TextStyle(color: AppColors.accentRose),
                      ),
                    ),
                  if (state is ImportacionPreviewLoaded) ...[
                    const Divider(height: 24),
                    Text(
                      'Resumen de Validación Preliminar:',
                      style: AppTextStyles.h3,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _buildStatChip(
                          'Total filas: ${state.preview.totalFilas}',
                          AppColors.statusInfoBg,
                          AppColors.statusInfoText,
                        ),
                        const SizedBox(width: 8),
                        _buildStatChip(
                          'Válidas: ${state.preview.filasValidas}',
                          AppColors.statusSuccessBg,
                          AppColors.statusSuccessText,
                        ),
                        const SizedBox(width: 8),
                        _buildStatChip(
                          'Con error: ${state.preview.filasConError}',
                          AppColors.statusWarningBg,
                          AppColors.statusWarningText,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (state.preview.filasConError > 0)
                      Container(
                        constraints: const BoxConstraints(maxHeight: 140),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: ListView(
                          shrinkWrap: true,
                          children: state.preview.filas
                              .where((f) => !f.valida)
                              .map(
                                (f) => ListTile(
                                  dense: true,
                                  leading: const Icon(Icons.error_outline,
                                      color: Colors.amber, size: 18),
                                  title: Text('Fila ${f.numeroFila}: ${f.asignaturaNombre}'),
                                  subtitle: Text(f.errores.join(', ')),
                                ),
                              )
                              .toList(),
                        ),
                      ),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                context.read<ImportacionBloc>().add(const ClearImportacionEvent());
                Navigator.pop(context);
              },
              child: const Text('Cerrar'),
            ),
            if (state is! ImportacionPreviewLoaded)
              ElevatedButton.icon(
                onPressed: _onPreview,
                icon: const Icon(Icons.check_circle_outline, size: 18),
                label: const Text('Validar CSV'),
              ),
            if (state is ImportacionPreviewLoaded)
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.statusSuccessText,
                ),
                onPressed: state.preview.filasValidas > 0
                    ? () {
                        final filasPayload = state.preview.filas
                            .where((f) => f.valida)
                            .map((f) => f.toJson())
                            .toList();
                        context.read<ImportacionBloc>().add(
                              ConfirmarImportarCsvEvent(filasPayload),
                            );
                      }
                    : null,
                icon: const Icon(Icons.done_all_rounded, size: 18),
                label: Text(
                  'Confirmar Importación (${state.preview.filasValidas} filas)',
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildStatChip(String text, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(color: fg, fontWeight: FontWeight.bold, fontSize: 12),
      ),
    );
  }
}
