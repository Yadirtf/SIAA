import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/error_operacion_dialog.dart';
import '../../../geo/presentation/widgets/selector_espacio.dart';
import '../../../usuarios/presentation/widgets/selector_usuario.dart';
import '../../data/models/academico_models.dart';
import '../../data/models/nueva_asignacion.dart';
import '../bloc/academico_bloc.dart';
import '../bloc/academico_event.dart';
import '../widgets/franja_horaria_campos.dart';

/// Nueva asignación horaria (US-ACA-03, US-ACA-08). Docentes y aula se eligen
/// buscándolos por nombre o código; el backend completa los datos derivados.
class AsignacionDialog extends StatefulWidget {
  final List<PeriodoModel> periodos;
  final List<GrupoModel> grupos;
  final List<AsignaturaModel> asignaturas;

  const AsignacionDialog({
    super.key,
    required this.periodos,
    required this.grupos,
    required this.asignaturas,
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

  @override
  void initState() {
    super.initState();
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

  String _etiquetaGrupo(GrupoModel g) {
    final asig = widget.asignaturas.where((a) => a.id == g.asignaturaId);
    final nombre = asig.isEmpty ? 'Asignatura' : asig.first.nombre;
    return '$nombre · Grupo ${g.numero}';
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
    final resultado = Completer<void>();
    setState(() => _guardando = true);
    context.read<AcademicoBloc>().add(
      CreateAsignacionEvent(asignacion.toJson(), resultado: resultado),
    );
    try {
      await resultado.future;
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      setState(() => _guardando = false);
      await mostrarErrorOperacion(context, e);
    }
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
          const Icon(Icons.add_chart_rounded, color: AppColors.primaryAccent),
          const SizedBox(width: 8),
          Text('Nueva Asignación Horaria (US-ACA-03)', style: AppTextStyles.h3),
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
                _periodoYGrupo(),
                const SizedBox(height: 12),
                SelectorUsuario(
                  etiqueta: 'Docente principal *',
                  rol: 'DOCENTE',
                  requerido: true,
                  icono: Icons.badge_outlined,
                  onCambio: (u) => setState(() => _docenteId = u?.id),
                ),
                const SizedBox(height: 12),
                SelectorUsuario(
                  etiqueta: 'Co-docente (opcional, US-ACA-08)',
                  rol: 'DOCENTE',
                  icono: Icons.group_add_outlined,
                  validador: (u) => u != null && u.id == _docenteId
                      ? 'Debe ser distinto del docente principal'
                      : null,
                  onCambio: (u) => setState(() => _codocenteId = u?.id),
                ),
                const SizedBox(height: 12),
                _modalidadYAula(),
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
          label: Text(_guardando ? 'Guardando…' : 'Guardar Asignación'),
        ),
      ],
    );
  }

  Widget _periodoYGrupo() {
    final grupos = _gruposDelPeriodo;
    return Column(
      children: [
        DropdownButtonFormField<String>(
          value: _periodoId,
          decoration: const InputDecoration(
            labelText: 'Periodo Académico *',
            prefixIcon: Icon(Icons.calendar_month_outlined),
          ),
          items: widget.periodos
              .map(
                (p) => DropdownMenuItem(
                  value: p.id,
                  child: Text('${p.codigo} - ${p.nombre}'),
                ),
              )
              .toList(),
          onChanged: (val) => setState(() => _elegirPeriodo(val)),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          key: ValueKey('grupos-$_periodoId'),
          value: _grupoId,
          isExpanded: true,
          decoration: InputDecoration(
            labelText: 'Grupo / Curso *',
            prefixIcon: const Icon(Icons.groups_outlined),
            helperText: grupos.isEmpty ? 'Este periodo no tiene grupos' : null,
          ),
          items: grupos
              .map(
                (g) => DropdownMenuItem(
                  value: g.id,
                  child: Text(
                    _etiquetaGrupo(g),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              )
              .toList(),
          validator: (v) => v == null ? 'Requerido' : null,
          onChanged: (val) => setState(() => _grupoId = val),
        ),
      ],
    );
  }

  Widget _modalidadYAula() {
    final virtual = _modalidad == 'VIRTUAL';
    return Column(
      children: [
        DropdownButtonFormField<String>(
          value: _modalidad,
          decoration: const InputDecoration(
            labelText: 'Modalidad *',
            prefixIcon: Icon(Icons.settings_ethernet_rounded),
          ),
          items: const [
            DropdownMenuItem(value: 'PRESENCIAL', child: Text('Presencial')),
            DropdownMenuItem(value: 'VIRTUAL', child: Text('Virtual')),
            DropdownMenuItem(value: 'HIBRIDA', child: Text('Híbrida')),
          ],
          onChanged: (val) => setState(() {
            _modalidad = val ?? 'PRESENCIAL';
            if (_modalidad == 'VIRTUAL') _espacioId = null;
          }),
        ),
        if (!virtual) ...[
          const SizedBox(height: 12),
          SelectorEspacio(
            // Nueva instancia al cambiar de periodo: la sede puede cambiar.
            key: ValueKey('aula-$_periodoId'),
            etiqueta: 'Aula *',
            sedeId: _periodo?.sedeId,
            requerido: true,
            onCambio: (e) => setState(() => _espacioId = e?.id),
          ),
        ],
      ],
    );
  }
}
