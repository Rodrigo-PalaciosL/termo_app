import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:termo_app/src/data/models/termo_database.dart';
import 'package:termo_app/src/domain/engine/termo_engine.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late TermoEngine engine;

  setUp(() async {
    final satRaw = await rootBundle.loadString('assets/agua_saturacion.json');
    final overRaw = await rootBundle.loadString(
      'assets/agua_sobrecalentado.json',
    );

    final satJson = jsonDecode(satRaw) as Map<String, dynamic>;
    final overJson = jsonDecode(overRaw) as List<dynamic>;

    final db = TermoDatabase.fromRawData(
      jsonSaturacion: satJson['tabla_saturacion'] as List<dynamic>,
      jsonSobrecalentado: overJson,
    );

    engine = TermoEngine(db: db);
  });

  test('resolverEstadoPorTyV detecta líquido comprimido', () {
    final estado = engine.resolverEstadoPorTyV(100, 0.001);
    expect(estado.fase, 'Líquido Comprimido');
  });

  test('resolverEstadoPorTyV detecta mezcla húmeda', () {
    final estado = engine.resolverEstadoPorTyV(100, 0.5);
    expect(estado.fase, 'Mezcla Húmeda');
    expect(estado.x, isNotNull);
  });

  test('resolverEstadoPorPyT detecta vapor sobrecalentado', () {
    final estado = engine.resolverEstadoPorPyT(100, 120);
    expect(estado.fase, 'Vapor Sobrecalentado');
    expect(estado.p, closeTo(100, 0.001));
    expect(estado.t, closeTo(120, 0.001));
  });

  test('resolverEstadoPorPyT falla en saturación', () {
    const double pSaturada = 101.418;
    const double tSaturada = 100.0;

    expect(
      () => engine.resolverEstadoPorPyT(pSaturada, tSaturada),
      throwsA(isA<Exception>()),
    );
  });
}
