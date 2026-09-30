import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../data/models/geo_models.dart';
import '../../domain/codigo_qr.dart';
import '../../domain/geo_repository.dart';
import '../bloc/geo_bloc.dart';
import '../bloc/geo_event.dart';
import '../bloc/verificacion_espacio_cubit.dart';
import '../bloc/verificacion_espacio_state.dart';
import '../widgets/bssid_list_editor.dart';

const _camposConocidos = {'wifiBssids', 'bleUuid', 'qrCodigo'};

/// Abre el diálogo de verificación complementaria (RF-GEO-016) de [espacio].
/// Al guardar, el espacio devuelto por el backend reemplaza al de la lista.
Future<void> mostrarVerificacionEspacioDialog(
  BuildContext context,
  EspacioModel espacio,
) {
  final repository = context.read<GeoRepository>();
  final geoBloc = context.read<GeoBloc>();
  return showDialog<void>(
    context: context,
    builder: (_) => BlocProvider(
      create: (_) => VerificacionEspacioCubit(
        repository: repository,
        espacioId: espacio.id,
      ),
      child: VerificacionEspacioDialog(
        espacio: espacio,
        onGuardado: (e) => geoBloc.add(EspacioActualizadoEvent(e)),
      ),
    ),
  );
}

/// Formulario de BSSIDs WiFi, UUID BLE y código QR de un espacio.
/// Requiere un [VerificacionEspacioCubit] en el contexto.
class VerificacionEspacioDialog extends StatefulWidget {
  final EspacioModel espacio;
  final ValueChanged<EspacioModel> onGuardado;

  const VerificacionEspacioDialog({
    super.key,
    required this.espacio,
    required this.onGuardado,
  });

  @override
  State<VerificacionEspacioDialog> createState() =>
      _VerificacionEspacioDialogState();
}

class _VerificacionEspacioDialogState extends State<VerificacionEspacioDialog> {
  late List<String> _bssids;
  late final TextEditingController _bleCtrl;
  late final TextEditingController _qrCtrl;

  @override
  void initState() {
    super.initState();
    final v =
        widget.espacio.verificacionComplementaria ??
        VerificacionEspacioModel.vacia;
    _bssids = List.of(v.wifiBssids);
    _bleCtrl = TextEditingController(text: v.bleUuid);
    _qrCtrl = TextEditingController(text: v.qrCodigo);
  }

  @override
  void dispose() {
    _bleCtrl.dispose();
    _qrCtrl.dispose();
    super.dispose();
  }

  VerificacionEspacioModel get _formulario => VerificacionEspacioModel(
    wifiBssids: _bssids,
    bleUuid: _bleCtrl.text.trim(),
    qrCodigo: _qrCtrl.text.trim(),
  );

  void _generarQr() {
    setState(() => _qrCtrl.text = generarCodigoQr(widget.espacio.codigo));
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<VerificacionEspacioCubit, VerificacionEspacioState>(
      listener: (context, state) {
        if (state.estado == EstadoVerificacion.guardado &&
            state.espacio != null) {
          widget.onGuardado(state.espacio!);
          Navigator.of(context).pop();
        }
      },
      builder: (context, state) {
        final cubit = context.read<VerificacionEspacioCubit>();
        final habilitado = !state.guardando;
        return AlertDialog(
          title: Text('Verificación complementaria · ${widget.espacio.codigo}'),
          content: SizedBox(
            width: 480,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Valores que el dispositivo debe observar dentro del aula '
                    'para confirmar el piso cuando el GPS no basta.',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  if (state.mensajeError != null) ...[
                    const SizedBox(height: 12),
                    _ErrorGeneral(
                      mensaje: state.mensajeError!,
                      otros: state.erroresCampo.entries
                          .where((e) => !_camposConocidos.contains(e.key))
                          .expand((e) => e.value)
                          .toList(),
                    ),
                  ],
                  const SizedBox(height: 16),
                  BssidListEditor(
                    bssids: _bssids,
                    enabled: habilitado,
                    errorText: state.errorDe('wifiBssids'),
                    onChanged: (l) => setState(() => _bssids = l),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    key: const Key('ble-uuid-input'),
                    controller: _bleCtrl,
                    enabled: habilitado,
                    decoration: InputDecoration(
                      labelText: 'UUID de baliza BLE',
                      hintText: 'f7826da6-4fa2-4e98-8024-bc5b71e0893e',
                      errorText: state.errorDe('bleUuid'),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: TextField(
                          key: const Key('qr-codigo-input'),
                          controller: _qrCtrl,
                          enabled: habilitado,
                          decoration: InputDecoration(
                            labelText: 'Código QR del aula',
                            helperText: 'Mínimo 6 caracteres',
                            errorText: state.errorDe('qrCodigo'),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: OutlinedButton.icon(
                          onPressed: habilitado ? _generarQr : null,
                          icon: const Icon(Icons.qr_code_2_rounded, size: 18),
                          label: const Text('Generar'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          actions: [
            if (widget.espacio.tieneVerificacion)
              TextButton(
                onPressed: habilitado ? cubit.quitar : null,
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.accentRose,
                ),
                child: const Text('Quitar verificación'),
              ),
            TextButton(
              onPressed: state.guardando
                  ? null
                  : () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: habilitado ? () => cubit.guardar(_formulario) : null,
              child: state.guardando
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Guardar'),
            ),
          ],
        );
      },
    );
  }
}

class _ErrorGeneral extends StatelessWidget {
  final String mensaje;
  final List<String> otros;

  const _ErrorGeneral({required this.mensaje, required this.otros});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.statusDangerBg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        [mensaje, ...otros].join('\n'),
        style: const TextStyle(fontSize: 12, color: AppColors.statusDangerText),
      ),
    );
  }
}
