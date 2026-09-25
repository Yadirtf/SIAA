// mi_horario_screen.dart - Pantalla principal de consulta de horario personal (US-ACA-01..09)
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../bloc/horario_bloc.dart';
import '../bloc/horario_event.dart';
import '../bloc/horario_state.dart';
import '../widgets/dias_selector.dart';
import '../widgets/horario_card.dart';

class MiHorarioScreen extends StatefulWidget {
  const MiHorarioScreen({super.key});

  @override
  State<MiHorarioScreen> createState() => _MiHorarioScreenState();
}

class _MiHorarioScreenState extends State<MiHorarioScreen> {
  late final HorarioBloc _bloc;
  DateTime _fechaActual = DateTime.now();

  @override
  void initState() {
    super.initState();
    _bloc = HorarioBloc();
    _cargarHorario();
  }

  void _cargarHorario() {
    String? usuarioId;
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      usuarioId = authState.usuarioId;
    }
    _bloc.add(CargarHorarioEvent(
      fecha: _fechaActual,
      docenteId: usuarioId,
    ));
  }

  @override
  void dispose() {
    _bloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _bloc,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Mi Horario',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              tooltip: 'Actualizar horario',
              onPressed: _cargarHorario,
            ),
          ],
        ),
        body: Column(
          children: [
            DiasSelector(
              fechaSeleccionada: _fechaActual,
              onDiaSeleccionado: (dia) {
                setState(() => _fechaActual = dia);
                _bloc.add(CambiarDiaEvent(dia));
              },
            ),
            const Divider(height: 1),
            Expanded(
              child: BlocBuilder<HorarioBloc, HorarioState>(
                builder: (context, state) {
                  if (state is HorarioLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (state is HorarioError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error_outline_rounded,
                                size: 48, color: Colors.red),
                            const SizedBox(height: 12),
                            Text(
                              state.mensaje,
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 14),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: _cargarHorario,
                              icon: const Icon(Icons.refresh_rounded),
                              label: const Text('Reintentar'),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  if (state is HorarioLoaded) {
                    if (state.esVacio) {
                      return RefreshIndicator(
                        onRefresh: () async => _cargarHorario(),
                        child: ListView(
                          children: [
                            SizedBox(
                              height: MediaQuery.of(context).size.height * 0.45,
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.event_available_outlined,
                                      size: 56,
                                      color: Colors.grey.shade400,
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      'Sin clases programadas para este día',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return RefreshIndicator(
                      onRefresh: () async => _cargarHorario(),
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: state.sesiones.length,
                        itemBuilder: (context, index) {
                          return HorarioCard(sesion: state.sesiones[index]);
                        },
                      ),
                    );
                  }

                  return const SizedBox.shrink();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
