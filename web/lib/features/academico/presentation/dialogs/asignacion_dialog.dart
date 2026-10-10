import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/edicion_remote_datasource.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/advertencias_dialog.dart';
import '../../../../core/widgets/error_operacion_dialog.dart';
import '../../../usuarios/presentation/widgets/selector_usuario.dart';
import '../../data/models/academico_models.dart';
import '../../data/models/nueva_asignacion.dart';
import '../bloc/academico_bloc.dart';
import '../bloc/academico_event.dart';
import '../widgets/franja_horaria_campos.dart';
import '../widgets/modalidad_aula_campos.dart';
import '../widgets/periodo_grupo_campos.dart';

/// Nueva asignación horaria o edición de una existente (US-ACA-03, US-ACA-08).
/// Docentes y aula se eligen buscándolos por nombre o código; el backend
/// completa los datos derivados. Al editar, el periodo no cambia.
class AsignacionDialog extends StatefulWidget {
  final List<PeriodoModel> periodos;
  final List<GrupoModel> grupos;
  final List<AsignaturaModel> asignaturas;
  final AsignacionModel? inicial;

  const AsignacionDialog({
    super.key,
    required this.periodos,
    required this.grupos,
    required this.asignaturas,
    this.inicial,
  });

  @override
  State<AsignacionDialog> createState() => _AsignacionDialogState();
}

class _AsignacionDialogState extends State<AsignacionDialog> {
  final _formKey = GlobalKey<FormState>();

  String? _periodoId;
  String? _grupoId;
  String _modalidad = 'PRESENCIAL';
  String? _docenteId;
  String? _codocenteId;
  String? _espacioId;
  FranjaHoraria _franja = FranjaHoraria.porDefecto;
  bool _guardando = false;

  bool get _editando => widget.inicial != null;

  @override
  void initState() {
    super.initState();
    final a = widget.inicial;
    if (a != null) {
      _periodoId = a.periodoId;
      _grupoId = a.grupoId;
      _modalidad = a.modalidad;
      _docenteId = a.docenteIds.isEmpty ? null : a.docenteIds.first;
      _codocenteId = a.docenteIds.length > 1 ? a.docenteIds[1] : null;
      _espacioId = a.espacioId;
      _franja = FranjaHoraria.desdeTexto(a.diaSemana, a.horaInicio, a.horaFin);
      return;
    }
    // Primer periodo con grupos (si ninguno tiene, el primero).
    final conGrupos = widget.periodos.where(
      (p) => widget.grupos.any((g) => g.periodoId == p.id),
    );
    final periodo = conGrupos.isNotEmpty
        ? conGrupos.first
        : (widget.periodos.isEmpty ? null : widget.periodos.first);
    _elegirPeriodo(periodo?.id);
  }

  List<GrupoModel> get _gruposDelPeriodo =>
      widget.grupos.where((g) => g.periodoId == _periodoId).toList();

  PeriodoModel? get _periodo {
    final hallado = widget.periodos.where((p) => p.id == _periodoId);
    return hallado.isEmpty ? null : hallado.first;
  }

  void _elegirPeriodo(String? id) {
    _periodoId = id;
    final grupos = _gruposDelPeriodo;
    _grupoId = grupos.isEmpty ? null : grupos.first.id;
    _espacioId = null; // las aulas dependen de la sede del periodo
  }

  Future<void> _submit() async {
    if (_guardando || !_formKey.currentState!.validate()) return;
    final grupo = _gruposDelPeriodo.where((g) => g.id == _grupoId);
    if (_periodoId == null || grupo.isEmpty || _docenteId == null) return;

    final asignacion = NuevaAsignacion(
      periodoId: _periodoId!,
      grupo: grupo.first,
      docenteId: _docenteId!,
      codocenteId: _codocenteId,
      espacioId: _espacioId,
      modalidad: _modalidad,
      diaSemana: _franja.diaSemana,
      horaInicio: _franja.inicioTexto,
      horaFin: _franja.finTexto,
    );
    // El formulario queda abierto hasta que el servidor acepte; si rechaza
    // (p. ej. un cruce de horario) se explica en un modal y se puede corregir.
    setState(() => _guardando = true);
    try {
      final (mensaje, advertencias) = _editando
          ? await _guardarEdicion(asignacion.toJson())
          : await _guardarNueva(asignacion.toJson());
      if (!mounted) return;
      // Avisos no bloqueantes (franja corta, aula sin geometría): se leen
      // antes de cerrar el formulario (US-ACA-03 AC-04). Ya está guardada.
      setState(() => _guardando = false);
      await mostrarAdvertencias(
        context,
        titulo: 'Asignación guardada con advertencias',
        advertencias: advertencias,
      );
      if (!mounted) return;
      final avisos = ScaffoldMessenger.maybeOf(context);
      Navigator.pop(context);
      avisos?.showSnackBar(SnackBar(content: Text(mensaje)));
    } catch (e) {
      if (!mounted) return;
      setState(() => _guardando = false);
      await mostrarErrorOperacion(context, e);
    }
  }

