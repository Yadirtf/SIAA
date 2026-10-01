import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/error_operacion_dialog.dart';
import '../../data/models/academico_models.dart';
import '../../data/models/sesion_model.dart';
import '../bloc/academico_bloc.dart';
import '../bloc/academico_state.dart';
import '../bloc/sesiones_bloc.dart';
import '../helpers/filtro_sesiones.dart';
import '../widgets/filtros_sesiones_bar.dart';
import '../widgets/rango_semana_selector.dart';
import '../widgets/tabla_sesiones.dart';

/// Sesiones de clase en una tabla: por defecto la semana actual, con filtros
/// para ubicar rápido un aula, un docente o un grupo.
class SesionesScreen extends StatefulWidget {
  const SesionesScreen({super.key});

  @override
  State<SesionesScreen> createState() => _SesionesScreenState();
}

class _SesionesScreenState extends State<SesionesScreen> {
  String? _periodoId;
  DateTimeRange _rango = semanaDe(DateTime.now());
  FiltroSesiones _filtro = const FiltroSesiones();
  ColumnaSesion _columna = ColumnaSesion.fecha;
  bool _ascendente = true;
  int _pagina = 0;
  // Cambia al limpiar filtros para que la barra se vuelva a dibujar vacía.
  int _versionFiltros = 0;
  List<PeriodoModel> _periodos = const [];

  @override
  void initState() {
    super.initState();
    final academico = context.read<AcademicoBloc>().state;
    if (academico is AcademicoLoaded) _periodos = academico.periodos;
    _cargar();
  }

  void _cargar() {
    _pagina = 0;
    context.read<SesionesBloc>().add(
      LoadSesionesEvent(
        periodoId: _periodoId,
        desde: fechaIso(_rango.start),
        hasta: fechaIso(_rango.end),
      ),
    );
  }

  void _cambiarFiltro(FiltroSesiones f) => setState(() {
    if (!f.activo && _filtro.activo) _versionFiltros++;
    _filtro = f;
    _pagina = 0;
  });

  void _avisar(BuildContext context, SesionesState state) {
    if (state is! SesionesLoaded) return;
    if (state.errorMessage != null) {
      mostrarErrorOperacion(
        context,
        ApiException(message: state.errorMessage!),
      );
    } else if (state.successMessage != null) {
      ScaffoldMessenger.maybeOf(context)
          ?.showSnackBar(SnackBar(content: Text(state.successMessage!)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<AcademicoBloc, AcademicoState>(
          listener: (_, s) {
            if (s is AcademicoLoaded) setState(() => _periodos = s.periodos);
          },
        ),
        BlocListener<SesionesBloc, SesionesState>(listener: _avisar),
      ],
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _encabezado(),
            const SizedBox(height: 16),
            Expanded(
              child: BlocBuilder<SesionesBloc, SesionesState>(
                builder: (context, state) => switch (state) {
                  SesionesLoaded(:final sesiones) => _contenido(sesiones),
                  SesionesError(:final message) => _aviso(
                    Icons.error_outline,
                    message,
                    '',
                    AppColors.accentRose,
                  ),
                  _ => const Center(child: CircularProgressIndicator()),
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _encabezado() => Wrap(
    spacing: 16,
    runSpacing: 12,
    crossAxisAlignment: WrapCrossAlignment.center,
    alignment: WrapAlignment.spaceBetween,
    children: [
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Sesiones de Clase', style: AppTextStyles.h2),
          const SizedBox(height: 4),
          Text(
            'Ubique cada clase por fecha, aula, docente o grupo '
            '(US-ACA-05, US-ACA-06, US-ACA-09)',
            style: AppTextStyles.bodyMedium,
          ),
        ],
      ),
      Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          RangoSemanaSelector(
            rango: _rango,
            onCambio: (r) {
              setState(() => _rango = r);
              _cargar();
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refrescar sesiones',
            onPressed: _cargar,
          ),
        ],
      ),
    ],
  );

  Widget _contenido(List<SesionModel> sesiones) {
    final filtradas = ordenarSesiones(
      _filtro.aplicar(sesiones),
      _columna,
      _ascendente,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FiltrosSesionesBar(
          key: ValueKey(_versionFiltros),
          periodos: _periodos,
          periodoId: _periodoId,
          onPeriodo: (p) {
            setState(() => _periodoId = p);
            _cargar();
          },
          filtro: _filtro,
          opciones: OpcionesSesiones.desde(sesiones, _filtro),
          onCambio: _cambiarFiltro,
        ),
        const SizedBox(height: 16),
        Expanded(
          child: sesiones.isEmpty
              ? _aviso(
                  Icons.event_busy_rounded,
                  'No hay sesiones en este rango de fechas',
                  'Cambie de semana, o en "Periodos" use "Generar sesiones" '
                      'para materializar el calendario.',
                  AppColors.textMuted,
                )
              : filtradas.isEmpty
              ? _aviso(
                  Icons.filter_alt_off_outlined,
                  'Ninguna sesión coincide con los filtros',
                  'Ajuste o limpie los filtros para ver más resultados.',
                  AppColors.textMuted,
                )
              : TablaSesiones(
                  sesiones: filtradas,
                  columna: _columna,
                  ascendente: _ascendente,
                  pagina: _pagina.clamp(
                    0,
                    (filtradas.length - 1) ~/ TablaSesiones.porPagina,
                  ),
                  onOrdenar: (c, asc) => setState(() {
                    _columna = c;
                    _ascendente = asc;
                    _pagina = 0;
                  }),
                  onPagina: (p) => setState(() => _pagina = p),
                ),
        ),
      ],
    );
  }

  Widget _aviso(IconData icono, String titulo, String detalle, Color color) =>
      Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icono, size: 44, color: color),
            const SizedBox(height: 12),
            Text(titulo, style: AppTextStyles.h3, textAlign: TextAlign.center),
            if (detalle.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                detalle,
                style: AppTextStyles.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      );
}
