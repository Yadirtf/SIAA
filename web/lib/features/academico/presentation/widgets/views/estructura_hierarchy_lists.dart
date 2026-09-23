import 'package:flutter/material.dart';
import '../../../data/academico_models.dart';

class EstructuraFacultadesList extends StatelessWidget {
  final List<FacultadModel> facultades;
  final ValueChanged<FacultadModel> onSelect;

  const EstructuraFacultadesList({
    super.key,
    required this.facultades,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    if (facultades.isEmpty) {
      return const Center(child: Text('No hay facultades registradas.'));
    }
    return ListView.separated(
      itemCount: facultades.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (ctx, i) {
        final f = facultades[i];
        return ListTile(
          leading: const CircleAvatar(
            backgroundColor: Color(0xFFEFF6FF),
            child: Icon(Icons.account_balance, color: Color(0xFF2563EB)),
          ),
          title: Text('${f.codigo} — ${f.nombre}',
              style: const TextStyle(fontWeight: FontWeight.bold)),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => onSelect(f),
        );
      },
    );
  }
}

class EstructuraProgramasList extends StatelessWidget {
  final List<ProgramaModel> programas;
  final ValueChanged<ProgramaModel> onSelect;

  const EstructuraProgramasList({
    super.key,
    required this.programas,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    if (programas.isEmpty) {
      return const Center(
        child: Text('No hay programas registrados para esta facultad.'),
      );
    }
    return ListView.separated(
      itemCount: programas.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (ctx, i) {
        final p = programas[i];
        return ListTile(
          leading: const CircleAvatar(
            backgroundColor: Color(0xFFF5F3FF),
            child: Icon(Icons.school, color: Color(0xFF7C3AED)),
          ),
          title: Text('${p.codigo} — ${p.nombre}',
              style: const TextStyle(fontWeight: FontWeight.bold)),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => onSelect(p),
        );
      },
    );
  }
}

class EstructuraAsignaturasList extends StatelessWidget {
  final List<AsignaturaModel> asignaturas;
  final ValueChanged<AsignaturaModel> onSelect;

  const EstructuraAsignaturasList({
    super.key,
    required this.asignaturas,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    if (asignaturas.isEmpty) {
      return const Center(
        child: Text('No hay asignaturas registradas para este programa.'),
      );
    }
    return ListView.separated(
      itemCount: asignaturas.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (ctx, i) {
        final a = asignaturas[i];
        return ListTile(
          leading: const CircleAvatar(
            backgroundColor: Color(0xFFECFDF5),
            child: Icon(Icons.menu_book, color: Color(0xFF059669)),
          ),
          title: Text('${a.codigo} — ${a.nombre}',
              style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text('${a.creditos} Créditos académicos'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => onSelect(a),
        );
      },
    );
  }
}

class EstructuraGruposList extends StatelessWidget {
  final List<GrupoModel> grupos;

  const EstructuraGruposList({super.key, required this.grupos});

  @override
  Widget build(BuildContext context) {
    if (grupos.isEmpty) {
      return const Center(
        child: Text('No hay grupos registrados para esta asignatura.'),
      );
    }
    return ListView.separated(
      itemCount: grupos.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (ctx, i) {
        final g = grupos[i];
        return ListTile(
          leading: const CircleAvatar(
            backgroundColor: Color(0xFFFFFBEB),
            child: Icon(Icons.groups, color: Color(0xFFD97706)),
          ),
          title: Text('Grupo ${g.numero}',
              style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text('Cupo: ${g.cupo} estudiantes'),
        );
      },
    );
  }
}
