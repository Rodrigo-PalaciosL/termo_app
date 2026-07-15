import 'saturacion_model.dart';
import 'sobrecalentado_model.dart';

class TermoDatabase {
  // Listas con tipado fuerte listas para indexar e interpolar
  final List<PuntoSaturacion> tablaSaturacion;
  final List<BloquePresionSobrecalentado> tablaSobrecalentado;

  TermoDatabase({
    required this.tablaSaturacion,
    required this.tablaSobrecalentado,
  });

  // Metodo inicializador para poblar la base desde las respuestas JSON de los archivos
  factory TermoDatabase.fromRawData({
    required List<dynamic> jsonSaturacion,
    required List<dynamic> jsonSobrecalentado,
  }) {
    final satParsed = jsonSaturacion
        .map((e) => PuntoSaturacion.fromMap(e as Map<String, dynamic>))
        .toList();

    final sobreParsed = <BloquePresionSobrecalentado>[];
    for (final item in jsonSobrecalentado) {
      if (item is! Map) continue;
      try {
        final bloque = BloquePresionSobrecalentado.fromMap(
          Map<String, dynamic>.from(item),
        );
        sobreParsed.add(bloque);
      } catch (_) {
        // Se omiten bloques incompletos del JSON.
      }
    }

    return TermoDatabase(
      tablaSaturacion: satParsed,
      tablaSobrecalentado: sobreParsed,
    );
  }
}
