import 'dart:convert';
import 'dart:io';

import 'package:termo_app/src/data/models/termo_database.dart';
import 'package:termo_app/src/domain/engine/termo_engine.dart';

void main() {
  final satFile = File('assets/amoniaco_saturacion.json');
  final overFile = File('assets/amoniaco_sobrecalentado.json');

  if (!satFile.existsSync()) {
    stderr.writeln('No se encontró ${satFile.path}');
    exit(2);
  }

  if (!overFile.existsSync()) {
    stderr.writeln('No se encontró ${overFile.path}');
    exit(2);
  }

  final satJson = jsonDecode(satFile.readAsStringSync()) as Map<String, dynamic>;
  final overJson = jsonDecode(overFile.readAsStringSync()) as List<dynamic>;

  final db = TermoDatabase.fromRawData(
    jsonSaturacion: satJson['tabla_saturacion'] as List<dynamic>,
    jsonSobrecalentado: overJson,
  );

  final engine = TermoEngine(db: db);

  void printEstado(String label, EstadoTermodinamico estado) {
    stdout.writeln('--- $label ---');
    stdout.writeln('fase: ${estado.fase}');
    stdout.writeln('p: ${estado.p} kPa');
    stdout.writeln('t: ${estado.t} °C');
    stdout.writeln('v: ${estado.v} m³/kg');
    stdout.writeln('u: ${estado.u} kJ/kg');
    stdout.writeln('h: ${estado.h} kJ/kg');
    stdout.writeln('s: ${estado.s} kJ/kg·K');
    stdout.writeln('x: ${estado.x ?? 'null'}');
    stdout.writeln('');
  }

  try {
    final estadoLiquid = engine.resolverEstadoPorTyV(100, 0.001);
    printEstado('resolverEstadoPorTyV(100, 0.001)', estadoLiquid);
    if (estadoLiquid.fase != 'Líquido Comprimido') {
      throw StateError('Se esperaba líquido comprimido');
    }
  } catch (e, stackTrace) {
    stderr.writeln('Fallo resolverEstadoPorTyV(100, 0.001): $e');
    stderr.writeln(stackTrace);
    exit(1);
  }

  try {
    final estadoMezcla = engine.resolverEstadoPorTyV(100, 0.5);
    printEstado('resolverEstadoPorTyV(100, 0.5)', estadoMezcla);
    if (estadoMezcla.fase != 'Mezcla Húmeda') {
      throw StateError('Se esperaba mezcla húmeda');
    }
  } catch (e, stackTrace) {
    stderr.writeln('Fallo resolverEstadoPorTyV(100, 0.5): $e');
    stderr.writeln(stackTrace);
    exit(1);
  }

  try {
    final estadoSobrecalentado = engine.resolverEstadoPorPyT(100, 120);
    printEstado('resolverEstadoPorPyT(100, 120)', estadoSobrecalentado);
    if (estadoSobrecalentado.fase != 'Vapor Sobrecalentado') {
      throw StateError('Se esperaba vapor sobrecalentado');
    }
  } catch (e, stackTrace) {
    stderr.writeln('Fallo resolverEstadoPorPyT(100, 120): $e');
    stderr.writeln(stackTrace);
    exit(1);
  }

  try {
    engine.resolverEstadoPorPyT(100, 99.61);
    stderr.writeln('No se lanzó excepción para estado saturado');
    exit(1);
  } catch (e) {
    stdout.writeln('resolverEstadoPorPyT(100, 99.61) lanzó excepción esperada: $e');
  }

  stdout.writeln('Pruebas del motor completadas correctamente.');
}
