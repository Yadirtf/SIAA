// marcaje_grupal_screen.dart — Control de marcaje estudiantil y lista manual (US-MAR-13, US-MAR-14)
import 'dart:async';
import 'package:flutter/material.dart';
import '../../data/repositories/marcaje_repository.dart';
import '../../domain/models/sesion_activa_model.dart';

class MarcajeGrupalScreen extends StatefulWidget {
  final MarcajeRepository? repository;

  const MarcajeGrupalScreen({super.key, this.repository});

  @override
  State<MarcajeGrupalScreen> createState() => _MarcajeGrupalScreenState();
}

class _MarcajeGrupalScreenState extends State<MarcajeGrupalScreen> {
  late final MarcajeRepository _repository;
  SesionActivaModel? _sesion;
  bool _isLoading = true;
  DateTime? _ventanaCierraEn;
  Timer? _countdownTimer;
  Duration _restante = Duration.zero;

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? MarcajeRepository();
    _cargarSesion();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  Future<void> _cargarSesion() async {
    setState(() => _isLoading = true);
    try {
      final s = await _repository.obtenerSesionActiva();
      setState(() {
        _sesion = s;
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  void _abrirVentanaEstudiantes() async {
    if (_sesion == null) return;
    try {
      final cierra = await _repository.abrirVentanaEstudiantil(_sesion!.id, duracionMinutos: 5);
      setState(() {
        _ventanaCierraEn = cierra;
      });
      _iniciarCountdown();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ventana para estudiantes abierta durante 5 minutos.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al abrir ventana: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _iniciarCountdown() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_ventanaCierraEn == null) return;
      final diff = _ventanaCierraEn!.difference(DateTime.now());
      if (diff.isNegative) {
        _countdownTimer?.cancel();
        setState(() {
          _restante = Duration.zero;
          _ventanaCierraEn = null;
        });
      } else {
        setState(() => _restante = diff);
      }
    });
  }

  void _abrirDialogoListaManual() {
    final motivoCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Pase de Lista Manual'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Registra asistencia por contingencia docente (mínimo 20 caracteres en motivo).',
              style: TextStyle(fontSize: 13, color: Colors.black87),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: motivoCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Ejemplo: Falla de red móvil general en el aula 302 durante clase.',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              if (motivoCtrl.text.trim().length < 20) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('El motivo debe tener al menos 20 caracteres.'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }
              Navigator.pop(ctx);
              await _enviarListaManual(motivoCtrl.text.trim());
            },
            child: const Text('Confirmar y Guardar'),
          ),
        ],
      ),
    );
  }

  Future<void> _enviarListaManual(String motivo) async {
    if (_sesion == null) return;
    try {
      await _repository.registrarListaManual(
        sesionId: _sesion!.id,
        motivo: motivo,
        estudiantes: [], // Lista procesada en lote
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pase de lista manual registrado exitosamente.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Marcaje Grupal y Estudiantil'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_sesion != null) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _sesion!.asignatura,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 6),
                      Text('Grupo: ${_sesion!.grupo} • Aula: ${_sesion!.espacio.codigo}'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.hourglass_top_rounded, color: Colors.blue),
                          SizedBox(width: 8),
                          Text(
                            'Ventana Estudiantil (US-MAR-13)',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _ventanaCierraEn != null
                            ? 'Ventana abierta. Cierra en: ${_restante.inMinutes}:${(_restante.inSeconds % 60).toString().padLeft(2, '0')}'
                            : 'Permite a los estudiantes marcar asistencia geolocalizada desde sus propios dispositivos.',
                        style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _ventanaCierraEn == null ? _abrirVentanaEstudiantes : null,
                        icon: const Icon(Icons.lock_open_rounded),
                        label: const Text('Abrir Ventana (5 Minutos)'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.checklist_rtl_rounded, color: Colors.teal),
                          SizedBox(width: 8),
                          Text(
                            'Pase de Lista Manual (US-MAR-14)',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'En caso de contingencia técnica o estudiantes sin dispositivo, registre la asistencia manual con auditoría obligatoria.',
                        style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                      ),
                      const SizedBox(height: 16),
                      OutlinedButton.icon(
                        onPressed: _abrirDialogoListaManual,
                        icon: const Icon(Icons.edit_note_rounded),
                        label: const Text('Iniciar Pase de Lista Manual'),
                      ),
                    ],
                  ),
                ),
              ),
            ] else ...[
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: Text(
                    'No hay una sesión activa para gestionar marcaje grupal.',
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
