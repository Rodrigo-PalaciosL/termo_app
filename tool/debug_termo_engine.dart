import 'dart:convert';
import 'dart:io';

import 'package:termo_app/src/data/models/termo_database.dart';
import 'package:termo_app/src/domain/engine/termo_engine.dart';

void main() {
  final satFile = File('assets/agua_saturacion.json');
  final overFile = File('assets/agua_sobrecalentado.json');
  final satJson =
      jsonDecode(satFile.readAsStringSync()) as Map<String, dynamic>;
  final overJson = jsonDecode(overFile.readAsStringSync()) as List<dynamic>;
  final db = TermoDatabase.fromRawData(
    jsonSaturacion: satJson['tabla_saturacion'] as List<dynamic>,
    jsonSobrecalentado: overJson,
  );
  final engine = TermoEngine(db: db);
  final punto = engine.db.tablaSaturacion.first;
  print('primer punto: ${punto.t}, ${punto.pSat}');
  for (final p
      in engine.db.tablaSaturacion
          .where((e) => e.pSat >= 90 && e.pSat <= 110)
          .take(10)) {
    print('pSat ${p.pSat} -> t ${p.t}');
  }
  final limites = engine.db.tablaSaturacion.first;
  print('limites first t ${limites.t}');
  try {
    final estado = engine.resolverEstadoPorPyT(100, 99.61);
    print('estado: ${estado.fase} p=${estado.p} t=${estado.t}');
  } catch (e) {
    print('exception: $e');
  }
}
