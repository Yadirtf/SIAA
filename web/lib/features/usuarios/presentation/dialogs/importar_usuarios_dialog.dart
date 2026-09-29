import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../bloc/importacion_usuarios_bloc.dart';
import '../bloc/usuarios_bloc.dart';
import '../bloc/usuarios_event.dart';
import '../widgets/importacion_usuarios_resumen.dart';

/// Carga masiva de usuarios desde CSV: primero valida (vista previa) y luego
/// confirma la creación de las filas válidas.
class ImportarUsuariosDialog extends StatefulWidget {
  const ImportarUsuariosDialog({super.key});

  static Future<void> show(BuildContext context) {
    context.read<ImportacionUsuariosBloc>().add(
      const ReiniciarImportacionUsuariosEvent(),
    );
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const ImportarUsuariosDialog(),
    );
  }

  @override
  State<ImportarUsuariosDialog> createState() => _ImportarUsuariosDialogState();
}

class _ImportarUsuariosDialogState extends State<ImportarUsuariosDialog> {
  final _csv = TextEditingController();

  static const String _plantilla =
      'correo,nombre,apellido,documento,roles,ambitos\n'
      'docente@universidad.edu.co,Ana,Pérez,1020304050,DOCENTE,\n'
      'coordinador@universidad.edu.co,Luis,Gómez,1090807060,'
      'COORDINADOR|DOCENTE,FACULTAD:<id-facultad>';

  @override
  void dispose() {
    _csv.dispose();
    super.dispose();
  }

  void _validar() {
    final texto = _csv.text.trim();
    if (texto.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingrese el contenido del archivo CSV')),
      );
      return;
    }
    context.read<ImportacionUsuariosBloc>().add(
      PrevisualizarImportacionUsuariosEvent('$texto\n'),
    );
  }

  void _cerrar() {
    final bloc = context.read<ImportacionUsuariosBloc>();
    if (bloc.state.paso == ImportacionUsuariosPaso.completada) {
      context.read<UsuariosBloc>().add(const RecargarUsuariosEvent());
    }
    bloc.add(const ReiniciarImportacionUsuariosEvent());
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ImportacionUsuariosBloc, ImportacionUsuariosState>(
      builder: (context, state) {
        final editable =
            state.paso == ImportacionUsuariosPaso.inicial ||
            state.paso == ImportacionUsuariosPaso.previa;
        return AlertDialog(
          title: Row(
            children: [
              const Icon(
                Icons.upload_file_rounded,
                color: AppColors.primaryAccent,
              ),
              const SizedBox(width: 8),
              Text('Importar usuarios desde CSV', style: AppTextStyles.h3),
            ],
          ),
          content: SizedBox(
            width: 680,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Columnas: correo, nombre, apellido, documento y, '
                    'opcionalmente, roles (separados por |, DOCENTE por '
                    'defecto) y ambitos (TIPO:id|TIPO:id). Los usuarios '
                    'recibirán un correo de invitación.',
                    style: AppTextStyles.bodyMedium,
                  ),
                  TextButton.icon(
                    icon: const Icon(Icons.content_copy_rounded, size: 16),
                    label: const Text('Cargar plantilla de ejemplo'),
                    onPressed: editable ? () => _csv.text = _plantilla : null,
                  ),
                  TextField(
                    controller: _csv,
                    enabled: editable,
                    maxLines: 7,
                    onChanged: (_) {
                      if (state.paso == ImportacionUsuariosPaso.previa) {
                        context.read<ImportacionUsuariosBloc>().add(
                          const ReiniciarImportacionUsuariosEvent(),
                        );
                      }
                    },
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Contenido CSV *',
                      hintText:
                          'correo,nombre,apellido,documento,roles,ambitos',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (state.ocupado)
                    const Center(child: CircularProgressIndicator()),
                  if (state.error != null)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: AppColors.statusDangerBg,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Error: ${state.error}',
                        style: const TextStyle(
                          color: AppColors.statusDangerText,
                        ),
                      ),
                    ),
                  if (state.resultado != null && !state.ocupado)
                    ImportacionUsuariosResumen(resultado: state.resultado!),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: state.ocupado ? null : _cerrar,
              child: const Text('Cerrar'),
            ),
            if (state.paso == ImportacionUsuariosPaso.inicial)
              ElevatedButton.icon(
                onPressed: _validar,
                icon: const Icon(Icons.fact_check_outlined, size: 18),
                label: const Text('Validar CSV'),
              ),
            if (state.paso == ImportacionUsuariosPaso.previa)
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.statusSuccessText,
                  foregroundColor: Colors.white,
                ),
                onPressed: (state.resultado?.validas ?? 0) > 0
                    ? () => context.read<ImportacionUsuariosBloc>().add(
                        const ConfirmarImportacionUsuariosEvent(),
                      )
                    : null,
                icon: const Icon(Icons.done_all_rounded, size: 18),
                label: Text('Crear ${state.resultado?.validas ?? 0} usuarios'),
              ),
          ],
        );
      },
    );
  }
}