  Future<(String, List<String>)> _guardarNueva(
    Map<String, dynamic> cuerpo,
  ) async {
    final resultado = Completer<AsignacionModel>();
    context.read<AcademicoBloc>().add(
      CreateAsignacionEvent(cuerpo, resultado: resultado),
    );
    final creada = await resultado.future;
    return ('Asignación creada.', creada.advertencias);
  }

  Future<(String, List<String>)> _guardarEdicion(
    Map<String, dynamic> cuerpo,
  ) async {
    final bloc = context.read<AcademicoBloc>();
    final res = await context.read<EdicionRemoteDataSource>().actualizar(
      '${ApiConstants.asignaciones}/${widget.inicial!.id}',
      cuerpo,
    );
    bloc.add(const LoadAcademicoDataEvent());
    final n = (res['sesionesGeneradas'] as num?)?.toInt() ?? 0;
    final mensaje = n == 0
        ? 'Asignación actualizada.'
        : 'Asignación actualizada. $n sesiones futuras siguen el nuevo horario.';
    return (mensaje, AsignacionModel.fromJson(res).advertencias);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.periodos.isEmpty || widget.grupos.isEmpty) {
      return AlertDialog(
        title: Text('Nueva Asignación', style: AppTextStyles.h3),
        content: const Text(
          'Se requiere al menos un Periodo y un Grupo registrado para crear asignaciones.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Entendido'),
          ),
        ],
      );
    }

    return AlertDialog(
      title: Row(
        children: [
          Icon(
            _editando ? Icons.edit_calendar_rounded : Icons.add_chart_rounded,
            color: AppColors.primaryAccent,
          ),
          const SizedBox(width: 8),
          Text(
            _editando
                ? 'Editar Asignación Horaria'
                : 'Nueva Asignación Horaria (US-ACA-03)',
            style: AppTextStyles.h3,
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: SizedBox(
          width: 520,
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_editando) ...[
                  Text(
                    'Los cambios aplican a las clases que aún no han ocurrido. '
                    'Las ya dictadas y la de hoy, si su ventana ya abrió, no cambian.',
                    style: AppTextStyles.bodySmall,
                  ),
                  const SizedBox(height: 12),
                ],
                PeriodoGrupoCampos(
                  periodos: widget.periodos,
                  grupos: widget.grupos,
                  asignaturas: widget.asignaturas,
                  periodoId: _periodoId,
                  grupoId: _grupoId,
                  periodoFijo: _editando,
                  onPeriodo: (v) => setState(() => _elegirPeriodo(v)),
                  onGrupo: (v) => setState(() => _grupoId = v),
                ),
                const SizedBox(height: 12),
                SelectorUsuario(
                  etiqueta: 'Docente principal *',
                  rol: 'DOCENTE',
                  idInicial: widget.inicial == null ? null : _docenteId,
                  requerido: true,
                  icono: Icons.badge_outlined,
                  onCambio: (u) => setState(() => _docenteId = u?.id),
                ),
                const SizedBox(height: 12),
                SelectorUsuario(
                  etiqueta: 'Co-docente (opcional, US-ACA-08)',
                  rol: 'DOCENTE',
                  idInicial: widget.inicial == null ? null : _codocenteId,
                  icono: Icons.group_add_outlined,
                  validador: (u) => u != null && u.id == _docenteId
                      ? 'Debe ser distinto del docente principal'
                      : null,
                  onCambio: (u) => setState(() => _codocenteId = u?.id),
                ),
                const SizedBox(height: 12),
                ModalidadAulaCampos(
                  modalidad: _modalidad,
                  periodoId: _periodoId,
                  sedeId: _periodo?.sedeId,
                  espacioInicial: widget.inicial?.espacioId,
                  onModalidad: (m) => setState(() {
                    _modalidad = m;
                    if (m == 'VIRTUAL') _espacioId = null;
                  }),
                  onEspacio: (id) => setState(() => _espacioId = id),
                ),
                const SizedBox(height: 16),
                Text(
                  'Franja Horaria Recurrente (US-ACA-02)',
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                FranjaHorariaCampos(
                  franja: _franja,
                  onCambio: (f) => setState(() => _franja = f),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton.icon(
          onPressed: _guardando ? null : _submit,
          icon: _guardando
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.save_rounded, size: 18),
          label: Text(
            _guardando
                ? 'Guardando…'
                : (_editando ? 'Guardar cambios' : 'Guardar Asignación'),
          ),
        ),
      ],
    );
  }
}
