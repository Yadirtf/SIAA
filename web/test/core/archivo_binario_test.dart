import 'package:flutter_test/flutter_test.dart';
import 'package:siaa_web/core/download/guardar_archivo.dart';
import 'package:siaa_web/core/models/pagina.dart';
import 'package:siaa_web/core/network/archivo_binario.dart';

void main() {
  test('nombreDesdeDisposition lee filename simple y extendido', () {
    expect(
      ArchivoBinario.nombreDesdeDisposition(
        'attachment; filename="cumplimiento_2026.xlsx"',
      ),
      'cumplimiento_2026.xlsx',
    );
    expect(
      ArchivoBinario.nombreDesdeDisposition(
        "attachment; filename*=UTF-8''bit%C3%A1cora.pdf",
      ),
      'bitácora.pdf',
    );
    expect(ArchivoBinario.nombreDesdeDisposition(null), isNull);
  });

  test('nombreExportacion arma un nombre con fecha y formato', () {
    expect(
      nombreExportacion('auditoria', 'pdf', DateTime(2026, 9, 3, 8, 5)),
      'auditoria_20260903_0805.pdf',
    );
  });

  test('Pagina calcula hayMas con y sin total', () {
    const conTotal = Pagina<int>(items: [1, 2], total: 5, pagina: 2, limite: 2);
    expect(conTotal.hayMas, isTrue);
    expect(conTotal.totalPaginas, 3);
    const sinTotal = Pagina<int>(items: [1], total: null, pagina: 1, limite: 2);
    expect(sinTotal.hayMas, isFalse);
  });
}
